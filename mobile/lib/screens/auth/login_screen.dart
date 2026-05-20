import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';

// ─────────────────────────────────────────────
//  PinjamIN Theme Colors (match website)
// ─────────────────────────────────────────────
const _kBlue = Color(0xFF3B82F6);
const _kBlueDark = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF93C5FD);
const _kBorder = Color(0xFF3B82F6);

// ─────────────────────────────────────────────
//  AUTH SCREEN (Login + Register with wave animation)
// ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────
  bool _isSignIn = true;

  // ── Animation ──────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _waveProgress;
  late final Animation<double> _headerHeight;
  late final Animation<double> _avatarOpacity;
  late final Animation<double> _avatarScale;

  // ── Form controllers ───────────────────────
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regNim = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirmPass = TextEditingController();

  bool _siPassVisible = false;
  bool _suPassVisible = false;
  bool _confirmPassVisible = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _waveProgress = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );

    _headerHeight = Tween<double>(begin: 320.0, end: 220.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );

    _avatarOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
    _avatarScale = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regNim.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _regConfirmPass.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isSignIn = !_isSignIn);
    if (!_isSignIn) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  // ── Snackbar Helper ───────────────────────
  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppConst.error : AppConst.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Auth Actions ──────────────────────────
  Future<void> _doLogin() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) {
      _snack('Email dan password wajib diisi.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.login(_loginEmail.text.trim(), _loginPass.text);
    if (err != null) {
      _snack(err);
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _doRegister() async {
    if (_regNim.text.isEmpty || _regName.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) {
      _snack('Semua field wajib diisi.');
      return;
    }
    if (_regPass.text != _regConfirmPass.text) {
      _snack('Password dan konfirmasi password tidak sama.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      _regNim.text.trim(),
      _regName.text.trim(),
      _regEmail.text.trim(),
      _regPass.text,
    );
    if (err != null) {
      _snack(err);
    } else {
      _snack('Registrasi berhasil! Silakan login.', error: false);
      _toggle(); // Switch back to Sign In
    }
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── ANIMATED BLUE HEADER ───────
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return SizedBox(
                  height: _headerHeight.value + topPad,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient + morphing wave
                      ClipPath(
                        clipper: _WaveClipper(_waveProgress.value),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_kBlueLight, _kBlue, _kBlueDark],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Subtle inner highlight
                      ClipPath(
                        clipper: _WaveClipper(_waveProgress.value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),

                      // Avatar (Sign-In only)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _avatarOpacity.value,
                          child: Transform.scale(
                            scale: _avatarScale.value,
                            child: Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── FORM BODY ──────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    // child.key == 'signIn' berarti form login
                    final isSignInForm = child.key == const ValueKey('signIn');
                    
                    final offsetAnimation = Tween<Offset>(
                      begin: isSignInForm ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _isSignIn
                      ? _SignInForm(
                          key: const ValueKey('signIn'),
                          emailCtrl: _loginEmail,
                          passCtrl: _loginPass,
                          passVisible: _siPassVisible,
                          loading: auth.loading,
                          onTogglePass: () =>
                              setState(() => _siPassVisible = !_siPassVisible),
                          onToggle: _toggle,
                          onSubmit: _doLogin,
                        )
                      : _SignUpForm(
                          key: const ValueKey('signUp'),
                          nimCtrl: _regNim,
                          nameCtrl: _regName,
                          emailCtrl: _regEmail,
                          passCtrl: _regPass,
                          confirmPassCtrl: _regConfirmPass,
                          passVisible: _suPassVisible,
                          confirmPassVisible: _confirmPassVisible,
                          loading: auth.loading,
                          onTogglePass: () =>
                              setState(() => _suPassVisible = !_suPassVisible),
                          onToggleConfirmPass: () => setState(
                              () => _confirmPassVisible = !_confirmPassVisible),
                          onToggle: _toggle,
                          onSubmit: _doRegister,
                        ),
            // (End of AnimatedSwitcher)
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED WAVE CLIPPER
// ─────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper(this.progress);
  final double progress;

  double _lerp(double a, double b) => a + (b - a) * progress;

  @override
  Path getClip(Size s) {
    final h = s.height;
    final w = s.width;
    final path = Path()..moveTo(0, 0);

    // Sign In (0.0): simple convex arc (simetris)
    // Sign Up (1.0): deep dip on left, rise on right (menarik ke bawah di kiri)
    
    final p1 = Offset(
      w * _lerp(0.20, 0.25),
      h * _lerp(0.95, 1.00),
    );
    final p2 = Offset(
      w * _lerp(0.40, 0.45),
      h * _lerp(1.00, 0.55),
    );
    final mid = Offset(
      w * 0.5,
      h * _lerp(1.00, 0.65),
    );

    final p3 = Offset(
      w * _lerp(0.60, 0.75),
      h * _lerp(1.00, 0.75),
    );
    final p4 = Offset(
      w * _lerp(0.80, 0.90),
      h * _lerp(0.95, 0.65),
    );

    path.lineTo(0, h * _lerp(0.85, 0.70));
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, mid.dx, mid.dy);
    path.cubicTo(p3.dx, p3.dy, p4.dx, p4.dy, w, h * _lerp(0.85, 0.60));
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggleVis,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggleVis;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppConst.textPrimary),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kBlue, fontSize: 14, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppConst.textSecondary)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _kBorder.withValues(alpha: 0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 2.0),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFFAAAAAA),
                  size: 20,
                ),
                onPressed: onToggleVis,
              )
            : null,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBlue.withValues(alpha: 0.6),
          elevation: 2,
          shadowColor: _kBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDDDDD), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Atau',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDDDDD), thickness: 1)),
      ],
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText({
    required this.text,
    required this.linkText,
    required this.onTap,
  });
  final String text;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: const TextStyle(
              color: _kBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SIGN IN FORM
// ─────────────────────────────────────────────
class _SignInForm extends StatelessWidget {
  const _SignInForm({
    super.key,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passVisible,
    required this.loading,
    required this.onTogglePass,
    required this.onToggle,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool passVisible;
  final bool loading;
  final VoidCallback onTogglePass;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),

          // Title
          const Text(
            'Sign In',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk ke akun PinjamIN Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppConst.textSecondary),
          ),

          const SizedBox(height: 28),

          // Email
          _AuthTextField(
            controller: emailCtrl,
            hint: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          // Password
          _AuthTextField(
            controller: passCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            isVisible: passVisible,
            onToggleVis: onTogglePass,
          ),

          const SizedBox(height: 24),

          _PrimaryButton(
            label: 'Sign In',
            onPressed: onSubmit,
            loading: loading,
          ),

          const SizedBox(height: 22),

          const _OrDivider(),

          const SizedBox(height: 18),

          // Info badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _kBlue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gunakan akun yang sudah terdaftar di sistem PinjamIN.',
                    style: TextStyle(fontSize: 12, color: AppConst.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _FooterText(
            text: 'Belum punya akun? ',
            linkText: 'Daftar',
            onTap: onToggle,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SIGN UP FORM
// ─────────────────────────────────────────────
class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    super.key,
    required this.nimCtrl,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
    required this.passVisible,
    required this.confirmPassVisible,
    required this.loading,
    required this.onTogglePass,
    required this.onToggleConfirmPass,
    required this.onToggle,
    required this.onSubmit,
  });

  final TextEditingController nimCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final bool passVisible;
  final bool confirmPassVisible;
  final bool loading;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirmPass;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Title
          const Text(
            'Daftar Akun',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buat akun baru untuk menggunakan PinjamIN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppConst.textSecondary),
          ),

          const SizedBox(height: 24),

          // NIM
          _AuthTextField(
            controller: nimCtrl,
            hint: 'NIM',
            prefixIcon: Icons.badge_outlined,
          ),

          const SizedBox(height: 12),

          // Nama
          _AuthTextField(
            controller: nameCtrl,
            hint: 'Nama Lengkap',
            prefixIcon: Icons.person_outline,
          ),

          const SizedBox(height: 12),

          // Email
          _AuthTextField(
            controller: emailCtrl,
            hint: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          // Password
          _AuthTextField(
            controller: passCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            isVisible: passVisible,
            onToggleVis: onTogglePass,
          ),

          const SizedBox(height: 12),

          // Confirm Password
          _AuthTextField(
            controller: confirmPassCtrl,
            hint: 'Konfirmasi Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            isVisible: confirmPassVisible,
            onToggleVis: onToggleConfirmPass,
          ),

          const SizedBox(height: 24),

          _PrimaryButton(
            label: 'Daftar',
            onPressed: onSubmit,
            loading: loading,
          ),

          const SizedBox(height: 24),

          _FooterText(
            text: 'Sudah punya akun? ',
            linkText: 'Masuk',
            onTap: onToggle,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
