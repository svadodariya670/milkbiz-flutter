import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/controllers.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      final auth = context.read<AuthController>();

      // 🔥 Add timeout safety
      await auth.checkSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("checkSession timeout");
          return;
        },
      );

      if (!mounted) return;

      if (auth.role == 'milkman' && auth.user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.milkmanShell);
      } else if (auth.role == 'customer' && auth.sessionUid != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.customerShell,
          arguments: {'docId': auth.sessionUid},
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } catch (e) {
      print("Splash ERROR: $e");

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: FadeTransition(
      opacity: _fade,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'milkbiz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Smart Milk Delivery',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 64),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ROLE SELECTION
// ══════════════════════════════════════════════════════════════════════════════

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          children: [
            const Spacer(),
            // Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'milkbiz',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart Milk Delivery Management',
              style: TextStyle(color: AppColors.grayText, fontSize: 14),
            ),
            const SizedBox(height: 56),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 24),
            _RoleBtn(
              label: 'I am a MILKMAN',
              sub: 'Business Owner — Manage deliveries',
              icon: Icons.local_shipping_rounded,
              filled: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.milkmanLogin),
            ),
            const SizedBox(height: 14),
            _RoleBtn(
              label: 'I am a CUSTOMER',
              sub: 'View bills & payment history',
              icon: Icons.person_rounded,
              filled: false,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.customerLogin),
            ),
            const Spacer(),
            Text(
              'Version ${AppConstants.version}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoleBtn extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _RoleBtn({
    required this.label,
    required this.sub,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(50),
        border: filled ? null : Border.all(color: AppColors.primary, width: 2),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white.withOpacity(0.20)
                  : AppColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: filled
                        ? Colors.white.withOpacity(0.78)
                        : AppColors.grayText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: filled ? Colors.white : AppColors.primary,
            size: 15,
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// MILKMAN LOGIN  (email + Google)
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanLoginScreen extends StatefulWidget {
  const MilkmanLoginScreen({super.key});
  @override
  State<MilkmanLoginScreen> createState() => _MilkmanLoginState();
}

class _MilkmanLoginState extends State<MilkmanLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.loginMilkman(_emailCtl.text.trim(), _passCtl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.milkmanShell);
    } else {
      AppHelpers.showSnack(context, auth.error ?? 'Login failed', error: true);
    }
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthController>();
    final done = await auth.startGoogleSignIn();
    if (!mounted) return;
    if (done) {
      // Has existing profile → go to dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.milkmanShell);
    } else if (auth.error != null) {
      AppHelpers.showSnack(context, auth.error!, error: true);
    } else {
      // No profile yet → Step 2
      Navigator.pushNamed(context, AppRoutes.milkmanBusinessSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BackBtn(),
                const SizedBox(height: 18),
                _AuthHero(
                  icon: Icons.local_shipping_rounded,
                  title: 'Milkman Login',
                  subtitle: 'Sign in to manage your dairy business',
                ),
                const SizedBox(height: 32),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailCtl,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Password',
                        controller: _passCtl,
                        validator: Validators.password,
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.grayText,
                        ),
                        suffixIcon: _EyeBtn(
                          obscure: _obscure,
                          onTap: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                _OrDivider(),
                const SizedBox(height: 16),
                _GoogleBtn(onTap: auth.isLoading ? null : _googleLogin),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.milkmanRegister,
                    ),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an account?  ",
                            style: TextStyle(color: AppColors.grayText),
                          ),
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
// MILKMAN REGISTER — STEP 1  (credentials only)
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanRegisterScreen extends StatefulWidget {
  const MilkmanRegisterScreen({super.key});
  @override
  State<MilkmanRegisterScreen> createState() => _MilkmanRegisterState();
}

