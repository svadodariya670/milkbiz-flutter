import 'package:flutter/material.dart';
import 'package:milkbiz/models/models.dart';
import 'package:milkbiz/services/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/controllers.dart';
//import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/widgets.dart';
import 'milkman_bills.dart'; // MilkTypesScreen

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE TAB
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanProfileTab extends StatelessWidget {
  const MilkmanProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile'), elevation: 0.5, automaticallyImplyLeading: false),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Profile hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(children: [
                    LetterAvatar(name: user.ownerName, radius: 36,
                        bg: Colors.white.withOpacity(0.22), fg: Colors.white),
                    const SizedBox(height: 12),
                    Text(user.ownerName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user.businessName, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _PillChip(label: user.milkmanId, icon: Icons.badge_outlined),
                      const SizedBox(width: 8),
                      _PillChip(label: user.subscriptionPlan.toUpperCase(), icon: Icons.workspace_premium_rounded),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // Subscription status
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: user.isSubscriptionActive ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: user.isSubscriptionActive ? AppColors.success : AppColors.error, width: 0.8),
                    ),
                    child: Row(children: [
                      Icon(
                        user.isSubscriptionActive ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                        color: user.isSubscriptionActive ? AppColors.success : AppColors.error, size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          user.isSubscriptionActive ? 'Subscription Active' : 'Subscription Expired',
                          style: TextStyle(fontWeight: FontWeight.bold, color: user.isSubscriptionActive ? AppColors.success : AppColors.error),
                        ),
                        Text(
                          '${user.subscriptionPlan.toUpperCase()}  •  Expires ${AppHelpers.formatDate(user.subscriptionExpiry)}',
                          style: const TextStyle(color: AppColors.grayText, fontSize: 12),
                        ),
                      ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: user.isSubscriptionActive ? AppColors.success : AppColors.error, size: 16),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Info card
                WhiteCard(padding: EdgeInsets.zero, child: Column(children: [
                  InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                  const Divider(height: 1, indent: 52),
                  InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone.isNotEmpty ? user.phone : '—'),
                  const Divider(height: 1, indent: 52),
                  InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: user.address),
                  const Divider(height: 1, indent: 52),
                  InfoRow(icon: Icons.map_outlined, label: 'Service Area', value: user.area),
                  const Divider(height: 1, indent: 52),
                  InfoRow(icon: Icons.people_rounded, label: 'Max Customers',
                      value: user.maxCustomers == -1 ? 'Unlimited' : '${user.maxCustomers}'),
                ])),
                const SizedBox(height: 14),

                // Action tiles
                _ActionTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                  sub: 'Update your business details',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Milk Types',
                  sub: 'Manage milk types & prices',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MilkTypesScreen())),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Monthly Summary',
                  sub: 'View billing summary by month',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.monthlySummary),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Payment History',
                  sub: 'All payments received',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.paymentHistory),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Subscription Plans',
                  sub: 'Upgrade or manage your plan',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
                ),
                const SizedBox(height: 20),

                // Logout button
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await AppHelpers.confirm(context,
                        title: 'Logout', message: 'Are you sure you want to logout?',
                        confirmText: 'Logout');
                    if (ok && context.mounted) {
                      await context.read<AuthController>().logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
                      }
                    }
                  },
                  icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                  label: Text('Logout', style: TextStyle(color: Colors.red.shade600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PillChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primarySubtle, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(sub, style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.lightGray, size: 16),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form    = GlobalKey<FormState>();
  final _owner   = TextEditingController();
  final _biz     = TextEditingController();
  final _phone   = TextEditingController();
  final _address = TextEditingController();
  final _area    = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final user = context.read<AuthController>().user;
      if (user != null) {
        _owner.text   = user.ownerName;
        _biz.text     = user.businessName;
        _phone.text   = user.phone;
        _address.text = user.address;
        _area.text    = user.area;
      }
      _init = true;
    }
  }

  @override void dispose() {
    for (final c in [_owner, _biz, _phone, _address, _area]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.updateProfile({
      'owner_name':    _owner.text.trim(),
      'business_name': _biz.text.trim(),
      'phone':         _phone.text.trim(),
      'address':       _address.text.trim(),
      'area':          _area.text.trim(),
    });
    if (!mounted) return;
    if (ok) { AppHelpers.showSnack(context, 'Profile updated'); Navigator.pop(context); }
    else AppHelpers.showSnack(context, auth.error ?? 'Error', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Edit Profile'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(children: [
              AppTextField(label: 'Owner Name', controller: _owner,
                  validator: (v) => Validators.required(v, field: 'Name'),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.grayText)),
              const SizedBox(height: 14),
              AppTextField(label: 'Business Name', controller: _biz,
                  validator: (v) => Validators.required(v, field: 'Business name'),
                  prefixIcon: const Icon(Icons.store_outlined, color: AppColors.grayText)),
              const SizedBox(height: 14),
              AppTextField(label: 'Phone', controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.grayText)),
              const SizedBox(height: 14),
              AppTextField(label: 'Address', controller: _address, maxLines: 2,
                  validator: (v) => Validators.required(v, field: 'Address'),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.grayText)),
              const SizedBox(height: 14),
              AppTextField(label: 'Service Area', controller: _area,
                  validator: (v) => Validators.required(v, field: 'Service area'),
                  prefixIcon: const Icon(Icons.map_outlined, color: AppColors.grayText)),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: auth.isLoading ? null : _save, child: const Text('Save Changes')),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final plans = [
      {'id': 'free',     'name': 'Free Trial', 'price': '₹0',   'period': '30 days', 'customers': '10',        'color': AppColors.grayText},
      {'id': 'basic',    'name': 'Basic',       'price': '₹199', 'period': '/month',  'customers': '50',        'color': AppColors.primary},
      {'id': 'standard', 'name': 'Standard',   'price': '₹499', 'period': '/month',  'customers': '100',       'color': const Color(0xFF7B1FA2)},
      {'id': 'premium',  'name': 'Premium',    'price': '₹799', 'period': '/month',  'customers': 'Unlimited', 'color': const Color(0xFFE65100)},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subscription'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Current Plan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(user.subscriptionPlan.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(user.isSubscriptionActive
                        ? 'Active until ${AppHelpers.formatDate(user.subscriptionExpiry)}'
                        : 'Expired — please upgrade',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white70, size: 40),
                ]),
              ),
              const SizedBox(height: 20),
            ],
            const Text('Choose a Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGray)),
            const SizedBox(height: 16),
            ...plans.map((plan) {
              final isCurrent = user?.subscriptionPlan == plan['id'];
              final color     = plan['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent ? color.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isCurrent ? color : AppColors.divider, width: isCurrent ? 2 : 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(plan['name'] as String,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                            child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Text('${plan['customers']} customers', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(plan['price'] as String, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(plan['period'] as String, style: const TextStyle(color: AppColors.grayText, fontSize: 11)),
                    const SizedBox(height: 8),
                    if (!isCurrent && plan['id'] != 'free')
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : () async {
                          final ok = await AppHelpers.confirm(context,
                              title: 'Upgrade to ${plan['name']}',
                              message: 'Upgrade for ${plan['price']}/month? (Demo — no real payment)',
                              confirmText: 'Upgrade', danger: false);
                          if (ok && context.mounted) {
                            final success = await auth.upgradePlan(plan['id'] as String);
                            if (context.mounted) AppHelpers.showSnack(context,
                                success ? 'Upgraded to ${plan['name']}!' : auth.error ?? 'Error', error: !success);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color, minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
                      ),
                  ]),
                ]),
              );
            }),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 17),
                const SizedBox(width: 10),
                Expanded(child: Text('This is a demo app. In production, payment gateway (Razorpay/UPI) would be integrated.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MONTHLY SUMMARY SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});
  @override State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime _month = DateTime.now();
  List<BillModel> _bills = [];
  bool _loading = true;

  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid  = context.read<AuthController>().user?.uid ?? '';
    final mKey = AppHelpers.monthKey(_month);
    try {
      final all = await context.read<BillController>().watchBills(uid).first;
      _bills = all.where((b) => b.billMonth == mKey).toList();
      _bills.sort((a, b) => a.customerName.compareTo(b.customerName));
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final total     = _bills.fold<double>(0, (s, b) => s + b.totalAmount);
    final collected = _bills.fold<double>(0, (s, b) => s + b.paidAmount);
    final due       = _bills.fold<double>(0, (s, b) => s + b.balanceDue);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Monthly Summary'), elevation: 0.5),
      body: Column(children: [
        // Month nav
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 28),
              onPressed: () { setState(() => _month = DateTime(_month.year, _month.month - 1)); _load(); },
            ),
            Expanded(child: Text(AppHelpers.formatMonth(_month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGray))),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, size: 28,
                  color: (_month.year < DateTime.now().year || _month.month < DateTime.now().month)
                      ? AppColors.primary : AppColors.divider),
              onPressed: (_month.year < DateTime.now().year || _month.month < DateTime.now().month)
                  ? () { setState(() => _month = DateTime(_month.year, _month.month + 1)); _load(); }
                  : null,
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _bills.isEmpty
                  ? const EmptyState(icon: Icons.bar_chart_outlined, title: 'No Bills', subtitle: 'No bills for this month')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        child: Column(children: [
                          // Stats
                          Row(children: [
                            Expanded(child: StatCard(label: 'Total Billed', value: AppHelpers.formatCurrency(total),
                                icon: Icons.receipt_long_rounded)),
                            const SizedBox(width: 10),
                            Expanded(child: StatCard(label: 'Collected', value: AppHelpers.formatCurrency(collected),
                                icon: Icons.check_circle_outline_rounded, iconColor: AppColors.success, iconBg: const Color(0xFFE8F5E9))),
                            const SizedBox(width: 10),
                            Expanded(child: StatCard(label: 'Outstanding', value: AppHelpers.formatCurrency(due),
                                icon: Icons.pending_outlined,
                                iconColor: due > 0 ? AppColors.error : AppColors.success,
                                iconBg: due > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9))),
                          ]),
                          const SizedBox(height: 16),
                          const Align(alignment: Alignment.centerLeft,
                              child: Text('Customer Wise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          const SizedBox(height: 8),
                          ..._bills.map((b) => GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.billDetail, arguments: {'billId': b.billId}),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                              ),
                              child: Row(children: [
                                LetterAvatar(name: b.customerName, radius: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(b.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text(AppHelpers.formatCurrency(b.finalBalance), style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
                                ])),
                                StatusBadge(status: b.status),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.lightGray, size: 18),
                              ]),
                            ),
                          )),
                        ]),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAYMENT HISTORY SCREEN (Milkman side)
