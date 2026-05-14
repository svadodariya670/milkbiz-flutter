import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/milk_type_model.dart';
import '../services/services.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AUTH CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

class AuthController extends ChangeNotifier {
  final _svc = AuthService();

  UserModel? _user;
  String?    _role;
  String?    _sessionUid;
  bool       _loading = false;
  String?    _error;

  // Pending Google data waiting for Step 2
  String? _pendingUid;
  String? _pendingEmail;
  String? _pendingDisplayName;

  UserModel? get user           => _user;
  String?    get role           => _role;
  String?    get sessionUid     => _sessionUid;
  bool       get isLoading      => _loading;
  String?    get error          => _error;
  bool       get isMilkman      => _role == 'milkman';
  String?    get pendingUid     => _pendingUid;
  String?    get pendingEmail   => _pendingEmail;
  String?    get pendingName    => _pendingDisplayName;

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> checkSession() async {
    final s = await _svc.getSession();
    _role       = s['role'];
    _sessionUid = s['uid'];
    if (_role == 'milkman' && _sessionUid != null) {
      _user = await _svc.getMilkman(_sessionUid!);
    }
    notifyListeners();
  }

  // ── Email registration — Step 1 ───────────────────────────────────────────

  /// Returns true if Firebase account created. Caller should navigate to Step 2.
  Future<bool> startEmailRegister(String email, String password) async {
    _begin();
    try {
      final uid = await _svc.registerMilkmanStep1(email: email, password: password);
      _pendingUid   = uid;
      _pendingEmail = email;
      _pendingDisplayName = null;
      _end(); return true;
    } catch (e) { return _fail(e); }
  }

  // ── Google Sign-In — fetches account, then always shows Step 2 ────────────

  /// Always returns 'needs_step2' with pre-filled data; never skips Step 2.
  Future<bool> startGoogleSignIn() async {
    _begin();
    try {
      final info = await _svc.signInWithGoogle();
      _pendingUid          = info['uid'];
      _pendingEmail        = info['email'];
      _pendingDisplayName  = info['displayName'];

      // Even if they already have a profile, we always enforce Step 2.
      // But: if they DO have a profile, load it and skip Step 2.
      final hasProfile = await _svc.hasMilkmanProfile(_pendingUid!);
      if (hasProfile) {
        _user       = await _svc.getMilkman(_pendingUid!);
        _role       = 'milkman';
        _sessionUid = _pendingUid;
        _pendingUid = _pendingEmail = _pendingDisplayName = null;
        _end(); return true; // → navigate to dashboard
      }
      _end(); return false; // → navigate to Step 2
    } catch (e) { return _fail(e); }
  }

  // ── Step 2: Save business profile (shared by email & Google) ─────────────

  Future<bool> completeBusinessProfile({
    required String ownerName,
    required String businessName,
    required String phone,
    required String address,
    required String area,
  }) async {
    if (_pendingUid == null || _pendingEmail == null) {
      _error = 'Session expired. Please try again.';
      notifyListeners(); return false;
    }
    _begin();
    try {
      _user = await _svc.saveMilkmanProfile(
        uid: _pendingUid!,
        email: _pendingEmail!,
        ownerName: ownerName,
        businessName: businessName,
        phone: phone,
        address: address,
        area: area,
      );
      _role       = 'milkman';
      _sessionUid = _pendingUid;
      _pendingUid = _pendingEmail = _pendingDisplayName = null;
      _end(); return true;
    } catch (e) { return _fail(e); }
  }

  // ── Email login ────────────────────────────────────────────────────────────

  Future<bool> loginMilkman(String email, String password) async {
    _begin();
    try {
      _user       = await _svc.loginMilkman(email, password);
      _role       = 'milkman';
      _sessionUid = _user!.uid;
      _end(); return true;
    } catch (e) { return _fail(e); }
  }

  // ── Customer login ─────────────────────────────────────────────────────────

