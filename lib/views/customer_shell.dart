import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/controllers.dart';
import '../models/models.dart';
import '../models/customer_model.dart';
import '../models/milk_type_model.dart';
//import '../services/services.dart';
import '../utils/app_theme.dart';
import '../utils/app_routes.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER SHELL — Bottom Nav
// ══════════════════════════════════════════════════════════════════════════════

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tab = 0;
  String? _docId;
  String? _milkmanUid;
  CustomerModel? _customer;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _docId =
        args?['docId'] as String? ?? context.read<AuthController>().sessionUid;
    _milkmanUid = args?['milkmanUid'] as String?;
    if (_docId != null) await _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _loadingProfile = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(_docId)
          .get();
      if (doc.exists && mounted) {
        _customer = CustomerModel.fromMap(doc.data()!, doc.id);
        _milkmanUid = _customer!.milkmanUid;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final tabs = [
      _CustomerHomeTab(customer: _customer, milkmanUid: _milkmanUid ?? ''),
      _CustomerBillsTab(docId: _docId ?? ''),
      _CustomerPaymentsTab(docId: _docId ?? ''),
      _CustomerProfileTab(customer: _customer, milkmanUid: _milkmanUid ?? ''),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — HOME
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerHomeTab extends StatefulWidget {
  final CustomerModel? customer;
  final String milkmanUid;
  const _CustomerHomeTab({required this.customer, required this.milkmanUid});
  @override
  State<_CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<_CustomerHomeTab> {
  List<BillModel> _bills = [];
  List<MilkTypeModel> _mtypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cid = widget.customer?.docId;
    if (cid != null) {
      try {
        final bSnap = await FirebaseFirestore.instance
            .collection('bills')
            .where('customer_id', isEqualTo: cid)
            .orderBy('generated_at', descending: true)
            .limit(3)
            .get();
        _bills = bSnap.docs
            .map((d) => BillModel.fromMap(d.data(), d.id))
            .toList();
        if (widget.milkmanUid.isNotEmpty) {
          final mtSnap = await FirebaseFirestore.instance
              .collection('milk_types')
              .where('milkman_uid', isEqualTo: widget.milkmanUid)
              .where('is_active', isEqualTo: true)
              .get();
          _mtypes = mtSnap.docs
              .map((d) => MilkTypeModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final totalDue = _bills.fold<double>(0, (s, b) => s + b.balanceDue);
    final latestBill = _bills.isNotEmpty ? _bills.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Hero header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppHelpers.greeting(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.78),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c?.name ?? 'Customer',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (c != null)
                                    Text(
                                      'ID: ${c.customerId}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Logout
                            IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white70,
                              ),
                              onPressed: () async {
                                await context.read<AuthController>().logout();
                                if (context.mounted)
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.roleSelection,
                                  );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Bills',
                          value: '${_bills.length}',
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Balance Due',
                          value: AppHelpers.formatCurrency(totalDue),
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: totalDue > 0
                              ? AppColors.error
                              : AppColors.success,
                          iconBg: totalDue > 0
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Latest bill card
            if (latestBill != null) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Latest Bill'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.customerBillView,
                      arguments: {'billId': latestBill.billId},
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: latestBill.status == 'paid'
                              ? [Colors.green.shade600, Colors.green.shade800]
                              : latestBill.status == 'partial'
                              ? [Colors.orange.shade600, Colors.orange.shade800]
                              : [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Latest Bill',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  latestBill.billMonth,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  latestBill.status == 'paid'
                                      ? 'Fully Paid ✓'
                                      : 'Due: ${AppHelpers.formatCurrency(latestBill.balanceDue)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white60,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // My milk types
            if (_mtypes.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'My Milk Types'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mtypes.map((mt) {
                      final isMine =
                          c?.milkTypeIds.contains(mt.milkTypeId) ?? false;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.primarySubtle
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMine
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              color: isMine
                                  ? AppColors.primary
                                  : AppColors.lightGray,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mt.name,
                                  style: TextStyle(
                                    color: isMine
                                        ? AppColors.primary
                                        : AppColors.grayText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '₹${mt.pricePerLitre}/L',
                                  style: TextStyle(
                                    color: isMine
                                        ? AppColors.primary.withOpacity(0.7)
                                        : AppColors.lightGray,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — BILLS
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerBillsTab extends StatelessWidget {
  final String docId;
  const _CustomerBillsTab({required this.docId});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('My Bills'), elevation: 0.5),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('customer_id', isEqualTo: docId)
          .orderBy('generated_at', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final bills = (snap.data?.docs ?? [])
            .map(
              (d) => BillModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();
        if (bills.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No Bills Yet',
            subtitle: 'Bills are auto-generated at end of month',
          );
        }
        final totalDue = bills.fold<double>(0, (s, b) => s + b.balanceDue);
        return Column(
          children: [
            if (totalDue > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Total Due: ${AppHelpers.formatCurrency(totalDue)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: bills.length,
                itemBuilder: (ctx, i) => _CustBillTile(bill: bills[i]),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CustBillTile extends StatelessWidget {
  final BillModel bill;
  const _CustBillTile({required this.bill});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(
      context,
      AppRoutes.customerBillView,
      arguments: {'billId': bill.billId},
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billMonth,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Total: ${AppHelpers.formatCurrency(bill.finalBalance)}',
                  style: const TextStyle(
                    color: AppColors.grayText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: bill.status),
              const SizedBox(height: 4),
              Text(
                bill.balanceDue > 0
                    ? 'Due: ${AppHelpers.formatCurrency(bill.balanceDue)}'
                    : 'Cleared ✓',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: bill.balanceDue > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.lightGray,
            size: 18,
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — PAYMENTS
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerPaymentsTab extends StatelessWidget {
  final String docId;
  const _CustomerPaymentsTab({required this.docId});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('My Payments'), elevation: 0.5),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('customer_id', isEqualTo: docId)
          .orderBy('payment_date', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final payments = (snap.data?.docs ?? [])
            .map(
              (d) =>
                  PaymentModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();
        final total = payments.fold<double>(0, (s, p) => s + p.amount);

        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No Payments Yet',
            subtitle: 'Your payment history will appear here',
          );
        }
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade800],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          AppHelpers.formatCurrency(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${payments.length} payments',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: payments.length,
                itemBuilder: (ctx, i) {
                  final p = payments[i];
                  final showHeader =
                      i == 0 ||
                      DateFormat('MMMM yyyy').format(p.paymentDate) !=
                          DateFormat(
                            'MMMM yyyy',
                          ).format(payments[i - 1].paymentDate);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                          child: Text(
                            DateFormat('MMMM yyyy').format(p.paymentDate),
                            style: const TextStyle(
                              color: AppColors.grayText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      _PaymentTile(payment: p),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  Color get _color {
    switch (payment.method) {
      case 'upi':
        return const Color(0xFF7B1FA2);
      case 'bank':
        return AppColors.primaryDark;
      default:
        return const Color(0xFF388E3C);
    }
  }

  IconData get _icon {
    switch (payment.method) {
      case 'upi':
        return Icons.account_balance_wallet_outlined;
      case 'bank':
        return Icons.account_balance_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: _color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('d MMM yyyy').format(payment.paymentDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${payment.method.toUpperCase()}${payment.transactionId.isNotEmpty ? " · ${payment.transactionId}" : ""}',
                style: const TextStyle(color: AppColors.grayText, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          AppHelpers.formatCurrency(payment.amount),
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — PROFILE
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerProfileTab extends StatefulWidget {
  final CustomerModel? customer;
  final String milkmanUid;
  const _CustomerProfileTab({required this.customer, required this.milkmanUid});
  @override
  State<_CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<_CustomerProfileTab> {
  List<MilkTypeModel> _allTypes = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    if (widget.milkmanUid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('milk_types')
          .where('milkman_uid', isEqualTo: widget.milkmanUid)
          .get();
      if (mounted)
        setState(() {
          _allTypes = snap.docs
              .map((d) => MilkTypeModel.fromMap(d.data(), d.id))
              .toList();
        });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthController>().logout();
              if (context.mounted)
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.roleSelection,
                );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  LetterAvatar(
                    name: c?.name ?? '?',
                    radius: 36,
                    bg: Colors.white.withOpacity(0.25),
                    fg: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c?.name ?? 'Customer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c?.customerId ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: c?.status ?? 'active'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info section
            WhiteCard(
              child: Column(
                children: [
                  _infoTile(
                    Icons.badge_outlined,
                    'Customer ID',
                    c?.customerId ?? '-',
                  ),
                  const Divider(height: 1, indent: 50),
                  _infoTile(
                    Icons.phone_outlined,
                    'Phone',
                    c?.phone.isEmpty == true ? 'Not provided' : c?.phone ?? '-',
                  ),
                  const Divider(height: 1, indent: 50),
                  _infoTile(
                    Icons.location_on_outlined,
                    'Address',
                    c?.address ?? '-',
                  ),
                  const Divider(height: 1, indent: 50),
                  _infoTile(
                    Icons.wb_sunny_outlined,
                    'Preferred Shift',
                    (c?.preferredShift ?? 'morning')[0].toUpperCase() +
                        (c?.preferredShift ?? 'morning').substring(1),
                  ),
                  const Divider(height: 1, indent: 50),
                  _infoTile(
                    Icons.calendar_today_outlined,
                    'Customer Since',
                    c != null ? AppHelpers.formatDate(c.startDate) : '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Milk types
            if (_allTypes.isNotEmpty) ...[
              const Text(
                'Milk Types',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 10),
              WhiteCard(
                child: Column(
                  children: _allTypes.asMap().entries.map((entry) {
                    final i = entry.key;
                    final mt = entry.value;
                    final mine =
                        c?.milkTypeIds.contains(mt.milkTypeId) ?? false;
                    return Column(
                      children: [
                        if (i > 0) const Divider(height: 1, indent: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: mine
                                      ? AppColors.primarySubtle
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.water_drop_rounded,
                                  color: mine
                                      ? AppColors.primary
                                      : AppColors.lightGray,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mt.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '₹${mt.pricePerLitre} / litre',
                                      style: const TextStyle(
                                        color: AppColors.grayText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      mine
                                          ? Icons.check_circle_rounded
                                          : Icons.remove_circle_outline_rounded,
                                      size: 14,
                                      color: mine
                                          ? AppColors.success
                                          : AppColors.lightGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      mine ? 'Subscribed' : 'Not subscribed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mine
                                            ? AppColors.success
                                            : AppColors.lightGray,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.grayText, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER BILL VIEW (read-only)
// ══════════════════════════════════════════════════════════════════════════════

class CustomerBillViewScreen extends StatefulWidget {
  const CustomerBillViewScreen({super.key});
  @override
  State<CustomerBillViewScreen> createState() => _CustomerBillViewState();
}

class _CustomerBillViewState extends State<CustomerBillViewScreen> {
  BillModel? _bill;
  List<BillItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final bid = args['billId'] as String;
    setState(() => _loading = true);
    try {
      final bDoc = await FirebaseFirestore.instance
          .collection('bills')
          .doc(bid)
          .get();
      if (bDoc.exists) _bill = BillModel.fromMap(bDoc.data()!, bDoc.id);
      final iSnap = await FirebaseFirestore.instance
          .collection('bill_items')
          .where('bill_id', isEqualTo: bid)
          .orderBy('date')
          .get();
      _items = iSnap.docs
          .map((d) => BillItemModel.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(bill != null ? 'Bill — ${bill.billMonth}' : 'Bill'),
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : bill == null
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Bill not found',
              subtitle: '',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Receipt hero
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'milkbiz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            StatusBadge(status: bill.status),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppHelpers.formatCurrency(bill.finalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bill.billMonth,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bill.status == 'paid'
                                ? 'FULLY PAID'
                                : 'Due: ${AppHelpers.formatCurrency(bill.balanceDue)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery table
                  _DeliveryTable(items: _items),
                  const SizedBox(height: 16),

                  // Summary
                  WhiteCard(
                    child: Column(
                      children: [
                        _sumRow(
                          'Milk Charges',
                          AppHelpers.formatCurrency(bill.totalAmount),
                        ),
                        if (bill.previousBalance > 0)
                          _sumRow(
                            'Previous Balance',
                            AppHelpers.formatCurrency(bill.previousBalance),
                            color: AppColors.warning,
                          ),
                        const Divider(height: 16),
                        _sumRow(
                          'Grand Total',
                          AppHelpers.formatCurrency(bill.finalBalance),
                          bold: true,
                        ),
                        _sumRow(
                          'Amount Paid',
                          AppHelpers.formatCurrency(bill.paidAmount),
                          color: AppColors.success,
                        ),
                        const Divider(height: 16),
                        _sumRow(
                          'Balance Due',
                          AppHelpers.formatCurrency(bill.balanceDue),
                          bold: true,
                          color: bill.balanceDue > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status message
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bill.status == 'paid'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: bill.status == 'paid'
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          bill.status == 'paid'
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: bill.status == 'paid'
                              ? AppColors.success
                              : AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bill.status == 'paid'
                                ? 'This bill is fully paid. Thank you!'
                                : 'Please pay ${AppHelpers.formatCurrency(bill.balanceDue)} to your milkman.',
                            style: TextStyle(
                              color: bill.status == 'paid'
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _sumRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.darkGray : AppColors.grayText,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 15 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    ),
  );
}

class _DeliveryTable extends StatelessWidget {
  final List<BillItemModel> items;
  const _DeliveryTable({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amt',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: e.key.isEven ? Colors.white : const Color(0xFFFAFAFA),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      DateFormat('d MMM').format(e.value.date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.value.milkTypeName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${e.value.quantity}L',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${e.value.rate}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      AppHelpers.formatCurrency(e.value.amount),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 10,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    AppHelpers.formatCurrency(
                      items.fold(0.0, (s, i) => s + i.amount),
                    ),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
