import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../models/milk_type_model.dart';
//import '../../models/customer_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BILLS TAB
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanBillsTab extends StatefulWidget {
  const MilkmanBillsTab({super.key});
  @override State<MilkmanBillsTab> createState() => _MilkmanBillsTabState();
}

class _MilkmanBillsTabState extends State<MilkmanBillsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bills'), elevation: 0.5, automaticallyImplyLeading: false),
      body: Column(children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['all', 'unpaid', 'partial', 'paid'].map((f) {
              final sel = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(f[0].toUpperCase() + f.substring(1),
                      style: TextStyle(color: sel ? Colors.white : AppColors.grayText,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                ),
              );
            }).toList()),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<BillModel>>(
            stream: context.read<BillController>().watchBills(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final all   = snap.data ?? [];
              final bills = _filter == 'all' ? all : all.where((b) => b.status == _filter).toList();
              final totalDue = bills.fold<double>(0, (s, b) => s + b.balanceDue);

              if (bills.isEmpty) return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Bills',
                subtitle: _filter == 'all' ? 'Bills are auto-generated at end of month' : 'No ${_filter} bills',
              );

              return Column(children: [
                if (totalDue > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 10),
                      Text('Outstanding: ${AppHelpers.formatCurrency(totalDue)}',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                Expanded(child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: bills.length,
                  itemBuilder: (ctx, i) => _BillCard(bill: bills[i]),
                )),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.billDetail, arguments: {'billId': bill.billId}),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bill.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(bill.billMonth, style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
              ])),
              StatusBadge(status: bill.status),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              _Amt(label: 'Total', value: AppHelpers.formatCurrency(bill.finalBalance), color: AppColors.darkGray),
              _Amt(label: 'Paid', value: AppHelpers.formatCurrency(bill.paidAmount), color: AppColors.success),
              _Amt(label: 'Balance', value: AppHelpers.formatCurrency(bill.balanceDue),
                  color: bill.balanceDue > 0 ? AppColors.error : AppColors.success),
            ]),
            if (bill.status != 'paid') ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addPayment, arguments: {'billId': bill.billId}),
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: const Text('Record Payment'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 38)),
              ),
            ],
          ]),
        ),
      );
}

class _Amt extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Amt({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// BILL DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key});
  @override State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  BillModel? _bill;
  List<BillItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  Future<void> _load() async {
    final args   = ModalRoute.of(context)!.settings.arguments as Map;
    final billId = args['billId'] as String;
    final ctrl   = context.read<BillController>();
    await ctrl.loadItems(billId);
    final uid = context.read<AuthController>().user?.uid ?? '';
    // Get bill from stream's first snapshot
    final allBills = await ctrl.watchBills(uid).first;
    _bill  = allBills.where((b) => b.billId == billId).firstOrNull;
    _items = ctrl.items;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(bill != null ? 'Bill — ${bill.billMonth}' : 'Bill'),
        elevation: 0.5,
        actions: [
          if (bill != null && bill.paidAmount == 0)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
              onPressed: () async {
                final ok = await AppHelpers.confirm(context,
                    title: 'Delete Bill', message: 'Delete this bill? Entries will be unlocked.');
                if (!ok || !mounted) return;
                final ctrl = context.read<BillController>();
                final success = await ctrl.deleteBill(bill);
                if (mounted) {
                  AppHelpers.showSnack(context, success ? 'Bill deleted' : ctrl.error ?? 'Error', error: !success);
                  if (success) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : bill == null
              ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Bill not found', subtitle: '')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.water_drop, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          const Text('milkbiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          StatusBadge(status: bill.status),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Customer', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            Text(bill.customerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(bill.customerReadableId, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('Bill Month', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            Text(bill.billMonth, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                        ]),
                        const SizedBox(height: 14),
                        Center(child: Column(children: [
                          Text('Grand Total', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          Text(AppHelpers.formatCurrency(bill.finalBalance),
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                          if (bill.balanceDue > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(20)),
                              child: Text('Due: ${AppHelpers.formatCurrency(bill.balanceDue)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    if (bill.status != 'paid')
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.addPayment,
                            arguments: {'billId': bill.billId}).then((_) => _load()),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text('Record Payment'),
                      ),
                    const SizedBox(height: 14),

                    // Delivery table
                    WhiteCard(padding: EdgeInsets.zero, child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(children: const [
                          Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary))),
                          Expanded(flex: 3, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary))),
                          Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary))),
                          Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary))),
                          Expanded(flex: 2, child: Text('Amt', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary))),
                        ]),
                      ),
                      ..._items.asMap().entries.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        color: e.key.isEven ? Colors.white : const Color(0xFFFAFAFA),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(DateFormat('d MMM').format(e.value.date), style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 3, child: Text(e.value.milkTypeName, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text('${e.value.quantity}L', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text('₹${e.value.rate}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text(AppHelpers.formatCurrency(e.value.amount), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        ]),
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(color: AppColors.primarySubtle, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                        child: Row(children: [
                          const Expanded(child: Text('Milk Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary))),
                          Text(AppHelpers.formatCurrency(_items.fold(0.0, (s, i) => s + i.amount)),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        ]),
                      ),
                    ])),
                    const SizedBox(height: 14),

                    // Summary
                    WhiteCard(child: Column(children: [
                      _SRow('Milk Charges', AppHelpers.formatCurrency(bill.totalAmount), AppColors.darkGray),
                      if (bill.previousBalance > 0)
                        _SRow('Previous Balance', AppHelpers.formatCurrency(bill.previousBalance), Colors.orange),
                      const Divider(height: 16),
                      _SRow('Grand Total', AppHelpers.formatCurrency(bill.finalBalance), AppColors.darkGray, bold: true),
                      _SRow('Paid', AppHelpers.formatCurrency(bill.paidAmount), AppColors.success),
                      const Divider(height: 16),
                      _SRow('Balance Due', AppHelpers.formatCurrency(bill.balanceDue),
                          bill.balanceDue > 0 ? AppColors.error : AppColors.success, bold: true),
                    ])),
                    const SizedBox(height: 60),
                  ]),
                ),
    );
  }
}

