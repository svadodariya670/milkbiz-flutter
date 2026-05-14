import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/controllers.dart';
//import '../utils/app_theme.dart';
import 'milkman/milkman_dashboard.dart';
import 'milkman/milkman_customers.dart';
import 'milkman/milkman_bills.dart';
import 'milkman/milkman_profile.dart';

class MilkmanShell extends StatefulWidget {
  const MilkmanShell({super.key});
  @override State<MilkmanShell> createState() => _MilkmanShellState();
}

class _MilkmanShellState extends State<MilkmanShell> {
  int _tab = 0;

  static const _tabs = [
    MilkmanDashboardTab(),
    MilkmanCustomersTab(),
    MilkmanEntriesTab(),
    MilkmanBillsTab(),
    MilkmanProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    await Future.wait([
      context.read<CustomerController>().load(uid),
      context.read<MilkTypeController>().load(uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded),      label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded),          label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_calendar_rounded),   label: 'Entries'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded),    label: 'Bills'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded),          label: 'Profile'),
        ],
      ),
    );
  }
}