// ══════════════════════════════════════════════════════════════════════════════

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment History'), elevation: 0.5),
      body: StreamBuilder<List<PaymentModel>>(
        stream: PaymentService().watchByMilkman(uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final payments = snap.data ?? [];
          if (payments.isEmpty) return const EmptyState(icon: Icons.payments_outlined, title: 'No Payments', subtitle: 'No payments recorded yet');
          final total = payments.fold<double>(0, (s, p) => s + p.amount);

          return Column(children: [
            Container(
              width: double.infinity, margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF1B5E20)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Collected', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(AppHelpers.formatCurrency(total), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ])),
                Text('${payments.length} payments', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: payments.length,
              itemBuilder: (_, i) => _PayCard(p: payments[i]),
            )),
          ]);
        },
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  final PaymentModel p;
  const _PayCard({required this.p});

  Color get _c => p.method == 'upi' ? const Color(0xFF7B1FA2) : p.method == 'bank' ? AppColors.primaryDark : AppColors.success;
  IconData get _i => p.method == 'upi' ? Icons.account_balance_wallet_outlined : p.method == 'bank' ? Icons.account_balance_outlined : Icons.payments_outlined;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: _c.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_i, color: _c, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${AppHelpers.formatDate(p.paymentDate)}  •  ${p.method.toUpperCase()}',
                style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
          ])),
          Text(AppHelpers.formatCurrency(p.amount), style: TextStyle(color: _c, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      );
}
