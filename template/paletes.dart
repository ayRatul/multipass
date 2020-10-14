import 'package:flutter/widgets.dart';
import 'package:multipass/multipass.dart';

abstract class Palettes extends MultiPalette {
  static Map<MultiOption, PaletteBuilder> get paletteBuilders => {
        MultiOption(id: 'lightTheme'): () => LightTheme(),
        MultiOption(id: 'darkTheme'): () => DarkTheme()
      };
  final Color background = null;
}

class LightTheme extends Palettes {
  final Color background = Color(0xFFEBEBEB);
} //We don't do anything since the default theme is light

class DarkTheme extends Palettes {
  Color get background => Color(0xFF000000);
}
