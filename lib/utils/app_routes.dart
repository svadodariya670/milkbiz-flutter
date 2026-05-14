class AppRoutes {
  // Auth
  static const splash                = '/';
  static const roleSelection         = '/role';
  static const milkmanLogin          = '/milkman/login';
  static const milkmanRegister       = '/milkman/register';
  static const milkmanBusinessSetup  = '/milkman/setup'; // Step 2 — MANDATORY
  static const customerLogin         = '/customer/login';

  // Milkman shell (bottom nav)
  static const milkmanShell          = '/milkman';

  // Milkman sub-pages
  static const addCustomer           = '/milkman/customers/add';
  static const editCustomer          = '/milkman/customers/edit';
  static const customerDetail        = '/milkman/customers/detail';
  static const addMilkType           = '/milkman/milk-types/add';
  static const editMilkType          = '/milkman/milk-types/edit';
  static const addEntry              = '/milkman/entries/add';
  static const editEntry             = '/milkman/entries/edit';
  static const billDetail            = '/milkman/bills/detail';
  static const addPayment            = '/milkman/bills/payment';
  static const paymentHistory        = '/milkman/payments';
  static const monthlySummary        = '/milkman/summary';
  static const subscription          = '/milkman/subscription';

  // Customer shell (bottom nav)
  static const customerShell         = '/customer';

  // Customer sub-pages
  static const customerBillView      = '/customer/bills/detail';
  static const customerPayHistory    = '/customer/payments';
}

class AppConstants {
  static const appName  = 'milkbiz';
  static const version  = '2.0.0';
  static const trialDays = 30;

  static const plans = {
    'free':     {'name': 'Free Trial',  'price': 0,   'maxCustomers': 10,  'days': 30},
    'basic':    {'name': 'Basic',       'price': 199,  'maxCustomers': 50,  'days': 30},
    'standard': {'name': 'Standard',   'price': 499,  'maxCustomers': 100, 'days': 30},
    'premium':  {'name': 'Premium',    'price': 799,  'maxCustomers': -1,  'days': 30},
  };
}
