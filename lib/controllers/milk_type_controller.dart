import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/milk_type_model.dart';

class MilkTypeController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<MilkTypeModel> _types = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────
  List<MilkTypeModel> get types => _types;
  List<MilkTypeModel> get activeTypes =>
      _types.where((t) => t.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load ───────────────────────────────────────────────
  Future<void> load(String milkmanUid) async {
    print("🔥 LOAD CALLED with UID = $milkmanUid");

    if (milkmanUid.isEmpty) {
      print("❌ UID EMPTY");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print("⏳ Fetching from Firestore...");

      final snapshot = await _db
          .collection('milk_types')
          .where('milkman_uid', isEqualTo: milkmanUid)
          .get();

      print("📦 DOC COUNT = ${snapshot.docs.length}");

      _types = snapshot.docs
          .map((doc) => MilkTypeModel.fromMap(doc.data(), doc.id))
          .toList();

      print("📊 TYPES LENGTH = ${_types.length}");
    } catch (e) {
      print("❌ ERROR = $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Add ────────────────────────────────────────────────
  Future<bool> add({
    required String milkmanUid,
    required String name,
    required double price,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ref = _db.collection('milk_types').doc();
      final now = DateTime.now();

      final newType = MilkTypeModel(
        milkTypeId: ref.id,
        milkmanUid: milkmanUid,
        name: name,
        pricePerLitre: price,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await ref.set(newType.toMap());
      _types.add(newType);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update (FIXED HERE) ────────────────────────────────
  Future<bool> update({
    required String milkTypeId,
    required String milkmanUid,
    String? newName,
    double? newPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };

      if (newName != null) data['name'] = newName;

      // ✅ FIX: use SAME field as Firestore + model
      if (newPrice != null) data['price_per_litre'] = newPrice;

      await _db.collection('milk_types').doc(milkTypeId).update(data);

      // ✅ FIX: safe update (avoid null overwrite)
      final index = _types.indexWhere((t) => t.milkTypeId == milkTypeId);
      if (index != -1) {
        _types[index] = _types[index].copyWith(
          name: newName ?? _types[index].name,
          pricePerLitre: newPrice ?? _types[index].pricePerLitre,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Toggle Active ──────────────────────────────────────
  Future<bool> toggleActive({
    required String milkTypeId,
    required String milkmanUid,
  }) async {
    final index = _types.indexWhere((t) => t.milkTypeId == milkTypeId);
    if (index == -1) return false;

    final currentlyActive = _types[index].isActive;

    if (currentlyActive) {
      final inUse = await _isUsedByActiveCustomer(milkTypeId);
      if (inUse) {
        _error =
            'Cannot deactivate: active customers are using this milk type.';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newValue = !currentlyActive;

      await _db.collection('milk_types').doc(milkTypeId).update({
        'is_active': newValue,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _types[index] = _types[index].copyWith(isActive: newValue);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Check usage ────────────────────────────────────────
  Future<bool> _isUsedByActiveCustomer(String milkTypeId) async {
    try {
      final snap = await _db
          .collection('customers')
          .where('milk_type_ids', arrayContains: milkTypeId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Get by ID ──────────────────────────────────────────
  MilkTypeModel? getById(String milkTypeId) {
    try {
      return _types.firstWhere((t) => t.milkTypeId == milkTypeId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Stream ─────────────────────────────────────────────
  Stream<List<MilkTypeModel>> streamMilkTypes(String milkmanUid) {
    return _db
        .collection('milk_types')
        .where('milkman_uid', isEqualTo: milkmanUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MilkTypeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
