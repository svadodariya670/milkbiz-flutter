import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milkbiz/models/customer_model.dart';
import 'package:milkbiz/models/milk_type_model.dart';
import 'package:milkbiz/models/user_model.dart';
import '../models/models.dart';
//import '../models/user_model.dart';
//import '../models/customer_model.dart';
//import '../models/milk_type_model.dart';

/// BillScheduler
/// Runs a timer that fires once per minute and checks whether it is
/// 23:59 on the last day of the month. When it is, it auto-generates
/// bills for every active customer of every milkman whose subscription
/// is still active.
///
/// Usage: call BillScheduler.start() from main() after Firebase.initializeApp().
/// It is intentionally kept in its own file so it can be unit-tested independently.
class BillScheduler {
  static Timer? _timer;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Start the scheduler. Safe to call multiple times – only one timer runs.
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
    // Also fire immediately so an app restart mid-month still works
    _check();
  }

  static void stop() => _timer?.cancel();

  // ─── Core check ──────────────────────────────────────────────────────────

  static Future<void> _check() async {
    final now = DateTime.now();
    if (!_isLastMomentOfMonth(now)) return;

    // Find all active milkmen with valid subscription
    final milkmenSnap = await _db
        .collection('users')
        .where('is_active', isEqualTo: true)
        .get();

    for (final milkmanDoc in milkmenSnap.docs) {
      final milkman = UserModel.fromMap(milkmanDoc.data(), milkmanDoc.id);
      if (!milkman.isSubscriptionActive) continue;

      await _generateBillsForMilkman(milkman, now);
    }
  }

  /// Returns true only at 23:59 on the last day of the current month.
  static bool _isLastMomentOfMonth(DateTime now) {
    // Last day of month: day == days-in-month
    final lastDay = _daysInMonth(now.year, now.month);
    return now.day == lastDay && now.hour == 23 && now.minute == 59;
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ─── Bill generation for one milkman ─────────────────────────────────────

  static Future<void> _generateBillsForMilkman(
    UserModel milkman,
    DateTime now,
  ) async {
    final year = now.year;
    final month = now.month;
    final billMonth = '$year-${month.toString().padLeft(2, '0')}';

    // Fetch all active customers
    final custSnap = await _db
        .collection('customers')
        .where('milkman_uid', isEqualTo: milkman.uid)
        .where('status', isEqualTo: 'active')
        .get();

    // Fetch all milk types (for price map)
    final mtSnap = await _db
        .collection('milk_types')
        .where('milkman_uid', isEqualTo: milkman.uid)
        .get();
    final priceMap = <String, double>{};
    final nameMap = <String, String>{};
    for (final d in mtSnap.docs) {
      final m = MilkTypeModel.fromMap(d.data(), d.id);
      priceMap[m.milkTypeId] = m.pricePerLitre;
      nameMap[m.milkTypeId] = m.name;
    }

    for (final custDoc in custSnap.docs) {
      final customer = CustomerModel.fromMap(custDoc.data(), custDoc.id);
      await _generateBillForCustomer(
        milkman: milkman,
        customer: customer,
        year: year,
        month: month,
        billMonth: billMonth,
        priceMap: priceMap,
        nameMap: nameMap,
      );
    }
  }

  static Future<void> _generateBillForCustomer({
    required UserModel milkman,
    required CustomerModel customer,
    required int year,
    required int month,
    required String billMonth,
    required Map<String, double> priceMap,
    required Map<String, String> nameMap,
  }) async {
    // Skip if bill already exists for this month
    final existingSnap = await _db
        .collection('bills')
        .where('milkman_uid', isEqualTo: milkman.uid)
        .where('customer_id', isEqualTo: customer.docId)
        .where('bill_month', isEqualTo: billMonth)
        .limit(1)
        .get();
    if (existingSnap.docs.isNotEmpty) return;

    // Fetch all daily entries for this customer this month
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final entriesSnap = await _db
        .collection('daily_entries')
        .where('milkman_uid', isEqualTo: milkman.uid)
        .where('customer_id', isEqualTo: customer.docId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final entries = entriesSnap.docs
        .map((d) => DailyEntryModel.fromMap(d.data(), d.id))
        .toList();

    // Get previous balance
    final prevSnap = await _db
        .collection('bills')
        .where('customer_id', isEqualTo: customer.docId)
        .orderBy('generated_at', descending: true)
        .limit(1)
        .get();
    double prevBalance = 0;
    if (prevSnap.docs.isNotEmpty) {
      final prev = BillModel.fromMap(
        prevSnap.docs.first.data(),
        prevSnap.docs.first.id,
      );
      prevBalance = prev.balanceDue;
    }

    // Calculate bill items
    double total = 0;
    final batch = _db.batch();
    final billRef = _db.collection('bills').doc();

    for (final entry in entries) {
      if (entry.status != 'delivered') continue;
      final rate = priceMap[entry.milkTypeId] ?? 0;
      final amount = entry.quantity * rate;
      total += amount;

      final itemRef = _db.collection('bill_items').doc();
      batch.set(itemRef, {
        'bill_id': billRef.id,
        'date': Timestamp.fromDate(entry.date),
        'milk_type_id': entry.milkTypeId,
        'milk_type_name': nameMap[entry.milkTypeId] ?? entry.milkTypeName,
        'quantity': entry.quantity,
        'rate': rate,
        'amount': amount,
        'status': entry.status,
      });
    }

    final finalBalance = total + prevBalance;
    // If total is 0 → auto mark as paid (free month / no deliveries)
    final status = total == 0 ? 'paid' : 'unpaid';

    final bill = BillModel(
      billId: billRef.id,
      milkmanUid: milkman.uid,
      customerId: customer.docId,
      customerName: customer.name,
      customerReadableId: customer.customerId,
      billMonth: billMonth,
      startDate: start,
      endDate: DateTime(year, month + 1, 0),
      totalAmount: total,
      paidAmount: 0,
      previousBalance: prevBalance,
      finalBalance: finalBalance,
      status: status,
      generatedAt: DateTime.now(),
    );
    batch.set(billRef, bill.toMap());

    // Lock all entries
    for (final d in entriesSnap.docs) {
      batch.update(d.reference, {'is_locked': true});
    }

    await batch.commit();
  }
}
