import 'package:multipass/multipass.dart';

abstract class Metrics extends MultiMetric {
  static Map<double, MetricBuilder> get getListOfDevices => {
        0: () => MetricsWatch(),
        300: () => MetricsSmallMobile(),
        450: () => MetricsMobile(), //This device
        800: () => MetricsTablet(),
        1300: () => MetricsDesktop()
      };
  Metrics(double multiplier)
      : this.exampleSize = 48 * multiplier,
        this.exampleMargin = 8 * multiplier;
  final double exampleSize;
  final double exampleMargin;
}

class MetricsWatch extends Metrics {
  MetricsWatch() : super(0.7);
}

class MetricsSmallMobile extends Metrics {
  MetricsSmallMobile() : super(0.85);
}

class MetricsMobile extends Metrics {
  MetricsMobile() : super(1);
}

class MetricsTablet extends Metrics {
  MetricsTablet() : super(1.2);
}

class MetricsDesktop extends Metrics {
  MetricsDesktop() : super(1.5);
}
