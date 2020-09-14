import 'package:flutter/widgets.dart';
import 'devices.dart';
import 'languages.dart';
import 'themes.dart';
export 'devices.dart';
export 'languages.dart';
export 'themes.dart';

final MultiReference<DefaultTheme, DefaultLanguage, DefaultDevice> reference =
    MultiReference.createReference();

mixin MultiPass {
  DefaultLanguage get language => reference.language;
  DefaultTheme get theme => reference.theme;
  DefaultDevice get device => reference.device;
  DefaultTheme useTheme(BuildContext context) =>
      MultiSource.useTheme<DefaultTheme, DefaultLanguage, DefaultDevice>(
          context);
  void useAll(BuildContext context) =>
      MultiSource.useAll<DefaultTheme, DefaultLanguage, DefaultDevice>(context);

  DefaultLanguage useLanguage(BuildContext context) =>
      MultiSource.useLanguage<DefaultTheme, DefaultLanguage, DefaultDevice>(
          context);

  DefaultDevice useDevice(BuildContext context) =>
      MultiSource.useDevice<DefaultTheme, DefaultLanguage, DefaultDevice>(
          context);

  useThemeAndDevice(BuildContext context) {
    MultiSource.useDevice<DefaultTheme, DefaultLanguage, DefaultDevice>(
        context);
    MultiSource.useTheme<DefaultTheme, DefaultLanguage, DefaultDevice>(context);
  }
}

class MyConfiguration
    implements MultiConf<DefaultTheme, DefaultLanguage, DefaultDevice> {
  @override
  List<DefaultDevice> get devices => DefaultDevice.getListOfDevices;

  @override
  Map<Type, MultiFunction<DefaultLanguage>> get languages =>
      DefaultLanguage.languageBuilders;

  @override
  Map<String, Type> get supportedLocales => DefaultLanguage.locales;

  @override
  Map<Type, MultiFunction<DefaultTheme>> get themes =>
      DefaultTheme.supportedThemes;
}

extension MultiNumber on num {
  double get d => this * reference.device.multiplier;
  int get i => this.d.toInt();
}


//To use this , do :
//void main() {
//  runApp(MultiSource<DefaultTheme, DefaultLanguage, DefaultDevice>(
//      child: const MyApp(), multiconf: MyConfiguration(), reference: reference));
//}