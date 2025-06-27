import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPalette {
  final String name;
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final Color accent;
  final Color divider;
  final Color shadow;
  final Color disabled;
  final Color hint;
  final Color? red;
  final Color? green;
  final Color? yellow;
  final Color? blue;
  final Color? magenta;
  final Color? cyan;

  const ColorPalette({
    required this.name,
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.accent,
    required this.divider,
    required this.shadow,
    required this.disabled,
    required this.hint,
    this.red,
    this.green,
    this.yellow,
    this.blue,
    this.magenta,
    this.cyan,
  });

  static Future<ColorPalette> fromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> json = jsonDecode(jsonString);
    
    return ColorPalette(
      name: json['name'] as String,
      primary: _colorFromHex(json['primary'] as String),
      primaryVariant: _colorFromHex(json['primaryVariant'] as String),
      secondary: _colorFromHex(json['secondary'] as String),
      secondaryVariant: _colorFromHex(json['secondaryVariant'] as String),
      surface: _colorFromHex(json['surface'] as String),
      background: _colorFromHex(json['background'] as String),
      error: _colorFromHex(json['error'] as String),
      onPrimary: _colorFromHex(json['onPrimary'] as String),
      onSecondary: _colorFromHex(json['onSecondary'] as String),
      onSurface: _colorFromHex(json['onSurface'] as String),
      onBackground: _colorFromHex(json['onBackground'] as String),
      onError: _colorFromHex(json['onError'] as String),
      accent: _colorFromHex(json['accent'] as String),
      divider: _colorFromHex(json['divider'] as String),
      shadow: _colorFromHex(json['shadow'] as String),
      disabled: _colorFromHex(json['disabled'] as String),
      hint: _colorFromHex(json['hint'] as String),
      red: json['red'] != null ? _colorFromHex(json['red'] as String) : null,
      green: json['green'] != null ? _colorFromHex(json['green'] as String) : null,
      yellow: json['yellow'] != null ? _colorFromHex(json['yellow'] as String) : null,
      blue: json['blue'] != null ? _colorFromHex(json['blue'] as String) : null,
      magenta: json['magenta'] != null ? _colorFromHex(json['magenta'] as String) : null,
      cyan: json['cyan'] != null ? _colorFromHex(json['cyan'] as String) : null,
    );
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'primary': '#${primary.toARGB32().toRadixString(16).substring(2)}',
      'primaryVariant': '#${primaryVariant.toARGB32().toRadixString(16).substring(2)}',
      'secondary': '#${secondary.toARGB32().toRadixString(16).substring(2)}',
      'secondaryVariant': '#${secondaryVariant.toARGB32().toRadixString(16).substring(2)}',
      'surface': '#${surface.toARGB32().toRadixString(16).substring(2)}',
      'background': '#${background.toARGB32().toRadixString(16).substring(2)}',
      'error': '#${error.toARGB32().toRadixString(16).substring(2)}',
      'onPrimary': '#${onPrimary.toARGB32().toRadixString(16).substring(2)}',
      'onSecondary': '#${onSecondary.toARGB32().toRadixString(16).substring(2)}',
      'onSurface': '#${onSurface.toARGB32().toRadixString(16).substring(2)}',
      'onBackground': '#${onBackground.toARGB32().toRadixString(16).substring(2)}',
      'onError': '#${onError.toARGB32().toRadixString(16).substring(2)}',
      'accent': '#${accent.toARGB32().toRadixString(16).substring(2)}',
      'divider': '#${divider.toARGB32().toRadixString(16).substring(2)}',
      'shadow': '#${shadow.toARGB32().toRadixString(16).substring(2)}',
      'disabled': '#${disabled.toARGB32().toRadixString(16).substring(2)}',
      'hint': '#${hint.toARGB32().toRadixString(16).substring(2)}',
      if (red != null) 'red': '#${red!.toARGB32().toRadixString(16).substring(2)}',
      if (green != null) 'green': '#${green!.toARGB32().toRadixString(16).substring(2)}',
      if (yellow != null) 'yellow': '#${yellow!.toARGB32().toRadixString(16).substring(2)}',
      if (blue != null) 'blue': '#${blue!.toARGB32().toRadixString(16).substring(2)}',
      if (magenta != null) 'magenta': '#${magenta!.toARGB32().toRadixString(16).substring(2)}',
      if (cyan != null) 'cyan': '#${cyan!.toARGB32().toRadixString(16).substring(2)}',
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorPalette &&
        other.name == name &&
        other.primary == primary &&
        other.primaryVariant == primaryVariant &&
        other.secondary == secondary &&
        other.secondaryVariant == secondaryVariant &&
        other.surface == surface &&
        other.background == background &&
        other.error == error &&
        other.onPrimary == onPrimary &&
        other.onSecondary == onSecondary &&
        other.onSurface == onSurface &&
        other.onBackground == onBackground &&
        other.onError == onError &&
        other.accent == accent &&
        other.divider == divider &&
        other.shadow == shadow &&
        other.disabled == disabled &&
        other.hint == hint &&
        other.red == red &&
        other.green == green &&
        other.yellow == yellow &&
        other.blue == blue &&
        other.magenta == magenta &&
        other.cyan == cyan;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        primary.hashCode ^
        primaryVariant.hashCode ^
        secondary.hashCode ^
        secondaryVariant.hashCode ^
        surface.hashCode ^
        background.hashCode ^
        error.hashCode ^
        onPrimary.hashCode ^
        onSecondary.hashCode ^
        onSurface.hashCode ^
        onBackground.hashCode ^
        onError.hashCode ^
        accent.hashCode ^
        divider.hashCode ^
        shadow.hashCode ^
        disabled.hashCode ^
        hint.hashCode ^
        red.hashCode ^
        green.hashCode ^
        yellow.hashCode ^
        blue.hashCode ^
        magenta.hashCode ^
        cyan.hashCode;
  }
}