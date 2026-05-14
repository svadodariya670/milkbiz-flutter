import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'controllers/controllers.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'services/bill_scheduler.dart';

// Auth screens
import 'views/auth/auth_screens.dart';

// Milkman shell + sub-screens
import 'views/milkman_shell.dart';
import 'views/milkman/milkman_customers.dart'; // Add/Edit customer, milk type, entry
import 'views/milkman/milkman_bills.dart'; // BillDetail, AddPayment, MilkTypes
import 'views/milkman/milkman_profile.dart'; // EditProfile, Subscription, Summary, PaymentHistory

// Customer shell + sub-screens
import 'views/customer_shell.dart'; // CustomerShell, CustomerBillViewScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //BillScheduler.start();
  runApp(const MilkbizApp());
}

class MilkbizApp extends StatefulWidget {
  const MilkbizApp({super.key});

  @override
  State<MilkbizApp> createState() => _MilkbizAppState();
}

class _MilkbizAppState extends State<MilkbizApp> {
  @override
  void initState() {
    super.initState();

    // 🔥 Run AFTER UI loads
    Future.delayed(Duration.zero, () {
      BillScheduler.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CustomerController()),
        ChangeNotifierProvider(create: (_) => MilkTypeController()),
        ChangeNotifierProvider(create: (_) => EntryController()),
        ChangeNotifierProvider(create: (_) => BillController()),
      ],
      child: MaterialApp(
        title: 'milkbiz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
          AppRoutes.milkmanLogin: (_) => const MilkmanLoginScreen(),
          AppRoutes.milkmanRegister: (_) => const MilkmanRegisterScreen(),
          AppRoutes.milkmanBusinessSetup: (_) =>
              const MilkmanBusinessSetupScreen(),
          AppRoutes.customerLogin: (_) => const CustomerLoginScreen(),

          AppRoutes.milkmanShell: (_) => const MilkmanShell(),

          AppRoutes.addCustomer: (_) => const AddCustomerScreen(),
          AppRoutes.editCustomer: (_) => const EditCustomerScreen(),
          AppRoutes.customerDetail: (_) => const CustomerDetailScreen(),
          AppRoutes.addMilkType: (_) => const AddMilkTypeScreen(),
          AppRoutes.editMilkType: (_) => const EditMilkTypeScreen(),
          AppRoutes.addEntry: (_) => const AddEntryScreen(),
          AppRoutes.editEntry: (_) => const EditEntryScreen(),
          AppRoutes.billDetail: (_) => const BillDetailScreen(),
          AppRoutes.addPayment: (_) => const AddPaymentScreen(),
          AppRoutes.paymentHistory: (_) => const PaymentHistoryScreen(),
          AppRoutes.monthlySummary: (_) => const MonthlySummaryScreen(),
          AppRoutes.subscription: (_) => const SubscriptionScreen(),

          AppRoutes.customerShell: (_) => const CustomerShell(),
          AppRoutes.customerBillView: (_) => const CustomerBillViewScreen(),
        },
      ),
    );
  }
}
