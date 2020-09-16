import 'package:flutter/widgets.dart';
import 'package:multipass/multipass.dart';

abstract class Palettes extends MultiPalette {
  static Map<Type, PaletteBuilder> get paletteBuilders =>
      {LightTheme: () => LightTheme(), DarkTheme: () => DarkTheme()};
  final Color background = null;
}

class LightTheme extends Palettes {
  final Color background = Color(0xFFEBEBEB);
} //We don't do anything since the default theme is light

class DarkTheme extends Palettes {
  Color get background => Color(0xFF000000);
}
