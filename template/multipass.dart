import 'package:flutter/widgets.dart';
import 'package:multipass/multipass.dart';
import 'metrics.dart';
import 'languages.dart';
import 'paletes.dart';

extension MultiPass on BuildContext {
  Languages get language => MultiSource.getLanguage(this);
  Palettes get theme => MultiSource.getPalette(this);
  Metrics get metrics => MultiSource.getMetric(this);
  MyStyle get style => MultiSource.getStyle(this);
}

class MyConfiguration implements MultiConf<Palettes, Languages, Metrics> {
  @override
  String get defaultLocaleId => 'en';

  @override
  String get defaultPaletteId => "lightTheme";

  @override
  Map<MultiOption, LocaleBuilder> get localeBuilders => Languages.localeBuilder;

  @override
  Map<double, MetricBuilder> get metrics => Metrics.getListOfDevices;

  @override
  Map<MultiOption, PaletteBuilder> get paletteBuilders =>
      Palettes.paletteBuilders;

  @override
  MultiStyle styleBuilder(
          Metrics metrics, Palettes palette, Languages language) =>
      MyStyle(metrics, palette, language);
}

class MyStyle extends MultiStyle {
  MyStyle(Metrics metrics, Palettes palette, Languages language)
      : this.exampleTextStyle = TextStyle(
          fontSize: 24.0 * metrics.exampleMargin,
          color: palette.background,
        );
  final TextStyle exampleTextStyle;
}

//To use this , do :
//void main() {
//  runApp(MultiSource(
//      child: const MyApp(), multiconf: MyConfiguration(), reference: reference));
//}

//Then just call
//context.style.exampleTextStyle
//context.palette.background
