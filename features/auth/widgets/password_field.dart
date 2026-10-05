import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';

/// A password input with a show/hide eye. Hidden by default.
class PasswordField extends ConsumerStatefulWidget {
  const PasswordField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.helperText,
    this.contentPadding,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    this.onChanged,
    this.onSubmitted,
  });

  /// Key for the inner TextField, so tests and autofill find the input itself.
  final Key? fieldKey;
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final String? helperText;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  ConsumerState<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends ConsumerState<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(trProvider);
    return TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: widget.autofillHints,
      // Passwords are Latin even in Urdu, so they always read left to right.
      textDirection: TextDirection.ltr,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        contentPadding: widget.contentPadding,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        errorMaxLines: 2,
        prefixIcon: const Icon(LucideIcons.lock, size: 20),
        suffixIcon: IconButton(
          tooltip: t.t(_visible ? 'auth.app.hidePassword' : 'auth.app.showPassword'),
          icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