class _SRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _SRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: bold ? AppColors.darkGray : AppColors.grayText,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 14)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: bold ? 16 : 14)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD PAYMENT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});
  @override State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _form   = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _txn    = TextEditingController();
  String _method = 'cash';
  BillModel? _bill;
  bool _loadingBill = true;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _loadBill()); }

  Future<void> _loadBill() async {
    final args   = ModalRoute.of(context)!.settings.arguments as Map;
    final billId = args['billId'] as String;
    final uid    = context.read<AuthController>().user?.uid ?? '';
    final all    = await context.read<BillController>().watchBills(uid).first;
    _bill = all.where((b) => b.billId == billId).firstOrNull;
    if (_bill != null) _amount.text = _bill!.balanceDue.toStringAsFixed(0);
    setState(() => _loadingBill = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _bill == null) return;
    final amt = double.parse(_amount.text);
    if (amt > _bill!.balanceDue) {
      AppHelpers.showSnack(context, 'Amount exceeds balance due', error: true); return;
    }
    final auth = context.read<AuthController>();
    final ctrl = context.read<BillController>();
    final ok = await ctrl.addPayment(
      billId: _bill!.billId, milkmanUid: auth.user!.uid,
      customerId: _bill!.customerId, customerName: _bill!.customerName,
      amount: amt, method: _method, txnId: _txn.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, 'Payment recorded!');
      Navigator.pop(context);
    } else {
      AppHelpers.showSnack(context, ctrl.error ?? 'Error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BillController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Record Payment'), elevation: 0.5),
      body: _loadingBill
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : LoadingOverlay(
              isLoading: ctrl.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_bill != null) WhiteCard(child: Column(children: [
                      _SRow2('Customer', _bill!.customerName),
                      _SRow2('Bill Month', _bill!.billMonth),
                      _SRow2('Total', AppHelpers.formatCurrency(_bill!.finalBalance)),
                      _SRow2('Paid', AppHelpers.formatCurrency(_bill!.paidAmount)),
                      const Divider(),
                      _SRow2('Balance Due', AppHelpers.formatCurrency(_bill!.balanceDue), bold: true, valueColor: AppColors.error),
                    ])),
                    const SizedBox(height: 20),
                    AppTextField(label: 'Amount (₹)', controller: _amount,
                        validator: Validators.positiveNumber,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Padding(padding: EdgeInsets.all(14),
                            child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grayText)))),
                    const SizedBox(height: 20),
                    const Text('Payment Method', style: TextStyle(color: AppColors.grayText, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _MethodTile('Cash', Icons.payments_outlined, 'cash', _method, (m) => setState(() => _method = m)),
                      const SizedBox(width: 10),
                      _MethodTile('UPI', Icons.account_balance_wallet_outlined, 'upi', _method, (m) => setState(() => _method = m)),
                      const SizedBox(width: 10),
                      _MethodTile('Bank', Icons.account_balance_outlined, 'bank', _method, (m) => setState(() => _method = m)),
                    ]),
                    if (_method != 'cash') ...[
                      const SizedBox(height: 16),
                      AppTextField(label: 'Transaction ID (optional)', controller: _txn,
                          prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.grayText)),
                    ],
                    const SizedBox(height: 28),
                    ElevatedButton(onPressed: ctrl.isLoading ? null : _save, child: const Text('Record Payment')),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _SRow2 extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _SRow2(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppColors.grayText, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 15 : 13, color: valueColor ?? AppColors.darkGray)),
        ]),
      );
}

