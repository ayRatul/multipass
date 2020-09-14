import 'package:flutter/widgets.dart';
import 'test.dart';

class DefaultTheme extends MultiTheme {
  static get supportedThemes => {
        DefaultTheme: () => DefaultTheme(),
        LightTheme: () => LightTheme(),
        DarkTheme: () => DarkTheme()
      };
  final Color background = Color(0xFFEBEBEB);
}

class LightTheme extends DefaultTheme {} //We don't do anything since the default theme is light

class DarkTheme extends DefaultTheme {
  Color get background => Color(0xFF000000);
}
