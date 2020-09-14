import 'test.dart';

class DefaultDevice extends MultiDevice {
  static List<DefaultDevice> get getListOfDevices => [
        DefaultDevice(),
        DeviceWatch(),
        DeviceSmallMobile(),
        DeviceMobile(),
        DeviceTablet(),
        DeviceDesktop()
      ];
  @override
  double get minSize => 0;

  @override
  double get multiplier => 1;
}

class DeviceWatch implements DefaultDevice {
  @override
  double get minSize => 0;

  @override
  double get multiplier => 0.7;
}

class DeviceSmallMobile implements DefaultDevice {
  @override
  double get minSize => 300;

  @override
  double get multiplier => 0.85;
}

class DeviceMobile implements DefaultDevice {
  @override
  double get minSize => 450;

  @override
  double get multiplier => 1;
}

class DeviceTablet implements DefaultDevice {
  @override
  double get minSize => 800;

  @override
  double get multiplier => 0.85;
}

class DeviceDesktop implements DefaultDevice {
  @override
  double get minSize => 1200;

  @override
  double get multiplier => 1.5;
}
