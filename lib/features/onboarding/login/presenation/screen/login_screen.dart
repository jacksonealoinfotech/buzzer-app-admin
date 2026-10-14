import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data handed to [LoginScreen.onLogin].
class LoginData {
  const LoginData({
    required this.email,
    required this.password,
    required this.code,
    required this.isBackupCode,
    required this.rememberDevice,
  });

  final String email;
  final String password;

  /// 6-digit authenticator code, or the backup code when [isBackupCode].
  final String code;
  final bool isBackupCode;
  final bool rememberDevice;
}

/// Throw this from [LoginScreen.onLogin] to show a friendly error message.
class LoginException implements Exception {
  const LoginException(this.message);
  final String message;
}

typedef LoginCallback = Future<void> Function(LoginData data);

enum _ButtonState { idle, loading, success }

/// Buzzer Super Admin login.
///
/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLogin,
    this.onSuccess,
    this.onForgotPassword,
    this.onContactSupport,
  });

  /// Call your API here. Throw [LoginException] to show an error.
  /// If null, a 1.8s fake delay is used (handy while building UI).
  final LoginCallback? onLogin;

  /// Called after the success animation (navigate to dashboard here).
  final VoidCallback? onSuccess;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onContactSupport;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const int _stepCount = 7;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _backupCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _backupFocus = FocusNode();

  late final AnimationController _enter;
  late final AnimationController _ambient;
  late final AnimationController _shake;
  late final List<Animation<double>> _steps;

  bool _obscure = true;
  bool _remember = true;
  bool _useBackup = false;
  bool _codeError = false;
  bool _autoValidate = false;
  bool _pressed = false;
  String? _error;
  _ButtonState _status = _ButtonState.idle;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _steps = List.generate(_stepCount, (i) {
      final start = i * 0.09;
      final end = math.min(start + 0.45, 1.0);
      return CurvedAnimation(
        parent: _enter,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    _shake.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _backupCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _otpFocus.dispose();
    _backupFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- logic

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your admin email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 6) return 'Password is too short';
    return null;
  }

  bool get _codeValid => _useBackup
      ? _backupCtrl.text.trim().length >= 6
      : _otpCtrl.text.length == 6;

  Future<void> _submit() async {
    if (_status != _ButtonState.idle) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _autoValidate = true;
      _error = null;
    });

    final formOk = _formKey.currentState?.validate() ?? false;
    final codeOk = _codeValid;
    setState(() => _codeError = !codeOk);

    if (!formOk || !codeOk) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      return;
    }

    setState(() => _status = _ButtonState.loading);
    try {
      final data = LoginData(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        code: _useBackup ? _backupCtrl.text.trim() : _otpCtrl.text,
        isBackupCode: _useBackup,
        rememberDevice: _remember,
      );

      if (widget.onLogin != null) {
        await widget.onLogin!(data);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 1800));
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _status = _ButtonState.success);
      TextInput.finishAutofillContext();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      widget.onSuccess?.call();
    } on LoginException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _status = _ButtonState.idle;
      _error = message;
      _codeError = true;
    });
    _shake.forward(from: 0);
  }

  void _toggleBackup() {
    setState(() {
      _useBackup = !_useBackup;
      _codeError = false;
      _otpCtrl.clear();
      _backupCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (_useBackup ? _backupFocus : _otpFocus).requestFocus();
    });
  }

  // ---------------------------------------------------------------- build

  Widget _reveal(int index, Widget child) {
    final anim = _steps[index];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _AmbientBackground(animation: _ambient),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) {
                        final t = _shake.value;
                        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: _buildContent(context, cs),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    final text = Theme.of(context).textTheme;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Brand header
            _reveal(
              0,
              Row(
                children: [
                  _BrandLogo(animation: _ambient),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buzzer',
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Super Admin',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _reveal(
              1,
              Text(
                'Secure access for platform administrators',
                style: text.bodyMedium?.copyWith(color: muted),
              ),
            ),
            const SizedBox(height: 28),

            // ---- Email
            _reveal(
              2,
              TextFormField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _decoration(
                  cs,
                  label: 'Email address',
                  icon: Icons.mail_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---- Password
            _reveal(
              3,
              TextFormField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
                onFieldSubmitted: (_) {
                  if (_useBackup) {
                    _backupFocus.requestFocus();
                  } else {
                    _otpFocus.requestFocus();
                  }
                },
                decoration: _decoration(
                  cs,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_obscure),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _reveal(
                3,
                TextButton(
                  onPressed: widget.onForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ---- Two-factor card
            _reveal(4, _buildTwoFactorCard(context, cs)),
            const SizedBox(height: 16),

            // ---- Error banner
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        key: ValueKey(_error),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ErrorBanner(message: _error!),
                      ),
              ),
            ),

            // ---- Sign in
            _reveal(5, _buildSignInButton(context, cs)),
            const SizedBox(height: 20),

            // ---- Support
            _reveal(
              6,
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Need help?',
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                    TextButton(
                      onPressed: widget.onContactSupport,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Contact support'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorCard(BuildContext context, ColorScheme cs) {
    final text = Theme.of(context).textTheme;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _codeError ? cs.error : cs.outlineVariant,
          width: _codeError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Two-Factor Authentication',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _useBackup
                  ? 'Enter one of your saved backup codes.'
                  : 'Enter the 6-digit code from your authenticator app.',
              key: ValueKey(_useBackup),
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _useBackup
                  ? TextField(
                      key: const ValueKey('backup'),
                      controller: _backupCtrl,
                      focusNode: _backupFocus,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]'),
                        ),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      onChanged: (_) {
                        if (_codeError) setState(() => _codeError = false);
                      },
                      onSubmitted: (_) => _submit(),
                      decoration: _decoration(
                        cs,
                        label: 'Backup code',
                        icon: Icons.key_rounded,
                        fill: cs.surface,
                      ),
                    )
                  : _OtpInput(
                      key: const ValueKey('otp'),
                      controller: _otpCtrl,
                      focusNode: _otpFocus,
                      hasError: _codeError,
                      onChanged: (_) {
                        if (_codeError) setState(() => _codeError = false);
                      },
                      onCompleted: _submit,
                    ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: _codeError && _error == null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _useBackup
                          ? 'Enter a valid backup code'
                          : 'Enter all 6 digits',
                      style: text.bodySmall?.copyWith(color: cs.error),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _remember = !_remember),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Remember this device',
                            style: text.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _toggleBackup,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _useBackup ? 'Use authenticator' : 'Use backup code',
                  style: text.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context, ColorScheme cs) {
    final text = Theme.of(context).textTheme;
    final loading = _status == _ButtonState.loading;
    final success = _status == _ButtonState.success;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (loading || success) ? 56.0 : constraints.maxWidth;
        return Align(
          child: Listener(
            onPointerDown: (_) => setState(() => _pressed = true),
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: width,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    success || loading ? 28 : 18,
                  ),
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      success || loading ? 28 : 18,
                    ),
                    onTap: _status == _ButtonState.idle ? _submit : null,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: success
                            ? Icon(
                                Icons.check_rounded,
                                key: const ValueKey('ok'),
                                color: cs.onPrimary,
                                size: 28,
                              )
                            : loading
                            ? SizedBox(
                                key: const ValueKey('load'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Row(
                                key: const ValueKey('idle'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sign In',
                                    style: text.titleMedium?.copyWith(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: cs.onPrimary,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _decoration(
    ColorScheme cs, {
    required String label,
    required IconData icon,
    Widget? suffix,
    Color? fill,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: fill ?? cs.surfaceContainerLow,
      prefixIcon: Icon(icon),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return cs.error;
        if (states.contains(WidgetState.focused)) return cs.primary;
        return cs.onSurface.withValues(alpha: 0.6);
      }),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: border(cs.outlineVariant),
      focusedBorder: border(cs.primary, 1.8),
      errorBorder: border(cs.error),
      focusedErrorBorder: border(cs.error, 1.8),
    );
  }
}

// ======================================================================
// Brand logo with a gentle float + glow pulse
// ======================================================================

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25 + 0.2 * t),
                  blurRadius: 18 + 12 * t,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.bolt_rounded, size: 38, color: cs.onPrimary),
          ),
        );
      },
    );
  }
}