class _MethodTile extends StatelessWidget {
  final String label, method, current;
  final IconData icon;
  final void Function(String) onSelect;
  const _MethodTile(this.label, this.icon, this.method, this.current, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final sel = method == current;
    return Expanded(child: GestureDetector(
      onTap: () => onSelect(method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : AppColors.divider, width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? Colors.white : AppColors.grayText, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.grayText,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 12)),
        ]),
      ),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MILK TYPES SCREEN (full standalone screen, navigated from profile or drawer)
// ══════════════════════════════════════════════════════════════════════════════

class MilkTypesScreen extends StatelessWidget {
  const MilkTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final uid  = auth.user?.uid ?? '';
    final ctrl = context.watch<MilkTypeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Milk Types'), elevation: 0.5),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, uid),
        child: const Icon(Icons.add),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ctrl.types.isEmpty
              ? EmptyState(
                  icon: Icons.water_drop_outlined,
                  title: 'No Milk Types',
                  subtitle: 'Add types like Cow, Buffalo, Mixed',
                  btnLabel: 'Add Milk Type',
                  onAction: () => _showAddSheet(context, uid),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: ctrl.types.length,
                  itemBuilder: (_, i) => _MilkTypeCard(mt: ctrl.types[i], uid: uid),
                ),
    );
  }

  void _showAddSheet(BuildContext ctx, String uid) => showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AddMilkTypeSheet(uid: uid),
      );
}

class _MilkTypeCard extends StatelessWidget {
  final MilkTypeModel mt;
  final String uid;
  const _MilkTypeCard({required this.mt, required this.uid});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<MilkTypeController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mt.isActive ? AppColors.primary.withOpacity(0.25) : AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: mt.isActive ? AppColors.primarySubtle : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.water_drop_rounded, color: mt.isActive ? AppColors.primary : AppColors.lightGray, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mt.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('₹${mt.pricePerLitre.toStringAsFixed(2)} / litre',
              style: const TextStyle(color: AppColors.grayText, fontSize: 13)),
        ])),
        Switch(
          value: mt.isActive,
          activeColor: AppColors.primary,
          onChanged: (v) async {
            final ok = await ctrl.toggle(mt.milkTypeId, mt.isActive, uid);
            if (!ok && context.mounted) {
              AppHelpers.showSnack(context, ctrl.error ?? 'Cannot change', error: true);
              ctrl.clearError();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
          onPressed: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => _EditMilkTypeSheet(mt: mt, uid: uid),
          ),
        ),
      ]),
    );
  }
}

class _AddMilkTypeSheet extends StatefulWidget {
  final String uid;
  const _AddMilkTypeSheet({required this.uid});
  @override State<_AddMilkTypeSheet> createState() => _AddMilkTypeSheetState();
}

class _AddMilkTypeSheetState extends State<_AddMilkTypeSheet> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _price = TextEditingController();

  @override void dispose() { _name.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<MilkTypeController>();
    final ok = await ctrl.add(widget.uid, _name.text.trim(), double.parse(_price.text));
    if (!mounted) return;
    if (ok) { AppHelpers.showSnack(context, 'Milk type added'); Navigator.pop(context); }
    else AppHelpers.showSnack(context, ctrl.error ?? 'Error', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MilkTypeController>();
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SheetHandle(),
          const Text('Add Milk Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTextField(label: 'Name', hint: 'e.g. Cow, Buffalo, Mixed', controller: _name,
              validator: (v) => Validators.required(v, field: 'Name')),
          const SizedBox(height: 14),
          AppTextField(label: 'Price per Litre (₹)', controller: _price,
              validator: Validators.positiveNumber,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 22),
          ElevatedButton(onPressed: ctrl.isLoading ? null : _save, child: const Text('Add Milk Type')),
        ]),
      ),
    );
  }
}

