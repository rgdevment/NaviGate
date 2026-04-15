import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _surface = Color(0xFF1E1E2E);
  static const _surfaceContainer = Color(0xFF262637);
  static const _surfaceBright = Color(0xFF2E2E42);
  static const _primary = Color(0xFF89B4FA);
  static const _onSurface = Color(0xFFCDD6F4);
  static const _onSurfaceVariant = Color(0xFFA6ADC8);
  static const _outline = Color(0xFF45475A);
  static const _error = Color(0xFFF38BA8);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surface,
    colorScheme: const ColorScheme.dark(
      surface: _surface,
      surfaceContainer: _surfaceContainer,
      surfaceBright: _surfaceBright,
      primary: _primary,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      outline: _outline,
      error: _error,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      bodyMedium: TextStyle(fontSize: 13, color: _onSurface),
      bodySmall: TextStyle(fontSize: 12, color: _onSurfaceVariant),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _onSurfaceVariant,
      ),
    ),
    iconTheme: const IconThemeData(color: _onSurfaceVariant, size: 18),
    dividerTheme: const DividerThemeData(color: _outline, thickness: 0.5),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _primary
            : _onSurfaceVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _primary.withAlpha(80)
            : _outline,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _surface,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceBright,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _outline),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  );
}
