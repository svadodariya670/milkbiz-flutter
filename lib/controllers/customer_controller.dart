import 'package:milkbiz/models/customer_model.dart';
import 'package:milkbiz/models/user_model.dart';
import 'package:milkbiz/services/services.dart';

import 'package:milkbiz/models/customer_milk_map_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// class CustomerController {
//   Stream<List<CustomerMilkMapModel>> streamCustomerMilkMap(String customerId) =>
//       const Stream.empty();
//   Future<void> addCustomerMilkMap(CustomerMilkMapModel map) async {}
//   Future<void> deleteCustomerMilkMap(String id) async {}
// }

class CustomerController extends ChangeNotifier {
  final CustomerService _service = CustomerService();

  // ── Private state ──────────────────────────────────────────────────────────
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get activeCustomers =>
      _customers.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _customers.length; // ALL customers count
  int get active => activeCustomers.length; // only active count

  // ── Load customers from Firestore (called on shell init) ──────────────────
  Future<void> load(String milkmanUid) async {
    if (milkmanUid.isEmpty) {
      print('CustomerController.load() called with empty uid — skipping');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _service.getCustomers(milkmanUid);
      print(
        'CustomerController loaded: ${_customers.length} total, ${active} active',
      );
    } catch (e) {
      _error = e.toString();
      print('CustomerController.load() ERROR: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Live stream (use this in UI for always-updated list) ──────────────────
  Stream<List<CustomerModel>> watch(String milkmanUid) {
    return _service.watchCustomers(milkmanUid);
  }

  // ── Add new customer ───────────────────────────────────────────────────────
  Future<bool> add({
    required UserModel milkman,
    required String name,
    required String phone,
    required String address,
    required String shift,
    required List<String> milkTypeIds,
    required String password,
  }) async {
    // Check subscription limit
    final limit = milkman.maxCustomers;
    if (limit != -1 && _customers.length >= limit) {
      _error = 'Customer limit reached ($limit). Please upgrade your plan.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCustomer = await _service.addCustomer(
        milkmanUid: milkman.uid,
        name: name,
        phone: phone,
        address: address,
        preferredShift: shift,
        milkTypeIds: milkTypeIds,
        password: password,
      );

      // Add to local list immediately — no need to re-fetch from Firestore
      _customers.add(newCustomer);

      print(
        'CustomerController.add() success. Total now: ${_customers.length}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('CustomerController.add() ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update customer ────────────────────────────────────────────────────────
  Future<bool> update(String docId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateCustomer(docId, data);

      // Update local list without re-fetching everything from Firestore
      final index = _customers.indexWhere((c) => c.docId == docId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(
          name: data['name'],
          phone: data['phone'],
          address: data['address'],
          preferredShift: data['preferred_shift'],
          milkTypeIds: data['milk_type_ids'] != null
              ? List<String>.from(data['milk_type_ids'])
              : null,
          status: data['status'],
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('CustomerController.update() ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete customer ────────────────────────────────────────────────────────
  Future<bool> delete(String docId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteCustomer(docId);

      // Remove from local list immediately
      _customers.removeWhere((c) => c.docId == docId);

      print(
        'CustomerController.delete() success. Total now: ${_customers.length}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('CustomerController.delete() ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Get single customer from local list ───────────────────────────────────
  CustomerModel? getById(String docId) {
    try {
      return _customers.firstWhere((c) => c.docId == docId);
    } catch (_) {
      return null;
    }
  }

  // ── Clear error ────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Customer Milk Map Methods ─────────────────────────────

  // Stream milk preferences
  Stream<List<CustomerMilkMapModel>> streamCustomerMilkMap(String customerId) {
    return FirebaseFirestore.instance
        .collection('customer_milk_map')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CustomerMilkMapModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Add milk preference
  Future<void> addCustomerMilkMap(CustomerMilkMapModel map) async {
    await FirebaseFirestore.instance
        .collection('customer_milk_map')
        .add(map.toMap());
  }

  // Delete milk preference
  Future<void> deleteCustomerMilkMap(String id) async {
    await FirebaseFirestore.instance
        .collection('customer_milk_map')
        .doc(id)
        .delete();
  }
}
