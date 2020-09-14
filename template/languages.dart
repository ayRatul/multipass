import 'test.dart';

class DefaultLanguage extends MultiLanguage {
  static get languageBuilders => {
        DefaultLanguage: () => DefaultLanguage(),
        EnglishLanguage: () => EnglishLanguage(),
        SpanishLanguage: () => SpanishLanguage()
      };
  static get locales => {
        'en': EnglishLanguage,
        'es': SpanishLanguage,
      };

  final String hi = "Hi!";
}

class EnglishLanguage extends DefaultLanguage {} //We don't do anything since english is the default language

class SpanishLanguage implements DefaultLanguage {
  String get hi => "Hola!";
}
