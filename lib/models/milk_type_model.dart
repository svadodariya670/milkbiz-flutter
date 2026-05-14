import 'package:cloud_firestore/cloud_firestore.dart';

class MilkTypeModel {
  final String milkTypeId;
  final String milkmanUid;
  final String name;
  final double pricePerLitre;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MilkTypeModel({
    required this.milkTypeId,
    required this.milkmanUid,
    required this.name,
    required this.pricePerLitre,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔥 FIXED FROM MAP
  factory MilkTypeModel.fromMap(Map<String, dynamic> map, String docId) {
    return MilkTypeModel(
      milkTypeId: docId,

      milkmanUid: map['milkman_uid'] ?? '',

      name: map['name'] ?? '',

      pricePerLitre: (map['price_per_litre'] as num?)?.toDouble() ?? 0.0,

      isActive: map['is_active'] ?? true,

      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Convert Dart object → Firestore document ───────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'milkman_uid': milkmanUid,
      'name': name,
      'price_per_litre': pricePerLitre,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // ── Copy with update ───────────────────────────────────────────────────────
  MilkTypeModel copyWith({
    String? name,
    double? pricePerLitre,
    bool? isActive,
  }) {
    return MilkTypeModel(
      milkTypeId: milkTypeId,
      milkmanUid: milkmanUid,
      name: name ?? this.name,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