class _MilkmanRegisterState extends State<MilkmanRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureC = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate()) return;
    if (_pass.text != _confirm.text) {
      AppHelpers.showSnack(context, 'Passwords do not match', error: true);
      return;
    }
    final auth = context.read<AuthController>();
    final ok = await auth.startEmailRegister(_email.text.trim(), _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, AppRoutes.milkmanBusinessSetup);
    } else {
      AppHelpers.showSnack(
        context,
        auth.error ?? 'Registration failed',
        error: true,
      );
    }
  }

  Future<void> _googleRegister() async {
    final auth = context.read<AuthController>();
    final done = await auth.startGoogleSignIn();
    if (!mounted) return;
    if (done) {
      Navigator.pushReplacementNamed(context, AppRoutes.milkmanShell);
    } else if (auth.error != null) {
      AppHelpers.showSnack(context, auth.error!, error: true);
    } else {
      Navigator.pushNamed(context, AppRoutes.milkmanBusinessSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BackBtn(),
                const SizedBox(height: 14),
                _StepBadge(step: 1, total: 2, label: 'Account Credentials'),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Text(
                  'Set up your login credentials',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _email,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Password',
                        controller: _pass,
                        validator: Validators.password,
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.grayText,
                        ),
                        suffixIcon: _EyeBtn(
                          obscure: _obscure,
                          onTap: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Confirm Password',
                        controller: _confirm,
                        validator: (v) =>
                            Validators.required(v, field: 'Confirm password'),
                        obscureText: _obscureC,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.grayText,
                        ),
                        suffixIcon: _EyeBtn(
                          obscure: _obscureC,
                          onTap: () => setState(() => _obscureC = !_obscureC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _next,
                  child: const Text('Continue to Business Details →'),
                ),
                const SizedBox(height: 16),
                _OrDivider(),
                const SizedBox(height: 16),
                _GoogleBtn(
                  label: 'Sign up with Google',
                  onTap: auth.isLoading ? null : _googleRegister,
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.milkmanLogin,
                    ),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account?  ',
                            style: TextStyle(color: AppColors.grayText),
                          ),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
// MILKMAN BUSINESS SETUP — STEP 2  (MANDATORY for ALL — email & Google)
// ══════════════════════════════════════════════════════════════════════════════

class MilkmanBusinessSetupScreen extends StatefulWidget {
  const MilkmanBusinessSetupScreen({super.key});
  @override
  State<MilkmanBusinessSetupScreen> createState() => _BusinessSetupState();
}

class _BusinessSetupState extends State<MilkmanBusinessSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _owner = TextEditingController();
  final _biz = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill owner name from Google display name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.pendingName != null && auth.pendingName!.isNotEmpty) {
        _owner.text = auth.pendingName!;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_owner, _biz, _phone, _address, _area]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.completeBusinessProfile(
      ownerName: _owner.text.trim(),
      businessName: _biz.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      area: _area.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      AppHelpers.showSnack(context, '🎉 Welcome! 30-day free trial started.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.milkmanShell,
        (r) => false,
      );
    } else {
      AppHelpers.showSnack(context, auth.error ?? 'Setup failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    // Show the verified email (read-only) so user knows which account
    final email = auth.pendingEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No back button — Step 2 is mandatory
                const SizedBox(height: 4),
                _StepBadge(step: 2, total: 2, label: 'Business Details'),
                const SizedBox(height: 20),
                const Text(
                  'Your Dairy Details',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Text(
                  'Tell us about your dairy business',
                  style: TextStyle(color: AppColors.grayText, fontSize: 13),
                ),
                const SizedBox(height: 6),

                // Show which email is being used (fetched from auth, not editable)
                if (email.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Email (verified)',
                                style: TextStyle(
                                  color: AppColors.grayText,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Owner / Your Name',
                        hint: 'Your full name',
                        controller: _owner,
                        validator: (v) =>
                            Validators.required(v, field: 'Owner name'),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Dairy / Business Name',
                        hint: 'e.g. Raj Dairy, Patel Milk Centre',
                        controller: _biz,
                        validator: (v) =>
                            Validators.required(v, field: 'Business name'),
                        prefixIcon: const Icon(
                          Icons.store_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Phone Number',
                        hint: '10-digit mobile number',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            Validators.required(v, field: 'Phone number'),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Business Address',
                        hint: 'Street, Area, City',
                        controller: _address,
                        maxLines: 2,
                        validator: (v) =>
                            Validators.required(v, field: 'Address'),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Service Area',
                        hint: 'e.g. Rajkot North, Kalawad Road',
                        controller: _area,
                        validator: (v) =>
                            Validators.required(v, field: 'Service area'),
                        prefixIcon: const Icon(
                          Icons.map_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Trial info banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              AppColors.primarySubtle,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '30-Day Free Trial',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Up to 10 customers · No payment required',
                                    style: TextStyle(
                                      color: AppColors.grayText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Complete Setup & Start Free Trial',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
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
// CUSTOMER LOGIN
// ══════════════════════════════════════════════════════════════════════════════

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});
  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final result = await auth.loginCustomer(_id.text.trim(), _pass.text);
    if (!mounted) return;
    if (result != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.customerShell,
        arguments: result,
      );
    } else {
      AppHelpers.showSnack(context, auth.error ?? 'Login failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BackBtn(),
                const SizedBox(height: 18),
                _AuthHero(
                  icon: Icons.person_rounded,
                  title: 'Customer Login',
                  subtitle: 'Use your unique Customer ID given by your milkman',
                ),
                const SizedBox(height: 32),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Customer ID',
                        hint: 'e.g.  CUST-001',
                        controller: _id,
                        validator: Validators.customerId,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your Customer ID (CUST-001) was assigned by your milkman when they added you. Ask them if you are unsure.',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Password',
                        controller: _pass,
                        validator: (v) =>
                            Validators.required(v, field: 'Password'),
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.grayText,
                        ),
                        suffixIcon: _EyeBtn(
                          obscure: _obscure,
                          onTap: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  child: const Text('Sign In'),
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
// SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _AuthHero extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _AuthHero({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 13),
        ),
      ],
    ),
  );
}

class _StepBadge extends StatelessWidget {
  final int step, total;
  final String label;
  const _StepBadge({
    required this.step,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ...List.generate(
        total,
        (i) => Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < step ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Step $step / $total  ·  $label',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _BackBtn extends StatelessWidget {
  const _BackBtn();
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.arrow_back_rounded,
        color: AppColors.darkGray,
        size: 22,
      ),
    ),
  );
}

class _EyeBtn extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeBtn({required this.obscure, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: AppColors.lightGray,
      size: 20,
    ),
    onPressed: onTap,
  );
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'OR',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const _GoogleBtn({this.onTap, this.label = 'Continue with Google'});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" logo using colored text
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Text(
              'G',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkGray,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
