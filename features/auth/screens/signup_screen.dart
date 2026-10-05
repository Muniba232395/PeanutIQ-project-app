import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/date_format.dart';
import '../../../core/errors.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../auth_controller.dart';
import '../farm_regions.dart';
import '../validators.dart';
import '../widgets/password_field.dart';
import 'auth_scaffold.dart';

/// Create Account: the farmer's details and a password. On success the farmer is sent
/// to Sign In (not Home) with the email filled in.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _region;
  late String _language = ref.read(localeControllerProvider);
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty &&
      _region != null;

  /// Typing clears the errors and re-evaluates the button.
  void _changed(String _) => setState(() {
        _emailError = _passwordError = _confirmError = _error = null;
      });

  Future<void> _submit() async {
    if (_loading || !_canSubmit) return;
    final t = ref.read(trProvider);
    final emailError = isValidEmail(_email.text) ? null : t.t('auth.app.emailInvalid');
    final passwordError = isValidPassword(_password.text) ? null : t.t('auth.app.passwordShort');
    final confirmError =
        _confirm.text == _password.text ? null : t.t('auth.app.passwordMismatch');
    if (emailError != null || passwordError != null || confirmError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmError = confirmError;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text,
            email: email,
            password: _password.text,
            farmLocation: _region!,
            languageCode: _language,
            timezone: ref.read(deviceTimezoneProvider),
          );
      if (!mounted) return;
      context.go(Uri(
        path: Routes.login,
        queryParameters: {'email': email, 'created': '1'},
      ).toString());
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
    // text-xs font-bold text-gray-600 mb-1, fields space-y-3 (the website's ProfileSetup)
    Widget label(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 12),
          child: Text(t.t(key),
              style: textTheme.labelMedium?.copyWith(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray600)),
        );
    // py-2.5 inputs
    const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    // Dropdowns default to 16px; the text fields are 14px.
    final fieldText = textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.charcoal);

    return AuthScaffold(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('auth.signup.title'), textAlign: TextAlign.center, style: authTitleStyle(textTheme)),
            const SizedBox(height: 8),
            Text(t.t('auth.signup.subtitle'),
                textAlign: TextAlign.center, style: authSubtitleStyle(textTheme)),
            const SizedBox(height: 4),
            label('auth.profileSetup.fullName'),
            TextField(
              key: const Key('nameField'),
              controller: _name,
              inputFormatters: [nameInputFormatter],
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              onChanged: _changed,
              decoration: InputDecoration(
                contentPadding: fieldPadding,
                hintText: t.t('auth.profileSetup.namePlaceholder'),
                prefixIcon: const Icon(LucideIcons.user, size: 20),
              ),
            ),
            label('auth.signup.emailLabel'),
            TextField(
              key: const Key('emailField'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              onChanged: _changed,
              decoration: InputDecoration(
                contentPadding: fieldPadding,
                hintText: t.t('auth.app.emailPlaceholder'),
                prefixIcon: const Icon(LucideIcons.mail, size: 20),
                errorText: _emailError,
              ),
            ),
            label('auth.app.password'),
            PasswordField(
              fieldKey: const Key('passwordField'),
              controller: _password,
              contentPadding: fieldPadding,
              hintText: t.t('auth.app.passwordHint'),
              errorText: _passwordError,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onChanged: _changed,
            ),
            label('auth.app.confirmPassword'),
            PasswordField(
              fieldKey: const Key('confirmPasswordField'),
              controller: _confirm,
              contentPadding: fieldPadding,
              hintText: t.t('auth.app.confirmPassword'),
              errorText: _confirmError,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: _changed,
            ),
            label('auth.profileSetup.farmLocation'),
            DropdownButtonFormField<String>(
              key: const Key('regionField'),
              initialValue: _region,
              isExpanded: true,
              style: fieldText,
              hint: Text(t.t('auth.profileSetup.locationPlaceholder'),
                  style: Theme.of(context).inputDecorationTheme.hintStyle),
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              decoration: const InputDecoration(
                  contentPadding: fieldPadding, prefixIcon: Icon(LucideIcons.mapPin, size: 20)),
              items: [
                for (final region in farmRegions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            label('auth.profileSetup.languagePreference'),
            DropdownButtonFormField<String>(
              key: const Key('languageField'),
              initialValue: _language,
              isExpanded: true,
              style: fieldText,
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              decoration: const InputDecoration(
                  contentPadding: fieldPadding, prefixIcon: Icon(LucideIcons.languages, size: 20)),
              items: [
                DropdownMenuItem(value: 'en', child: Text(t.t('auth.profileSetup.langEnglish'))),
                DropdownMenuItem(value: 'ur', child: Text(t.t('auth.profileSetup.langUrdu'))),
              ],
              onChanged: (value) => setState(() => _language = value ?? _language),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.red500, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: t.t('auth.profileSetup.submitBtn'),
              color: AppColors.authButton,
              showLogo: true,
              loading: _loading,
              onPressed: _canSubmit ? _submit : null,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t.t('auth.signup.hasAccount'), style: authFooterStyle(textTheme)),
                TextButton(
                  // If Sign In is underneath, go back to it; otherwise open it on top
                  // (first launch), so Android Back returns here.
                  onPressed: () => context.canPop() ? context.pop() : context.push(Routes.login),
                  child: Text(t.t('auth.signup.loginLink')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
