import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/controllers.dart';
//import '../../models/models.dart';
//import '../../models/customer_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/widgets.dart';

class MilkmanDashboardTab extends StatefulWidget {
  const MilkmanDashboardTab({super.key});
  @override
  State<MilkmanDashboardTab> createState() => _MilkmanDashboardTabState();
}

class _MilkmanDashboardTabState extends State<MilkmanDashboardTab> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();

      // 🔥 WAIT until user is available
      await Future.delayed(const Duration(milliseconds: 500));

      final uid = auth.user?.uid ?? '';

      print("DASHBOARD UID = $uid"); // DEBUG

      await context.read<MilkTypeController>().load(uid);
      await context.read<CustomerController>().load(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final custCtrl = context.watch<CustomerController>();
    final mtCtrl = context.watch<MilkTypeController>();
    final user = auth.user;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await custCtrl.load(uid);
          await mtCtrl.load(uid);
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero App Bar ──────────────────────────────────────────────────
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                                      color: Colors.white.withOpacity(0.82),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.businessName ?? 'milkbiz',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Date chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat('d MMM yyyy').format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Subscription warning
                        if (user != null && !user.isSubscriptionActive)
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.subscription,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Subscription expired — Tap to renew',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // SizedBox(height: 20),
            // ── Stats Row ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, 0), // reduced overlap (safe)
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    0,
                  ), // added top spacing
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Customers',
                          value: '${custCtrl.total}',
                          icon: Icons.people_rounded,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Active',
                          value: '${custCtrl.active}',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.success,
                          iconBg: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Milk Types',
                          value: '${mtCtrl.activeTypes.length}',
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF7B1FA2),
                          iconBg: const Color(0xFFF3E5F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────────────────
            SliverToBoxAdapter(child: SectionHeader(title: 'Quick Actions')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _QuickBtn(
                      label: 'Add Entry',
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.addEntry),
                    ),
                    const SizedBox(width: 10),
                    _QuickBtn(
                      label: 'Add Customer',
                      icon: Icons.person_add_rounded,
                      color: const Color(0xFF7B1FA2),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.addCustomer),
                    ),
                    const SizedBox(width: 10),
                    _QuickBtn(
                      label: 'View Bills',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF388E3C),
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _QuickBtn(
                      label: 'Summary',
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFFE65100),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.monthlySummary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Recent Customers ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Customers',
                action: 'See All',
                onAction: () {},
              ),
            ),
            if (custCtrl.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else if (custCtrl.customers.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No Customers Yet',
                  subtitle: 'Add your first customer to get started',
                  btnLabel: 'Add Customer',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.addCustomer),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final list = custCtrl.customers.take(5).toList();
                  if (i >= list.length) return null;
                  return _CustomerTile(c: list[i]);
                }, childCount: custCtrl.customers.take(5).length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.darkGray,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CustomerTile extends StatelessWidget {
  final dynamic c;
  const _CustomerTile({required this.c});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.customerDetail,
        arguments: {'docId': c.docId},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            LetterAvatar(name: c.name, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    c.customerId,
                    style: const TextStyle(
                      color: AppColors.grayText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: c.status),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.lightGray,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