// ======================================================================
// Soft drifting background blobs
// ======================================================================

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(animation.value);
            return Stack(
              children: [
                Positioned(
                  top: -120 + 30 * t,
                  right: -100 + 20 * t,
                  child: _blob(cs.primary.withValues(alpha: 0.16), 320),
                ),
                Positioned(
                  bottom: -140 - 20 * t,
                  left: -120 + 30 * t,
                  child: _blob(cs.tertiary.withValues(alpha: 0.14), 360),
                ),
                Positioned(
                  top: 260 - 24 * t,
                  left: -80,
                  child: _blob(cs.secondary.withValues(alpha: 0.08), 200),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

// ======================================================================
// Error banner
// ======================================================================

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: cs.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// 6-box OTP input backed by ONE hidden TextField
// (so paste, SMS/authenticator autofill and backspace all just work)
// ======================================================================

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
    this.length = 6,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onCompleted;
  final int length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          // The real (invisible) input.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(length),
                ],
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onChanged(value);
                  if (value.length == length) onCompleted();
                },
              ),
            ),
          ),
          // The visible boxes.
          IgnorePointer(
            child: ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final value = controller.text;
                final active = value.length.clamp(0, length - 1);
                return Row(
                  children: List.generate(length, (i) {
                    final filled = i < value.length;
                    final isActive = focusNode.hasFocus && i == active;
                    final Color borderColor = hasError
                        ? cs.error
                        : isActive
                        ? cs.primary
                        : filled
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == length - 1 ? 0 : 8,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: 54,
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(isActive ? 1.06 : 1.0),
                          transformAlignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled
                                ? cs.primaryContainer.withValues(alpha: 0.5)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: isActive || hasError ? 2 : 1,
                            ),
                          ),
                          child: filled
                              ? TweenAnimationBuilder<double>(
                                  key: ValueKey('$i-${value[i]}'),
                                  tween: Tween(begin: 0.4, end: 1),
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutBack,
                                  builder: (context, scale, child) =>
                                      Transform.scale(
                                        scale: scale,
                                        child: child,
                                      ),
                                  child: Text(
                                    value[i],
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                  ),
                                )
                              : (isActive
                                    ? _BlinkingCursor(color: cs.primary)
                                    : null),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