class _EditMilkTypeSheet extends StatefulWidget {
  final MilkTypeModel mt;
  final String uid;
  const _EditMilkTypeSheet({required this.mt, required this.uid});
  @override State<_EditMilkTypeSheet> createState() => _EditMilkTypeSheetState();
}

class _EditMilkTypeSheetState extends State<_EditMilkTypeSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.mt.name);
    _price = TextEditingController(text: widget.mt.pricePerLitre.toString());
  }
  @override void dispose() { _name.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<MilkTypeController>();
    final ok = await ctrl.update(widget.mt.milkTypeId, widget.uid,
        {'name': _name.text.trim(), 'price_per_litre': double.parse(_price.text)});
    if (!mounted) return;
    if (ok) { AppHelpers.showSnack(context, 'Updated. New price applies to future bills only.'); Navigator.pop(context); }
    else AppHelpers.showSnack(context, ctrl.error ?? 'Error', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MilkTypeController>();
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SheetHandle(),
          const Text('Edit Milk Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Price change only affects future bills — existing bills are frozen.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 12))),
              ])),
          const SizedBox(height: 16),
          AppTextField(label: 'Name', controller: _name, validator: (v) => Validators.required(v, field: 'Name')),
          const SizedBox(height: 14),
          AppTextField(label: 'Price per Litre (₹)', controller: _price, validator: Validators.positiveNumber,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 22),
          ElevatedButton(onPressed: ctrl.isLoading ? null : _save, child: const Text('Save Changes')),
        ]),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Container(
    width: 38, height: 4, margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
  ));
}


// ══════════════════════════════════════════════════════════════════════════════
// DAILY ENTRIES TAB
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanEntriesTab extends StatefulWidget {
  const MilkmanEntriesTab({super.key});
  @override State<MilkmanEntriesTab> createState() => _MilkmanEntriesTabState();
}

class _MilkmanEntriesTabState extends State<MilkmanEntriesTab> {
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().user?.uid ?? '';
      context.read<CustomerController>().load(uid);
      context.read<MilkTypeController>().load(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid ?? '';
    final isToday = _date.year == DateTime.now().year &&
        _date.month == DateTime.now().month &&
        _date.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Entries'),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final p = await showDatePicker(
                context: context, initialDate: _date,
                firstDate: DateTime(2024), lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                  child: child!,
                ),
              );
              if (p != null) setState(() => _date = p);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addEntry),
        icon: const Icon(Icons.add), label: const Text('Add Entry'),
      ),
      body: Column(children: [
        // Date navigator
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 28),
              onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
            ),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(color: AppColors.primarySubtle, borderRadius: BorderRadius.circular(12)),
              child: Text(
                isToday ? 'Today — ${DateFormat('d MMM yyyy').format(_date)}'
                    : DateFormat('EEE, d MMM yyyy').format(_date),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            )),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, size: 28,
                  color: isToday ? AppColors.divider : AppColors.primary),
              onPressed: isToday ? null : () => setState(() => _date = _date.add(const Duration(days: 1))),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<DailyEntryModel>>(
            stream: context.read<EntryController>().watch(uid, _date),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final entries = snap.data ?? [];
              if (entries.isEmpty) {
                return EmptyState(
                  icon: Icons.edit_calendar_outlined,
                  title: 'No Entries',
                  subtitle: 'No deliveries for ${DateFormat('d MMM yyyy').format(_date)}',
                  btnLabel: 'Add Entry',
                  onAction: () => Navigator.pushNamed(context, AppRoutes.addEntry),
                );
              }

              final delivered = entries.where((e) => e.status == 'delivered').length;
              final totalL = entries.where((e) => e.status == 'delivered').fold(0.0, (s, e) => s + e.quantity);

              // Group by customer
              final Map<String, List<DailyEntryModel>> grouped = {};
              for (final e in entries) grouped.putIfAbsent(e.customerName, () => []).add(e);

              return Column(children: [
                // Summary strip
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    _SChip(label: '${entries.length} entries', color: AppColors.primary),
                    const SizedBox(width: 8),
                    _SChip(label: '$delivered delivered', color: AppColors.success),
                    const SizedBox(width: 8),
                    _SChip(label: '${totalL.toStringAsFixed(1)}L', color: AppColors.primaryDark),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  children: grouped.entries.map((g) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                        child: Row(children: [
                          LetterAvatar(name: g.key, radius: 13),
                          const SizedBox(width: 8),
                          Text(g.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ]),
                      ),
                      ...g.value.map((e) => _EntryRow(entry: e, uid: uid)),
                      const SizedBox(height: 4),
                    ],
                  )).toList(),
                )),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _SChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _EntryRow extends StatelessWidget {
  final DailyEntryModel entry;
  final String uid;
  const _EntryRow({required this.entry, required this.uid});

  Color get _statusColor {
    switch (entry.status) {
      case 'delivered': return AppColors.success;
      case 'skipped':   return AppColors.error;
      default:          return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Dismissible(
      key: Key(entry.entryId),
      direction: entry.isLocked ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) => AppHelpers.confirm(context, title: 'Delete Entry', message: 'Delete this entry?'),
      onDismissed: (_) async {
        final ctrl = context.read<EntryController>();
        await ctrl.delete(entry.entryId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
      child: GestureDetector(
        onTap: entry.isLocked ? null : () => _showEditSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: _statusColor, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.milkTypeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${entry.quantity} L  ·  ${entry.status}',
                  style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
              if (entry.note.isNotEmpty) Text(entry.note, style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
            ])),
            if (entry.isLocked) ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_outline, size: 11, color: AppColors.lightGray),
                    SizedBox(width: 4),
                    Text('Locked', style: TextStyle(color: AppColors.lightGray, fontSize: 10)),
                  ])),
            ] else ...[
              GestureDetector(onTap: () => _showEditSheet(context),
                  child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primarySubtle, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 15))),
              const SizedBox(width: 6),
              GestureDetector(onTap: () async {
                final ok = await AppHelpers.confirm(context, title: 'Delete Entry', message: 'Delete this entry?');
                if (ok && context.mounted) await context.read<EntryController>().delete(entry.entryId);
              },
                  child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 15))),
            ],
          ]),
        ),
      ),
    );
    return card;
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditEntrySheet(entry: entry),
    );
  }
}

