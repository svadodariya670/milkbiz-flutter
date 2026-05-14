import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/milk_type_controller.dart';
import '../../models/customer_model.dart';
import '../../models/customer_milk_map_model.dart';
import '../../models/milk_type_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customer =
        ModalRoute.of(context)!.settings.arguments as CustomerModel;
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/edit-customer',
                  arguments: customer,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(
                        alpha: (0.3 * 255).toDouble(),
                      ),
                      child: Text(
                        AppHelpers.initials(customer.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(status: customer.status),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: customer.phone,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.home_outlined,
                            label: 'Address',
                            value: customer.address,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Shift',
                            value:
                                customer.preferredShift[0].toUpperCase() +
                                customer.preferredShift.substring(1),
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Since',
                            value: AppHelpers.formatDate(customer.startDate),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Milk Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddMilkMapDialog(
                          context,
                          customer,
                          auth.user!.uid,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<CustomerMilkMapModel>>(
                    stream: context
                        .read<CustomerController>()
                        .streamCustomerMilkMap(customer.customerId),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No milk preferences set',
                              style: TextStyle(color: AppColors.grey),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: snap.data!
                            .map(
                              (m) => _MilkMapTile(
                                map: m,
                                milkmanUid: auth.user!.uid,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/generate-bill',
                      arguments: customer,
                    ),
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Generate Bill',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMilkMapDialog(
    BuildContext context,
    CustomerModel customer,
    String milkmanUid,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _AddMilkMapSheet(customer: customer, milkmanUid: milkmanUid),
    );
  }
}

class _AddMilkMapSheet extends StatefulWidget {
  final CustomerModel customer;
  final String milkmanUid;
  const _AddMilkMapSheet({required this.customer, required this.milkmanUid});

  @override
  State<_AddMilkMapSheet> createState() => _AddMilkMapSheetState();
}

class _AddMilkMapSheetState extends State<_AddMilkMapSheet> {
  String? _selectedMilkTypeId;
  final _qtyCtrl = TextEditingController(text: '1');
  final _customPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _customPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Milk Preference',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<MilkTypeModel>>(
            stream: context.read<MilkTypeController>().streamMilkTypes(
              widget.milkmanUid,
            ),
            builder: (ctx, snap) {
              final types = snap.data?.where((m) => m.isActive).toList() ?? [];
              return DropdownButtonFormField<String>(
                value: _selectedMilkTypeId,
                hint: const Text('Select Milk Type'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: types
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.milkTypeId,
                        child: Text('${m.name} - ₹${m.pricePerLitre}/L'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedMilkTypeId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Default Quantity (L/day)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Custom Price (optional)',
              hintText: 'Leave empty to use standard price',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_selectedMilkTypeId == null) return;
              final map = CustomerMilkMapModel(
                id: '',
                customerId: widget.customer.customerId,
                milkTypeId: _selectedMilkTypeId!,
                defaultQuantity: double.tryParse(_qtyCtrl.text) ?? 1,
                customPrice: _customPriceCtrl.text.isNotEmpty
                    ? double.tryParse(_customPriceCtrl.text)
                    : null,
              );
              await context.read<CustomerController>().addCustomerMilkMap(map);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ADD PREFERENCE'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MilkMapTile extends StatelessWidget {
  final CustomerMilkMapModel map;
  final String milkmanUid;
  const _MilkMapTile({required this.map, required this.milkmanUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MilkTypeModel>>(
      stream: context.read<MilkTypeController>().streamMilkTypes(milkmanUid),
      builder: (ctx, snap) {
        final milkType = snap.data?.firstWhere(
          (m) => m.milkTypeId == map.milkTypeId,
          orElse: () => MilkTypeModel(
            milkTypeId: '',
            milkmanUid: '',
            name: 'Unknown',
            pricePerLitre: 0,
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              milkType?.name ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${map.defaultQuantity}L/day · ₹${map.customPrice ?? milkType?.pricePerLitre ?? 0}/L',
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await context.read<CustomerController>().deleteCustomerMilkMap(
                  map.id,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
