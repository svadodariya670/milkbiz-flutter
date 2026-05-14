import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../models/customer_model.dart';
import '../../models/milk_type_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMERS TAB
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanCustomersTab extends StatefulWidget {
  const MilkmanCustomersTab({super.key});
  @override
  State<MilkmanCustomersTab> createState() => _MilkmanCustomersTabState();
}

class _MilkmanCustomersTabState extends State<MilkmanCustomersTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load customers when tab first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().user?.uid ?? '';
      print('CustomersTab initState uid: $uid');
      if (uid.isNotEmpty) {
        context.read<CustomerController>().load(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid ?? '';
    final ctrl = context.watch<CustomerController>();

    // Filter by search query
    final filtered = ctrl.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.customerId.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.addCustomer).then((_) {
              // Reload after coming back from add screen
              context.read<CustomerController>().load(uid);
            }),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, ID or phone...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.grayText,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.grayText,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // ── Count chips ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CountChip(
                  label: '${ctrl.total} total',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _CountChip(
                  label: '${ctrl.active} active',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: ctrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filtered.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: _searchQuery.isNotEmpty
                        ? 'No results found'
                        : 'No Customers Yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different search'
                        : 'Tap + to add your first customer',
                    btnLabel: _searchQuery.isEmpty ? 'Add Customer' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.addCustomer,
                          )
                        : null,
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => ctrl.load(uid),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _CustomerCard(
                        customer: filtered[i],
                        onEdit: () => Navigator.pushNamed(
                          context,
                          AppRoutes.editCustomer,
                          arguments: {'docId': filtered[i].docId},
                        ).then((_) => ctrl.load(uid)),
                        onDelete: () async {
                          final confirmed = await AppHelpers.confirm(
                            context,
                            title: 'Delete Customer',
                            message:
                                'Delete ${filtered[i].name}? '
                                'This cannot be undone.',
                          );
                          if (confirmed && ctx.mounted) {
                            final ok = await ctrl.delete(filtered[i].docId);
                            if (ctx.mounted) {
                              AppHelpers.showSnack(
                                context,
                                ok ? 'Customer deleted' : ctrl.error ?? 'Error',
                                error: !ok,
                              );
                            }
                          }
                        },
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.customerDetail,
                          arguments: {'docId': filtered[i].docId},
                        ).then((_) => ctrl.load(uid)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Customer card widget ───────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Avatar — letter only, no image
            LetterAvatar(
              name: customer.name,
              radius: 24,
              bg: customer.isActive
                  ? AppColors.primarySubtle
                  : Colors.grey.shade100,
              fg: customer.isActive ? AppColors.primary : AppColors.lightGray,
            ),
            const SizedBox(width: 12),

            // Name, ID, phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    customer.customerId,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (customer.phone.isNotEmpty)
                    Text(
                      customer.phone,
                      style: const TextStyle(
                        color: AppColors.grayText,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Status + action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: customer.status),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Delete button
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small count chip ───────────────────────────────────────────────────────

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// ADD CUSTOMER SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});
  @override
  State<AddCustomerScreen> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomerScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _addr = TextEditingController();
  final _pass = TextEditingController();
  String _shift = 'morning';
  List<String> _selectedMilkTypeIds = [];
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().user?.uid ?? '';
      print('AddCustomer initState uid: $uid');
      if (uid.isNotEmpty) {
        context.read<MilkTypeController>().load(uid);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _addr, _pass]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedMilkTypeIds.isEmpty) {
      AppHelpers.showSnack(
        context,
        'Select at least one milk type',
        error: true,
      );
      return;
    }
    final auth = context.read<AuthController>();
    final ctrl = context.read<CustomerController>();
    final ok = await ctrl.add(
      milkman: auth.user!,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _addr.text.trim(),
      shift: _shift,
      milkTypeIds: _selectedMilkTypeIds,
      password: _pass.text,
    );
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(
        context,
        'Customer added! ID: ${ctrl.customers.last.customerId}',
      );
      Navigator.pop(context);
    } else {
      AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CustomerController>();
    final mtCtrl = context.watch<MilkTypeController>();
    final activeTypes = mtCtrl.activeTypes;

    print('Build: activeTypes count = ${activeTypes.length}');
    print('Build: isLoading = ${mtCtrl.isLoading}');
    print('Build: error = ${mtCtrl.error}');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Add Customer'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: ctrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A unique Customer ID will be auto-generated (e.g. CUST-001). Share it with your customer for login.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'Full Name',
                  hint: "Customer's full name",
                  controller: _name,
                  validator: (v) => Validators.required(v, field: 'Name'),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Phone (optional)',
                  hint: '10-digit number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Delivery Address',
                  hint: 'House no, Street, Area',
                  controller: _addr,
                  validator: (v) => Validators.required(v, field: 'Address'),
                  maxLines: 2,
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 18),

                // Shift selector
                const Text(
                  'Preferred Shift',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['morning', 'evening', 'both'].map((s) {
                    final sel = _shift == s;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _shift = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: sel ? Colors.white : AppColors.grayText,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Milk type multi-select (IMPORTANT feature)
                Row(
                  children: [
                    const Text(
                      'Milk Types',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Required',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select which milk types this customer buys',
                  style: TextStyle(color: AppColors.grayText, fontSize: 12),
                ),
                const SizedBox(height: 10),
                mtCtrl.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : activeTypes.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'No milk types found.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Go to Milk Types tab first and add at least one type, then come back here.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  // Reload button in case load failed silently
                                  GestureDetector(
                                    onTap: () {
                                      final uid =
                                          context
                                              .read<AuthController>()
                                              .user
                                              ?.uid ??
                                          '';
                                      context.read<MilkTypeController>().load(
                                        uid,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Retry Load',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: activeTypes.map((mt) {
                          final sel = _selectedMilkTypeIds.contains(
                            mt.milkTypeId,
                          );
                          return GestureDetector(
                            onTap: () => setState(() {
                              sel
                                  ? _selectedMilkTypeIds.remove(mt.milkTypeId)
                                  : _selectedMilkTypeIds.add(mt.milkTypeId);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primarySubtle
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: sel ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.water_drop_rounded,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.lightGray,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mt.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.darkGray,
                                          ),
                                        ),
                                        Text(
                                          '₹${mt.pricePerLitre} per litre',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sel
                                                ? AppColors.primary.withOpacity(
                                                    0.7,
                                                  )
                                                : AppColors.grayText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.divider,
                                        width: 2,
                                      ),
                                    ),
                                    child: sel
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 20),
                // Password
                AppTextField(
                  label: 'Login Password',
                  hint: 'Min 6 characters',
                  controller: _pass,
                  validator: Validators.password,
                  obscureText: _obscure,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.grayText,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grayText,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Share the Customer ID and this password with your customer for their login.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _save,
                  child: const Text('Add Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EDIT CUSTOMER SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({super.key});
  @override
  State<EditCustomerScreen> createState() => _EditCustomerState();
}

class _EditCustomerState extends State<EditCustomerScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _addr = TextEditingController();
  String _shift = 'morning';
  String _status = 'active';
  List<String> _selectedMilkTypeIds = [];
  bool _init = false;
  late String _docId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _docId = args['docId'] as String;
      final c = context.read<CustomerController>().getById(_docId);
      if (c != null) {
        _name.text = c.name;
        _phone.text = c.phone;
        _addr.text = c.address;
        _shift = c.preferredShift;
        _status = c.status;
        _selectedMilkTypeIds = List.from(c.milkTypeIds);
      }
      _init = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _addr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<CustomerController>();
    final ok = await ctrl.update(_docId, {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'address': _addr.text.trim(),
      'preferred_shift': _shift,
      'milk_type_ids': _selectedMilkTypeIds,
      'status': _status,
    });
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, 'Customer updated');
      Navigator.pop(context);
    } else
      AppHelpers.showSnack(context, ctrl.error ?? 'Update failed', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CustomerController>();
    final mtCtrl = context.watch<MilkTypeController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Edit Customer'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: ctrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Full Name',
                  controller: _name,
                  validator: (v) => Validators.required(v, field: 'Name'),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Phone (optional)',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Delivery Address',
                  controller: _addr,
                  maxLines: 2,
                  validator: (v) => Validators.required(v, field: 'Address'),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 18),
                _SegmentPicker(
                  label: 'Preferred Shift',
                  options: ['morning', 'evening', 'both'],
                  selected: _shift,
                  onChanged: (v) => setState(() => _shift = v),
                ),
                const SizedBox(height: 18),
                _SegmentPicker(
                  label: 'Status',
                  options: ['active', 'inactive', 'paused'],
                  selected: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Milk Types',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...mtCtrl.activeTypes.map((mt) {
                  final sel = _selectedMilkTypeIds.contains(mt.milkTypeId);
                  return GestureDetector(
                    onTap: () => setState(() {
                      sel
                          ? _selectedMilkTypeIds.remove(mt.milkTypeId)
                          : _selectedMilkTypeIds.add(mt.milkTypeId);
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primarySubtle : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: sel
                                ? AppColors.primary
                                : AppColors.lightGray,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mt.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.darkGray,
                              ),
                            ),
                          ),
                          Text(
                            '₹${mt.pricePerLitre}/L',
                            style: TextStyle(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.grayText,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            sel
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: sel ? AppColors.primary : AppColors.divider,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _save,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentPicker extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onChanged;
  const _SegmentPicker({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.grayText, fontSize: 13),
      ),
      const SizedBox(height: 8),
      Row(
        children: options.map((o) {
          final sel = selected == o;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    o[0].toUpperCase() + o.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.grayText,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOMER DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetailScreen> {
  List<BillModel> _bills = [];
  bool _loadingBills = true;
  late String _docId;
  CustomerModel? _customer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _docId = args['docId'] as String;
    setState(() {
      _customer = context.read<CustomerController>().getById(_docId);
      _loadingBills = true;
    });
    final bills = await context.read<BillController>().getBillsForCustomer(
      _docId,
    );
    if (mounted)
      setState(() {
        _bills = bills;
        _loadingBills = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final c = _customer;
    final mtCtrl = context.watch<MilkTypeController>();
    if (c == null)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

    final myTypes = c.milkTypeIds
        .map((id) => mtCtrl.getById(id))
        .whereType<MilkTypeModel>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(c.name),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.pushNamed(
                  context,
                  AppRoutes.editCustomer,
                  arguments: {'docId': c.docId},
                ).then((_) {
                  final uid = context.read<AuthController>().user?.uid ?? '';
                  context.read<CustomerController>().load(uid);
                  setState(() {
                    _customer = context.read<CustomerController>().getById(
                      _docId,
                    );
                  });
                }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  LetterAvatar(
                    name: c.name,
                    radius: 30,
                    bg: Colors.white.withOpacity(0.22),
                    fg: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          c.customerId,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (c.phone.isNotEmpty)
                          Text(
                            c.phone,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(status: c.status),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Info grid
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Shift',
                    value:
                        c.preferredShift[0].toUpperCase() +
                        c.preferredShift.substring(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Since',
                    value: AppHelpers.formatDate(c.startDate),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Area',
                    value: c.address.length > 12
                        ? '${c.address.substring(0, 12)}…'
                        : c.address,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Milk types
            if (myTypes.isNotEmpty) ...[
              const Text(
                'Milk Types',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: myTypes
                    .map(
                      (mt) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${mt.name}  ₹${mt.pricePerLitre}/L',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.addEntry,
                      arguments: {
                        'customerId': c.docId,
                        'customerName': c.name,
                      },
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Entry'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.paymentHistory,
                      arguments: {
                        'customerId': c.docId,
                        'customerName': c.name,
                      },
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Payments'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bills
            const Text(
              'Bills',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingBills)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (_bills.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Bills Yet',
                subtitle: 'Bills are auto-generated at end of month',
              )
            else
              ..._bills.map(
                (b) => GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.billDetail,
                    arguments: {'billId': b.billId},
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.billMonth,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Total: ${AppHelpers.formatCurrency(b.finalBalance)}',
                                style: const TextStyle(
                                  color: AppColors.grayText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: b.status),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.lightGray,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.grayText, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD / EDIT MILK TYPE SCREENS
// ══════════════════════════════════════════════════════════════════════════════

class AddMilkTypeScreen extends StatefulWidget {
  const AddMilkTypeScreen({super.key});
  @override
  State<AddMilkTypeScreen> createState() => _AddMilkTypeState();
}

class _AddMilkTypeState extends State<AddMilkTypeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = context.read<AuthController>().user!.uid;
    final ctrl = context.read<MilkTypeController>();
    final ok = await ctrl.add(
      uid,
      _name.text.trim(),
      double.parse(_price.text),
    );
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, 'Milk type added');
      Navigator.pop(context);
    } else
      AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MilkTypeController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Add Milk Type'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: ctrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              children: [
                AppTextField(
                  label: 'Milk Type Name',
                  hint: 'e.g. Cow, Buffalo, Mixed',
                  controller: _name,
                  validator: (v) => Validators.required(v, field: 'Name'),
                  prefixIcon: const Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Price per Litre (₹)',
                  hint: '0.00',
                  controller: _price,
                  validator: Validators.positiveNumber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grayText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Price changes only affect future bills. Existing bills are frozen.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _save,
                  child: const Text('Add Milk Type'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditMilkTypeScreen extends StatefulWidget {
  const EditMilkTypeScreen({super.key});
  @override
  State<EditMilkTypeScreen> createState() => _EditMilkTypeState();
}

class _EditMilkTypeState extends State<EditMilkTypeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  bool _init = false;
  late String _typeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _typeId = args['typeId'] as String;
      final mt = context.read<MilkTypeController>().getById(_typeId);
      if (mt != null) {
        _name.text = mt.name;
        _price.text = mt.pricePerLitre.toString();
      }
      _init = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = context.read<AuthController>().user!.uid;
    final ctrl = context.read<MilkTypeController>();
    final ok = await ctrl.update(_typeId, uid, {
      'name': _name.text.trim(),
      'price_per_litre': double.parse(_price.text),
    });
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(
        context,
        'Updated. New price applies to future bills only.',
      );
      Navigator.pop(context);
    } else
      AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MilkTypeController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Edit Milk Type'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: ctrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              children: [
                AppTextField(
                  label: 'Milk Type Name',
                  controller: _name,
                  validator: (v) => Validators.required(v, field: 'Name'),
                  prefixIcon: const Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Price per Litre (₹)',
                  controller: _price,
                  validator: Validators.positiveNumber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      '₹',
                      style: TextStyle(fontSize: 16, color: AppColors.grayText),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _save,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD / EDIT ENTRY SCREENS
// ══════════════════════════════════════════════════════════════════════════════

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});
  @override
  State<AddEntryScreen> createState() => _AddEntryState();
}

class _AddEntryState extends State<AddEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  CustomerModel? _cust;
  MilkTypeModel? _milkType;
  DateTime _date = DateTime.now();
  String _status = 'delivered';
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args?['customerId'] != null)
        _cust = context.read<CustomerController>().getById(
          args!['customerId'] as String,
        );
      _init = true;
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_cust == null) {
      AppHelpers.showSnack(context, 'Select a customer', error: true);
      return;
    }
    if (_milkType == null) {
      AppHelpers.showSnack(context, 'Select a milk type', error: true);
      return;
    }
    final auth = context.read<AuthController>();
    final ctrl = context.read<EntryController>();
    final ok = await ctrl.add(
      milkmanUid: auth.user!.uid,
      customerId: _cust!.docId,
      customerName: _cust!.name,
      milkTypeId: _milkType!.milkTypeId,
      milkTypeName: _milkType!.name,
      date: _date,
      quantity: double.parse(_qty.text),
      status: _status,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, 'Entry added');
      Navigator.pop(context);
    } else {
      AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
      ctrl.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eCtrl = context.watch<EntryController>();
    final cCtrl = context.watch<CustomerController>();
    final mtCtrl = context.watch<MilkTypeController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Add Entry'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: eCtrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                const Text(
                  'Delivery Date',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (p != null) setState(() => _date = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer dropdown — only show customers with matching milk types
                const Text(
                  'Customer',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<CustomerModel>(
                  value: _cust,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.grayText,
                    ),
                  ),
                  hint: const Text('Select customer'),
                  items: cCtrl.activeCustomers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              LetterAvatar(name: c.name, radius: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${c.name}  (${c.customerId})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _cust = v;
                    _milkType = null;
                  }),
                  validator: (v) => v == null ? 'Select a customer' : null,
                ),
                const SizedBox(height: 16),

                // Milk type (filtered by customer's assigned types)
                const Text(
                  'Milk Type',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<MilkTypeModel>(
                  value: _milkType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.grayText,
                    ),
                  ),
                  hint: const Text('Select milk type'),
                  items:
                      (_cust != null
                              ? mtCtrl.activeTypes
                                    .where(
                                      (mt) => _cust!.milkTypeIds.contains(
                                        mt.milkTypeId,
                                      ),
                                    )
                                    .toList()
                              : mtCtrl.activeTypes)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                '${m.name}  —  ₹${m.pricePerLitre}/L',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _milkType = v),
                  validator: (v) => v == null ? 'Select a milk type' : null,
                ),
                const SizedBox(height: 16),

                // Quantity
                AppTextField(
                  label: 'Quantity (Litres)',
                  controller: _qty,
                  validator: Validators.positiveNumber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Icon(
                    Icons.local_drink_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [0.5, 1.0, 1.5, 2.0, 2.5]
                      .map(
                        (q) => ActionChip(
                          label: Text('${q}L'),
                          onPressed: () =>
                              setState(() => _qty.text = q.toString()),
                          backgroundColor: AppColors.primarySubtle,
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Status
                const Text(
                  'Status',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['delivered', 'skipped', 'vacation'].map((s) {
                    final sel = _status == s;
                    final color = s == 'delivered'
                        ? AppColors.success
                        : s == 'skipped'
                        ? AppColors.error
                        : AppColors.warning;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _status = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel
                                  ? color.withOpacity(0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? color : AppColors.divider,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  s == 'delivered'
                                      ? Icons.check_circle_outline_rounded
                                      : s == 'skipped'
                                      ? Icons.cancel_outlined
                                      : Icons.beach_access_outlined,
                                  color: sel ? color : AppColors.lightGray,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s[0].toUpperCase() + s.substring(1),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: sel ? color : AppColors.grayText,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Note (optional)',
                  hint: 'e.g. Extra delivery, reduced quantity...',
                  controller: _note,
                  prefixIcon: const Icon(
                    Icons.notes_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: eCtrl.isLoading ? null : _save,
                  child: const Text('Save Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditEntryScreen extends StatefulWidget {
  const EditEntryScreen({super.key});
  @override
  State<EditEntryScreen> createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  String _status = 'delivered';
  bool _init = false;
  late String _entryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _entryId = args['entryId'] as String;
      _qty.text = (args['quantity'] as double).toString();
      _note.text = args['note'] as String? ?? '';
      _status = args['status'] as String? ?? 'delivered';
      _init = true;
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<EntryController>();
    final ok = await ctrl.update(_entryId, {
      'quantity': double.parse(_qty.text),
      'status': _status,
      'note': _note.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, 'Entry updated');
      Navigator.pop(context);
    } else
      AppHelpers.showSnack(context, ctrl.error ?? 'Failed', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EntryController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Edit Entry'), elevation: 0.5),
      body: LoadingOverlay(
        isLoading: ctrl.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              children: [
                AppTextField(
                  label: 'Quantity (Litres)',
                  controller: _qty,
                  validator: Validators.positiveNumber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Icon(
                    Icons.local_drink_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [0.5, 1.0, 1.5, 2.0]
                      .map(
                        (q) => ActionChip(
                          label: Text('${q}L'),
                          onPressed: () =>
                              setState(() => _qty.text = q.toString()),
                          backgroundColor: AppColors.primarySubtle,
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                _SegmentPicker(
                  label: 'Status',
                  options: ['delivered', 'skipped', 'vacation'],
                  selected: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Note (optional)',
                  controller: _note,
                  prefixIcon: const Icon(
                    Icons.notes_outlined,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _save,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
