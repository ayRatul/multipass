import 'package:multipass/multipass.dart';

abstract class Languages extends MultiLanguage {
  static Map<String, LocaleBuilder> get localeBuilder => {
        'en': () => EnglishLanguage(),
        'es': () => SpanishLanguage(),
      };

  final String hi = "";
}

class EnglishLanguage implements Languages {
  final String hi = "Hi!";
}

class SpanishLanguage implements Languages {
  final String hi = "Hola!";
}
