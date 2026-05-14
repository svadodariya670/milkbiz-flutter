class CustomerMilkMapModel {
  final String id;
  final String customerId;
  final String milkTypeId;
  final double defaultQuantity;
  final double? customPrice;

  CustomerMilkMapModel({
    required this.id,
    required this.customerId,
    required this.milkTypeId,
    required this.defaultQuantity,
    this.customPrice,
  });

  // 🔥 Convert Firestore → Model
  factory CustomerMilkMapModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerMilkMapModel(
      id: id,
      customerId: map['customerId'],
      milkTypeId: map['milkTypeId'],
      defaultQuantity: (map['defaultQuantity'] as num).toDouble(),
      customPrice: map['customPrice'] != null
          ? (map['customPrice'] as num).toDouble()
          : null,
    );
  }

  // 🔥 Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'milkTypeId': milkTypeId,
      'defaultQuantity': defaultQuantity,
      'customPrice': customPrice,
    };
  }
}