class _EditEntrySheet extends StatefulWidget {
  final DailyEntryModel entry;
  const _EditEntrySheet({required this.entry});
  @override State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _qty;
  late TextEditingController _note;
  late String _status;

  @override
  void initState() {
    super.initState();
    _qty    = TextEditingController(text: widget.entry.quantity.toString());
    _note   = TextEditingController(text: widget.entry.note);
    _status = widget.entry.status;
  }
  @override void dispose() { _qty.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<EntryController>();
    final ok   = await ctrl.update(widget.entry.entryId, {'quantity': double.parse(_qty.text), 'status': _status, 'note': _note.text.trim()});
    if (!mounted) return;
    if (ok) { AppHelpers.showSnack(context, 'Entry updated'); Navigator.pop(context); }
    else AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EntryController>();
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Edit Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        AppTextField(label: 'Quantity (Litres)', controller: _qty, validator: Validators.positiveNumber,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.local_drink_outlined, color: AppColors.grayText)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [0.5, 1.0, 1.5, 2.0].map((q) => ActionChip(
          label: Text('${q}L'), onPressed: () => setState(() => _qty.text = q.toString()),
          backgroundColor: AppColors.primarySubtle, labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12), padding: EdgeInsets.zero,
        )).toList()),
        const SizedBox(height: 14),
        Row(children: ['delivered', 'skipped', 'vacation'].map((s) {
          final sel = _status == s;
          final color = s == 'delivered' ? AppColors.success : s == 'skipped' ? AppColors.error : AppColors.warning;
          return Expanded(child: Padding(padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(onTap: () => setState(() => _status = s),
              child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: sel ? color.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? color : AppColors.divider, width: sel ? 2 : 1)),
                child: Text(s[0].toUpperCase() + s.substring(1), textAlign: TextAlign.center,
                    style: TextStyle(color: sel ? color : AppColors.grayText, fontWeight: sel ? FontWeight.w700 : FontWeight.normal, fontSize: 12)),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 14),
        AppTextField(label: 'Note (optional)', controller: _note,
            prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.grayText)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: ctrl.isLoading ? null : _save, child: const Text('Save Changes')),
      ])),
    );
  }
}