  Future<Map<String, String>?> loginCustomer(
      String customerId, String password) async {
    _begin();
    try {
      final result    = await _svc.loginCustomer(customerId, password);
      _role           = 'customer';
      _sessionUid     = result['docId'];
      _end(); return result;
    } catch (e) { _fail(e); return null; }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _svc.logout();
    _user = _role = _sessionUid = _error = null;
    _pendingUid = _pendingEmail = _pendingDisplayName = null;
    notifyListeners();
  }

  // ── Refresh & update ───────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (_sessionUid != null && _role == 'milkman') {
      _user = await _svc.getMilkman(_sessionUid!);
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    _begin();
    try {
      await _svc.updateMilkman(_user!.uid, data);
      await refreshUser();
      _end(); return true;
    } catch (e) { return _fail(e); }
  }

  Future<bool> upgradePlan(String plan) async {
    if (_user == null) return false;
    _begin();
    try {
      await _svc.upgradePlan(_user!.uid, plan);
      await refreshUser();
      _end(); return true;
    } catch (e) { return _fail(e); }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _begin() { _loading = true; _error = null; notifyListeners(); }
  void _end()   { _loading = false; notifyListeners(); }
  bool _fail(dynamic e) {
    _error   = _friendly(e);
    _loading = false;
    notifyListeners();
    return false;
  }

  String _friendly(dynamic e) {
    final s = e.toString();
    if (s.contains('user-not-found') || s.contains('wrong-password') ||
        s.contains('invalid-credential')) return 'Invalid email or password';
    if (s.contains('email-already-in-use')) return 'Email already registered';
    if (s.contains('weak-password')) return 'Password too weak (min 6 chars)';
    if (s.contains('network-request-failed')) return 'No internet connection';
    if (s.contains('Exception:')) return s.replaceAll('Exception: ', '');
    return 'Something went wrong. Please try again.';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

class CustomerController extends ChangeNotifier {
  final _svc = CustomerService();

  List<CustomerModel> _customers = [];
  bool    _loading = false;
  String? _error;

  List<CustomerModel> get customers       => _customers;
  List<CustomerModel> get activeCustomers =>
      _customers.where((c) => c.isActive).toList();
  bool    get isLoading => _loading;
  String? get error     => _error;
  int     get total     => _customers.length;
  int     get active    => activeCustomers.length;

  Stream<List<CustomerModel>> watch(String uid) => _svc.watchCustomers(uid);

  Future<void> load(String uid) async {
    _loading = true; notifyListeners();
    try { _customers = await _svc.getCustomers(uid); _error = null; }
    catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<bool> add({
    required UserModel milkman, required String name, required String phone,
    required String address, required String shift,
    required List<String> milkTypeIds, required String password,
  }) async {
    final limit = milkman.maxCustomers;
    if (limit != -1 && _customers.length >= limit) {
      _error = 'Customer limit reached (${limit}). Upgrade your plan.';
      notifyListeners(); return false;
    }
    _loading = true; notifyListeners();
    try {
      final c = await _svc.addCustomer(
        milkmanUid: milkman.uid, name: name, phone: phone,
        address: address, preferredShift: shift,
        milkTypeIds: milkTypeIds, password: password,
      );
      _customers.add(c); _error = null;
      _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> update(String docId, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      await _svc.updateCustomer(docId, data);
      final idx = _customers.indexWhere((c) => c.docId == docId);
      if (idx != -1) {
        final c = _customers[idx];
        _customers[idx] = c.copyWith(
          name: data['name'], phone: data['phone'], address: data['address'],
          preferredShift: data['preferred_shift'],
          milkTypeIds: data['milk_type_ids'] != null
              ? List<String>.from(data['milk_type_ids']) : null,
          status: data['status'],
        );
      }
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> delete(String docId) async {
    _loading = true; notifyListeners();
    try {
      await _svc.deleteCustomer(docId);
      _customers.removeWhere((c) => c.docId == docId);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  CustomerModel? getById(String docId) {
    try { return _customers.firstWhere((c) => c.docId == docId); }
    catch (_) { return null; }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ══════════════════════════════════════════════════════════════════════════════
// MILK TYPE CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

class MilkTypeController extends ChangeNotifier {
  final _svc = MilkTypeService();

  List<MilkTypeModel> _types = [];
  bool    _loading = false;
  String? _error;

  List<MilkTypeModel> get types       => _types;
  List<MilkTypeModel> get activeTypes =>
      _types.where((t) => t.isActive).toList();
  bool    get isLoading => _loading;
  String? get error     => _error;

  Stream<List<MilkTypeModel>> watch(String uid) => _svc.watchMilkTypes(uid);

  Future<void> load(String uid) async {
    _loading = true; notifyListeners();
    try { _types = await _svc.getMilkTypes(uid); _error = null; }
    catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<bool> add(String uid, String name, double price) async {
    _loading = true; notifyListeners();
    try {
      await _svc.add(milkmanUid: uid, name: name, price: price);
      await load(uid); _error = null;
      _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> update(String id, String uid, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      await _svc.update(id, data); await load(uid);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> toggle(String id, bool current, String uid) async {
    if (current) {
      final ok = await _svc.canDeactivate(id);
      if (!ok) {
        _error = 'Cannot deactivate: active customers use this type.';
        notifyListeners(); return false;
      }
    }
    _loading = true; notifyListeners();
    try {
      await _svc.toggle(id, !current); await load(uid);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  MilkTypeModel? getById(String id) {
    try { return _types.firstWhere((t) => t.milkTypeId == id); }
    catch (_) { return null; }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

class EntryController extends ChangeNotifier {
  final _svc = EntryService();
  bool    _loading = false;
  String? _error;
  bool    get isLoading => _loading;
  String? get error     => _error;

  Stream<List<DailyEntryModel>> watch(String uid, DateTime date) =>
      _svc.watchByDate(uid, date);

  Future<bool> add({
    required String milkmanUid, required String customerId,
    required String customerName, required String milkTypeId,
    required String milkTypeName, required DateTime date,
    required double quantity, required String status, String note = '',
  }) async {
    _loading = true; notifyListeners();
    try {
      final locked =
          await _svc.isMonthLocked(milkmanUid, customerId, date.year, date.month);
      if (locked) {
        _error = 'Entries locked – bill already generated for this month.';
        _loading = false; notifyListeners(); return false;
      }
      await _svc.add(DailyEntryModel(
        entryId: '', milkmanUid: milkmanUid,
        customerId: customerId, customerName: customerName,
        milkTypeId: milkTypeId, milkTypeName: milkTypeName,
        date: date, quantity: quantity, status: status, note: note,
        isLocked: false, createdAt: DateTime.now(),
      ));
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      await _svc.update(id, data);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> delete(String id) async {
    _loading = true; notifyListeners();
    try {
      await _svc.delete(id);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ══════════════════════════════════════════════════════════════════════════════
// BILL CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

class BillController extends ChangeNotifier {
  final _billSvc = BillService();

  List<BillItemModel> _items   = [];
  bool    _loading = false;
  String? _error;

  List<BillItemModel> get items     => _items;
  bool    get isLoading => _loading;
  String? get error     => _error;

  Stream<List<BillModel>> watchBills(String uid) => _billSvc.watchBills(uid);

  Future<List<BillModel>> getBillsForCustomer(String cid) =>
      _billSvc.getBillsForCustomer(cid);

  Future<void> loadItems(String billId) async {
    _loading = true; notifyListeners();
    try { _items = await _billSvc.getItems(billId); _error = null; }
    catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<bool> addPayment({
    required String billId, required String milkmanUid,
    required String customerId, required String customerName,
    required double amount, required String method, String txnId = '',
  }) async {
    _loading = true; notifyListeners();
    try {
      await _billSvc.addPayment(
        billId: billId, milkmanUid: milkmanUid,
        customerId: customerId, customerName: customerName,
        amount: amount, method: method, txnId: txnId,
      );
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  Future<bool> deleteBill(BillModel bill) async {
    if (bill.paidAmount > 0) {
      _error = 'Cannot delete a bill that has payments recorded.';
      notifyListeners(); return false;
    }
    _loading = true; notifyListeners();
    try {
      await _billSvc.deleteBill(bill);
      _error = null; _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); _loading = false; notifyListeners(); return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}
