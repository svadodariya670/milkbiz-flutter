import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String milkmanId;
  final String email;
  final String ownerName;
  final String businessName;
  final String phone;
  final String address;
  final String area;
  final String subscriptionPlan;
  final DateTime subscriptionExpiry;
  final int maxCustomers;
  final bool isActive;
  final bool profileComplete;   // false until Step 2 is filled
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.milkmanId,
    required this.email,
    required this.ownerName,
    required this.businessName,
    required this.phone,
    required this.address,
    required this.area,
    required this.subscriptionPlan,
    required this.subscriptionExpiry,
    required this.maxCustomers,
    required this.isActive,
    this.profileComplete = false,
    required this.createdAt,
  });

  bool get isSubscriptionActive => subscriptionExpiry.isAfter(DateTime.now());

  factory UserModel.fromMap(Map<String, dynamic> m, String uid) => UserModel(
        uid: uid,
        milkmanId:        m['milkman_id']        ?? '',
        email:            m['email']              ?? '',
        ownerName:        m['owner_name']         ?? '',
        businessName:     m['business_name']      ?? '',
        phone:            m['phone']              ?? '',
        address:          m['address']            ?? '',
        area:             m['area']               ?? '',
        subscriptionPlan: m['subscription_plan']  ?? 'free',
        subscriptionExpiry: (m['subscription_expiry'] as Timestamp?)?.toDate()
            ?? DateTime.now().add(const Duration(days: 30)),
        maxCustomers:    m['max_customers']    ?? 10,
        isActive:        m['is_active']        ?? true,
        profileComplete: m['profile_complete'] ?? false,
        createdAt:       (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'milkman_id':        milkmanId,
        'email':             email,
        'owner_name':        ownerName,
        'business_name':     businessName,
        'phone':             phone,
        'address':           address,
        'area':              area,
        'subscription_plan': subscriptionPlan,
        'subscription_expiry': Timestamp.fromDate(subscriptionExpiry),
        'max_customers':     maxCustomers,
        'is_active':         isActive,
        'profile_complete':  profileComplete,
        'created_at':        Timestamp.fromDate(createdAt),
      };
}
