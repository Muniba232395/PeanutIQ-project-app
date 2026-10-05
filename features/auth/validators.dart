import 'package:flutter/services.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// The backend's identifier is an EmailStr, so the app accepts email addresses only.
bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

final _namePattern = RegExp(r'^[\p{L}\p{M}\s]*$', unicode: true);

/// Same rule as the website's ProfileSetup: letters (any script), marks and spaces only.
final TextInputFormatter nameInputFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) => _namePattern.hasMatch(newValue.text) ? newValue : oldValue,
);

const minPasswordLength = 8;

bool isValidPassword(String value) => value.length >= minPasswordLength;
