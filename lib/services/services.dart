import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/milk_type_model.dart';
import '../utils/helpers.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AUTH SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _google = GoogleSignIn();

  static const _kRole = 'role';
  static const _kUid = 'uid';

  // ── Email/Password register (returns partial user needing Step 2) ──────────

  Future<String> registerMilkmanStep1({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  // ── Google Sign-In (returns uid + prefilled name/email, needs Step 2) ──────

  /// Returns {uid, email, displayName} — profile NOT yet saved to Firestore.
  /// Caller must check if user doc exists; if not → show Step 2.
  Future<Map<String, String>> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return {
      'uid': cred.user!.uid,
      'email': cred.user!.email ?? '',
      'displayName': cred.user!.displayName ?? '',
    };
  }

  /// Check if milkman has completed Step 2 (profile saved in Firestore).
  Future<bool> hasMilkmanProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ── Step 2: Save business details (works for both email & Google) ──────────

  Future<UserModel> saveMilkmanProfile({
    required String uid,
    required String email,
    required String ownerName,
    required String businessName,
    required String phone,
    required String address,
    required String area,
  }) async {
    final now = DateTime.now();
    final user = UserModel(
      uid: uid,
      milkmanId: AppHelpers.generateMilkmanId(uid),
      email: email,
      ownerName: ownerName,
      businessName: businessName,
      phone: phone,
      address: address,
      area: area,
      subscriptionPlan: 'free',
      subscriptionExpiry: now.add(const Duration(days: 30)),
      maxCustomers: 10,
      isActive: true,
      createdAt: now,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    await _saveSession('milkman', uid);
    return user;
  }

  // ── Email login ────────────────────────────────────────────────────────────

  Future<UserModel> loginMilkman(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists)
      throw Exception('Profile incomplete. Please complete setup.');
    await _saveSession('milkman', uid);
    return UserModel.fromMap(doc.data()!, uid);
  }

  // ── Customer login (Customer ID + password) ────────────────────────────────

  Future<Map<String, String>> loginCustomer(
    String customerId,
    String password,
  ) async {
    final snap = await _db
        .collection('customers')
        .where('customer_id', isEqualTo: customerId.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('Customer ID not found. Check with your milkman.');
    }
    final cDoc = snap.docs.first;
    final cData = cDoc.data();
    final email = '${customerId.trim().toLowerCase()}@cust.milkbiz.app';
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _saveSession('customer', cDoc.id);
    return {
      'docId': cDoc.id,
      'customerId': cData['customer_id'] ?? '',
      'milkmanUid': cData['milkman_uid'] ?? '',
      'name': cData['name'] ?? '',
    };
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRole);
    await p.remove(_kUid);
  }

  Future<Map<String, String?>> getSession() async {
    final p = await SharedPreferences.getInstance();
    return {'role': p.getString(_kRole), 'uid': p.getString(_kUid)};
  }

  Future<UserModel?> getMilkman(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateMilkman(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  Future<void> upgradePlan(String uid, String plan) async {
    final maxCust = plan == 'basic'
        ? 50
        : plan == 'standard'
        ? 100
        : -1;
    await _db.collection('users').doc(uid).update({
      'subscription_plan': plan,
      'subscription_expiry': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'max_customers': maxCust,
    });
  }

  Future<void> _saveSession(String role, String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRole, role);
    await p.setString(_kUid, uid);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Live stream — updates automatically when Firestore changes ─────────────
  Stream<List<CustomerModel>> watchCustomers(String milkmanUid) {
    if (milkmanUid.isEmpty) return const Stream.empty();

    return _db
        .collection('customers')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
              .toList();
          print('CustomerService stream: ${list.length} customers');
          return list;
        });
  }

  // ── One-time fetch ─────────────────────────────────────────────────────────
  Future<List<CustomerModel>> getCustomers(String milkmanUid) async {
    if (milkmanUid.isEmpty) {
      print('CustomerService.getCustomers() called with empty uid');
      return [];
    }

    print('CustomerService.getCustomers() fetching for uid: $milkmanUid');

    final snapshot = await _db
        .collection('customers')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .orderBy('created_at')
        .get();

    final list = snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
        .toList();

    print('CustomerService.getCustomers() found: ${list.length}');
    return list;
  }

  // ── Count customers (used to generate readable ID) ─────────────────────────
  Future<int> countCustomers(String milkmanUid) async {
    final snapshot = await _db
        .collection('customers')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .get();
    return snapshot.docs.length;
  }

  // ── Add new customer ───────────────────────────────────────────────────────
  Future<CustomerModel> addCustomer({
    required String milkmanUid,
    required String name,
    required String phone,
    required String address,
    required String preferredShift,
    required List<String> milkTypeIds,
    required String password,
  }) async {
    // Step 1: generate readable customer ID like CUST-001
    final count = await countCustomers(milkmanUid);
    final customerId = 'CUST-${(count + 1).toString().padLeft(3, '0')}';

    // Step 2: create Firebase Auth account for customer login
    final email = '${customerId.toLowerCase()}@cust.milkbiz.app';
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('CustomerService: Auth account created for $email');
    } catch (e) {
      print('CustomerService: Auth account error (may already exist): $e');
    }

    // Step 3: save customer document to Firestore
    final ref = _db.collection('customers').doc();
    final now = DateTime.now();
    final customer = CustomerModel(
      docId: ref.id,
      customerId: customerId,
      milkmanUid: milkmanUid,
      name: name,
      phone: phone,
      address: address,
      preferredShift: preferredShift,
      milkTypeIds: milkTypeIds,
      startDate: now,
      status: 'active',
      createdAt: now,
    );

    await ref.set(customer.toMap());
    print(
      'CustomerService: Customer saved with ID $customerId, docId: ${ref.id}',
    );

    return customer;
  }

  // ── Update customer fields ─────────────────────────────────────────────────
  Future<void> updateCustomer(String docId, Map<String, dynamic> data) async {
    await _db.collection('customers').doc(docId).update(data);
    print('CustomerService: Updated customer $docId');
  }

  // ── Delete customer ────────────────────────────────────────────────────────
  Future<void> deleteCustomer(String docId) async {
    await _db.collection('customers').doc(docId).delete();
    print('CustomerService: Deleted customer $docId');
  }

  // ── Get single customer by docId ───────────────────────────────────────────
  Future<CustomerModel?> getCustomer(String docId) async {
    final doc = await _db.collection('customers').doc(docId).get();
    if (!doc.exists) return null;
    return CustomerModel.fromMap(doc.data()!, doc.id);
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// MILK TYPE SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class MilkTypeService {
  final _db = FirebaseFirestore.instance;

  Stream<List<MilkTypeModel>> watchMilkTypes(String milkmanUid) => _db
      .collection('milk_types')
      .where('milkman_uid', isEqualTo: milkmanUid)
      .orderBy('created_at')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => MilkTypeModel.fromMap(d.data(), d.id)).toList(),
      );

  Future<List<MilkTypeModel>> getMilkTypes(String milkmanUid) async {
    final s = await _db
        .collection('milk_types')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .orderBy('created_at')
        .get();
    return s.docs.map((d) => MilkTypeModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> add({
    required String milkmanUid,
    required String name,
    required double price,
  }) async {
    final ref = _db.collection('milk_types').doc();
    await ref.set(
      MilkTypeModel(
        milkTypeId: ref.id,
        milkmanUid: milkmanUid,
        name: name,
        pricePerLitre: price,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = Timestamp.fromDate(DateTime.now());
    await _db.collection('milk_types').doc(id).update(data);
  }

  Future<bool> canDeactivate(String milkTypeId) async {
    final s = await _db
        .collection('customers')
        .where('milk_type_ids', arrayContains: milkTypeId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return s.docs.isEmpty;
  }

  Future<void> toggle(String id, bool active) =>
      _db.collection('milk_types').doc(id).update({
        'is_active': active,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
}

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class EntryService {
  final _db = FirebaseFirestore.instance;

  Stream<List<DailyEntryModel>> watchByDate(String milkmanUid, DateTime date) {
    final s = DateTime(date.year, date.month, date.day);
    final e = s.add(const Duration(days: 1));
    return _db
        .collection('daily_entries')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('date', isLessThan: Timestamp.fromDate(e))
        .orderBy('date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DailyEntryModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<DailyEntryModel>> getForMonth(
    String milkmanUid,
    String customerId,
    int year,
    int month,
  ) async {
    final s = DateTime(year, month, 1);
    final e = DateTime(year, month + 1, 1);
    final snap = await _db
        .collection('daily_entries')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .where('customer_id', isEqualTo: customerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('date', isLessThan: Timestamp.fromDate(e))
        .orderBy('date')
        .get();
    return snap.docs
        .map((d) => DailyEntryModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<bool> isMonthLocked(
    String milkmanUid,
    String customerId,
    int year,
    int month,
  ) async {
    final s = DateTime(year, month, 1);
    final e = DateTime(year, month + 1, 1);
    final snap = await _db
        .collection('daily_entries')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .where('customer_id', isEqualTo: customerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('date', isLessThan: Timestamp.fromDate(e))
        .where('is_locked', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> add(DailyEntryModel entry) async {
    final ref = _db.collection('daily_entries').doc();
    await ref.set(entry.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      _db.collection('daily_entries').doc(id).update(data);

  Future<void> delete(String id) =>
      _db.collection('daily_entries').doc(id).delete();
}

// ══════════════════════════════════════════════════════════════════════════════
// BILL SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class BillService {
  final _db = FirebaseFirestore.instance;

  Stream<List<BillModel>> watchBills(String milkmanUid) => _db
      .collection('bills')
      .where('milkman_uid', isEqualTo: milkmanUid)
      .orderBy('generated_at', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => BillModel.fromMap(d.data(), d.id)).toList(),
      );

  Future<List<BillModel>> getBillsForCustomer(String customerId) async {
    final s = await _db
        .collection('bills')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('generated_at', descending: true)
        .get();
    return s.docs.map((d) => BillModel.fromMap(d.data(), d.id)).toList();
  }

  Future<List<BillItemModel>> getItems(String billId) async {
    final s = await _db
        .collection('bill_items')
        .where('bill_id', isEqualTo: billId)
        .orderBy('date')
        .get();
    return s.docs.map((d) => BillItemModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addPayment({
    required String billId,
    required String milkmanUid,
    required String customerId,
    required String customerName,
    required double amount,
    required String method,
    required String txnId,
  }) async {
    final billDoc = await _db.collection('bills').doc(billId).get();
    if (!billDoc.exists) throw Exception('Bill not found');
    final bill = BillModel.fromMap(billDoc.data()!, billDoc.id);
    final newPaid = bill.paidAmount + amount;
    final status = newPaid >= bill.finalBalance
        ? 'paid'
        : newPaid > 0
        ? 'partial'
        : 'unpaid';
    final batch = _db.batch();
    final payRef = _db.collection('payments').doc();
    batch.set(payRef, {
      'bill_id': billId,
      'milkman_uid': milkmanUid,
      'customer_id': customerId,
      'customer_name': customerName,
      'amount': amount,
      'method': method,
      'transaction_id': txnId,
      'payment_date': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('bills').doc(billId), {
      'paid_amount': newPaid,
      'status': status,
    });
    await batch.commit();
  }

  Future<void> deleteBill(BillModel bill) async {
    final items = await _db
        .collection('bill_items')
        .where('bill_id', isEqualTo: bill.billId)
        .get();
    final batch = _db.batch();
    for (final d in items.docs) batch.delete(d.reference);
    batch.delete(_db.collection('bills').doc(bill.billId));
    final parts = bill.billMonth.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final entries = await _db
        .collection('daily_entries')
        .where('milkman_uid', isEqualTo: bill.milkmanUid)
        .where('customer_id', isEqualTo: bill.customerId)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(y, m, 1)),
        )
        .where('date', isLessThan: Timestamp.fromDate(DateTime(y, m + 1, 1)))
        .get();
    for (final d in entries.docs)
      batch.update(d.reference, {'is_locked': false});
    await batch.commit();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAYMENT SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class PaymentService {
  final _db = FirebaseFirestore.instance;

  Stream<List<PaymentModel>> watchByMilkman(String milkmanUid) => _db
      .collection('payments')
      .where('milkman_uid', isEqualTo: milkmanUid)
      .orderBy('payment_date', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList(),
      );

  Stream<List<PaymentModel>> watchByCustomer(String customerId) => _db
      .collection('payments')
      .where('customer_id', isEqualTo: customerId)
      .orderBy('payment_date', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList(),
      );
}
