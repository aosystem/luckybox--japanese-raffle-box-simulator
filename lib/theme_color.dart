import 'package:flutter/material.dart';

class ThemeColor {
  final int? themeNumber;
  final BuildContext context;

  ThemeColor({this.themeNumber, required this.context});

  Brightness get _effectiveBrightness {
    switch (themeNumber) {
      case 1:
        return Brightness.light;
      case 2:
        return Brightness.dark;
      default:
        return Theme.of(context).brightness;
    }
  }

  bool get _isLight => _effectiveBrightness == Brightness.light;

  //main page
  Color get colorNote => _isLight ? Color.fromRGBO(255, 0, 0, 0.4) : Color.fromRGBO(255, 100, 100, 0.8);
  Color get colorBack => _isLight ? Color.fromRGBO(255, 204, 0, 1) : Color.fromRGBO(
      117, 90, 0, 1.0);
  Color get colorSettingHeader => _isLight ? Color.fromRGBO(255, 204, 0, 1) : Color.fromRGBO(
      124, 101, 0, 1.0) ;
  String get backImage => _isLight ? 'assets/image/back.png' : 'assets/image/back_dark.png';
  //setting page
  Color get backColor => _isLight ? Colors.grey[300]! : Colors.grey[900]!;
  Color get cardColor => _isLight ? Colors.white : Colors.grey[800]!;
  Color get appBarForegroundColor => _isLight ? Colors.grey[700]! : Colors.white70;
  Color get dropdownColor => cardColor;
  Color get borderColor => _isLight ? Colors.grey[300]! : Colors.grey[700]!;
  Color get inputFillColor => _isLight ? Colors.grey[50]! : Colors.grey[900]!;
}
