import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Daily Entry ─────────────────────────────────────────────────────────────

class DailyEntryModel {
  final String entryId;
  final String milkmanUid;
  final String customerId;    // customer doc ID
  final String customerName;
  final String milkTypeId;
  final String milkTypeName;
  final DateTime date;
  final double quantity;
  final String status;   // delivered / skipped / vacation
  final String note;
  final bool isLocked;
  final DateTime createdAt;

  DailyEntryModel({
    required this.entryId, required this.milkmanUid,
    required this.customerId, required this.customerName,
    required this.milkTypeId, required this.milkTypeName,
    required this.date, required this.quantity,
    required this.status, required this.note,
    required this.isLocked, required this.createdAt,
  });

  factory DailyEntryModel.fromMap(Map<String, dynamic> m, String id) =>
      DailyEntryModel(
        entryId: id,
        milkmanUid: m['milkman_uid'] ?? '',
        customerId: m['customer_id'] ?? '',
        customerName: m['customer_name'] ?? '',
        milkTypeId: m['milk_type_id'] ?? '',
        milkTypeName: m['milk_type_name'] ?? '',
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'delivered',
        note: m['note'] ?? '',
        isLocked: m['is_locked'] ?? false,
        createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'milkman_uid': milkmanUid,
        'customer_id': customerId,
        'customer_name': customerName,
        'milk_type_id': milkTypeId,
        'milk_type_name': milkTypeName,
        'date': Timestamp.fromDate(date),
        'quantity': quantity,
        'status': status,
        'note': note,
        'is_locked': isLocked,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

// ─── Bill ─────────────────────────────────────────────────────────────────────

class BillModel {
  final String billId;
  final String milkmanUid;
  final String customerId;
  final String customerName;
  final String customerReadableId;
  final String billMonth;     // YYYY-MM
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double paidAmount;
  final double previousBalance;
  final double finalBalance;
  final String status;        // unpaid / partial / paid
  final DateTime generatedAt;

  BillModel({
    required this.billId, required this.milkmanUid,
    required this.customerId, required this.customerName,
    required this.customerReadableId,
    required this.billMonth, required this.startDate, required this.endDate,
    required this.totalAmount, required this.paidAmount,
    required this.previousBalance, required this.finalBalance,
    required this.status, required this.generatedAt,
  });

  double get balanceDue => (finalBalance - paidAmount).clamp(0, double.infinity);

  factory BillModel.fromMap(Map<String, dynamic> m, String id) => BillModel(
        billId: id,
        milkmanUid: m['milkman_uid'] ?? '',
        customerId: m['customer_id'] ?? '',
        customerName: m['customer_name'] ?? '',
        customerReadableId: m['customer_readable_id'] ?? '',
        billMonth: m['bill_month'] ?? '',
        startDate: (m['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (m['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
        previousBalance: (m['previous_balance'] as num?)?.toDouble() ?? 0,
        finalBalance: (m['final_balance'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'unpaid',
        generatedAt: (m['generated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'milkman_uid': milkmanUid,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_readable_id': customerReadableId,
        'bill_month': billMonth,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'previous_balance': previousBalance,
        'final_balance': finalBalance,
        'status': status,
        'generated_at': Timestamp.fromDate(generatedAt),
      };
}

// ─── Bill Item ────────────────────────────────────────────────────────────────

class BillItemModel {
  final String id;
  final String billId;
  final DateTime date;
  final String milkTypeId;
  final String milkTypeName;
  final double quantity;
  final double rate;     // frozen at generation
  final double amount;
  final String status;

  BillItemModel({
    required this.id, required this.billId, required this.date,
    required this.milkTypeId, required this.milkTypeName,
    required this.quantity, required this.rate,
    required this.amount, required this.status,
  });

  factory BillItemModel.fromMap(Map<String, dynamic> m, String id) =>
      BillItemModel(
        id: id, billId: m['bill_id'] ?? '',
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        milkTypeId: m['milk_type_id'] ?? '',
        milkTypeName: m['milk_type_name'] ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        rate: (m['rate'] as num?)?.toDouble() ?? 0,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'delivered',
      );

  Map<String, dynamic> toMap() => {
        'bill_id': billId,
        'date': Timestamp.fromDate(date),
        'milk_type_id': milkTypeId,
        'milk_type_name': milkTypeName,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
        'status': status,
      };
}

// ─── Payment ─────────────────────────────────────────────────────────────────

class PaymentModel {
  final String paymentId;
  final String billId;
  final String milkmanUid;
  final String customerId;
  final String customerName;
  final double amount;
  final String method;      // cash / upi / bank
  final String transactionId;
  final DateTime paymentDate;

  PaymentModel({
    required this.paymentId, required this.billId,
    required this.milkmanUid, required this.customerId,
    required this.customerName, required this.amount,
    required this.method, required this.transactionId,
    required this.paymentDate,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m, String id) =>
      PaymentModel(
        paymentId: id, billId: m['bill_id'] ?? '',
        milkmanUid: m['milkman_uid'] ?? '',
        customerId: m['customer_id'] ?? '',
        customerName: m['customer_name'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        method: m['method'] ?? 'cash',
        transactionId: m['transaction_id'] ?? '',
        paymentDate: (m['payment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'bill_id': billId,
        'milkman_uid': milkmanUid,
        'customer_id': customerId,
        'customer_name': customerName,
        'amount': amount,
        'method': method,
        'transaction_id': transactionId,
        'payment_date': Timestamp.fromDate(paymentDate),
      };
}
