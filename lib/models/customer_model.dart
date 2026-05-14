import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String docId; // Firestore auto-generated document ID
  final String customerId; // readable ID like CUST-001
  final String milkmanUid; // which milkman owns this customer
  final String name;
  final String phone;
  final String address;
  final String preferredShift; // morning / evening / both
  final List<String> milkTypeIds; // which milk types this customer buys
  final DateTime startDate;
  final String status; // active / inactive / paused
  final DateTime createdAt;

  CustomerModel({
    required this.docId,
    required this.customerId,
    required this.milkmanUid,
    required this.name,
    required this.phone,
    required this.address,
    required this.preferredShift,
    required this.milkTypeIds,
    required this.startDate,
    required this.status,
    required this.createdAt,
  });

  // true if customer is currently active
  bool get isActive => status == 'active';

  // first letter of name for avatar
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  // ── Convert Firestore document → Dart object ───────────────────────────────
  factory CustomerModel.fromMap(Map<String, dynamic> m, String docId) {
    return CustomerModel(
      docId: docId,
      customerId: m['customer_id'] ?? '',
      milkmanUid: m['milkman_uid'] ?? '',
      name: m['name'] ?? '',
      phone: m['phone'] ?? '',
      address: m['address'] ?? '',
      preferredShift: m['preferred_shift'] ?? 'morning',
      milkTypeIds: List<String>.from(m['milk_type_ids'] ?? []),
      startDate: (m['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: m['status'] ?? 'active',
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Convert Dart object → Firestore document ───────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'milkman_uid': milkmanUid,
      'name': name,
      'phone': phone,
      'address': address,
      'preferred_shift': preferredShift,
      'milk_type_ids': milkTypeIds,
      'start_date': Timestamp.fromDate(startDate),
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // ── Create a copy with some fields changed ─────────────────────────────────
  CustomerModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? preferredShift,
    List<String>? milkTypeIds,
    String? status,
  }) {
    return CustomerModel(
      docId: docId,
      customerId: customerId,
      milkmanUid: milkmanUid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      preferredShift: preferredShift ?? this.preferredShift,
      milkTypeIds: milkTypeIds ?? this.milkTypeIds,
      startDate: startDate,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
