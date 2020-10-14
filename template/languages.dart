import 'package:multipass/multipass.dart';

abstract class Languages extends MultiLanguage {
  static Map<MultiOption, LocaleBuilder> get localeBuilder => {
        MultiOption(id: 'en'): () => EnglishLanguage(),
        MultiOption(id: 'es'): () => SpanishLanguage(),
      };

  final String hi = "";
}

class EnglishLanguage implements Languages {
  final String hi = "Hi!";
}

class SpanishLanguage implements Languages {
  final String hi = "Hola!";
}
