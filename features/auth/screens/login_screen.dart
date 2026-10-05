import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api_client.dart';
import '../../../core/errors.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/toast.dart';
import '../auth_controller.dart';
import '../validators.dart';
import '../widgets/password_field.dart';
import 'auth_scaffold.dart';

/// Email and password sign-in. Create Account sends the farmer here with the email filled in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail = '', this.accountCreated = false});

  final String initialEmail;

  /// Just came from Create Account: confirm it with a toast.
  final bool accountCreated;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _clearErrors() {
    if (_emailError != null || _error != null) {
      setState(() => _emailError = _error = null);
    }
  }

  Future<void> _submit() async {
    // The keyboard's Done key and the button can both fire before the button rebuilds as disabled.
    if (_loading || !_canSubmit) return;
    final t = ref.read(trProvider);
    if (!isValidEmail(_email.text)) {
      setState(() => _emailError = t.t('auth.app.emailInvalid'));
      return;
    }
    setState(() {
      _loading = true;
      _emailError = _error = null;
    });
    try {
      final outcome = await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
      // On success the router moves to Home by itself.
      if (outcome == LoginOutcome.blockedRole && mounted) {
        _password.clear();
        showToast(context, t.t('auth.app.farmersOnly'), type: ToastType.warning);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = describeError(e, t));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.t('auth.mockup.welcome'),
              textAlign: TextAlign.center,
              style: authTitleStyle(textTheme),
            ),
            const SizedBox(height: 8),
            Text(
              t.t('auth.mockup.loginDesc'),
              textAlign: TextAlign.center,
              style: authSubtitleStyle(textTheme),
            ),
            if (ref.watch(demoModeProvider)) ...[
              const SizedBox(height: 12),
              Text(
                t.t('auth.app.demoHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest),
              ),
            ],
            const SizedBox(height: 32),
            // A banner rather than a toast: Android's save-password sheet opens at this moment
            // and would cover a toast until it disappeared.
            if (widget.accountCreated) ...[
              Container(
                key: const Key('accountCreatedBanner'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  border: Border.all(color: AppColors.green200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.circleCheck, size: 20, color: AppColors.forest),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.t('auth.app.accountCreated'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.forest),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              key: const Key('emailField'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearErrors(),
              decoration: InputDecoration(
                hintText: t.t('auth.app.emailPlaceholder'),
                prefixIcon: const Icon(LucideIcons.user, size: 20),
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              fieldKey: const Key('passwordField'),
              controller: _password,
              hintText: t.t('auth.app.password'),
              errorText: _error,
              onChanged: (_) => _clearErrors(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: Listenable.merge([_email, _password]),
              builder: (context, _) => AppButton(
                label: t.t('auth.app.signInBtn'),
                color: AppColors.authButton,
                showLogo: true,
                loading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t.t('auth.login.noAccount'), style: authFooterStyle(textTheme)),
                TextButton(
                  // If Create Account is underneath, go back to it; otherwise open it on top,
                  // so Android Back always returns here.
                  onPressed: () => context.canPop() ? context.pop() : context.push(Routes.signup),
                  child: Text(t.t('auth.login.signupLink')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
