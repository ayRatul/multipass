library multipass;

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'dart:collection';

abstract class MultiLanguage {}

abstract class MultiStyle {}

abstract class MultiPalette {}

abstract class MultiMetric {}

typedef MultiLanguage LocaleBuilder();
typedef MultiPalette PaletteBuilder();
typedef MultiMetric MetricBuilder();

abstract class MultiConf<P extends MultiPalette, L extends MultiLanguage,
    M extends MultiMetric> {
  final Map<Type, PaletteBuilder> paletteBuilders = null;
  final Map<double, MetricBuilder> metrics = null;
  final Map<String, LocaleBuilder> localeBuilders = null;
  final String defaultLocale = null;
  final Type defaultPalette = null;

  MultiStyle styleBuilder(M metrics, P palette, L language) => null;
}

class MultiSource<T extends MultiPalette, L extends MultiLanguage,
    M extends MultiMetric, S extends MultiStyle> extends StatefulWidget {
  MultiSource(
      {@required this.child,
      @required this.multiconf,
      this.localeOverride,
      this.themeOverride});
  final String localeOverride;
  final T themeOverride;
  final Widget child;
  final MultiConf multiconf;
  static P getPalette<P extends MultiPalette>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'palette')
        .palette;
  }

  static L getLanguage<L extends MultiLanguage>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context,
            aspect: 'language')
        .language;
  }

  static M getMetric<M extends MultiMetric>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'device')
        .metric;
  }

  static S getStyle<S extends MultiStyle>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'style')
        .style;
  }

  static MultiPassData of(BuildContext context) =>
      InheritedModel.inheritFrom<MultiPassData>(context);
  @override
  _MultiPassState createState() => _MultiPassState();
}

class _MultiPassState extends State<MultiSource> with WidgetsBindingObserver {
  double _nextMaxSize = 0;
  double _previousMinSize = 0;
  Map<double, MetricBuilder> _orderedDevices;
  MultiMetric metric;
  MultiPalette palette;
  MultiLanguage language;
  MultiStyle style;
  @override
  void initState() {
    if (widget.multiconf.paletteBuilders != null) initializeColors();
    if (widget.multiconf.localeBuilders != null) initializeLanguages();
    if (widget.multiconf.metrics != null) {
      WidgetsBinding.instance.addObserver(this);
      initializeDevices();
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (widget.multiconf.metrics != null && widget.multiconf.metrics.length > 1)
      detectDevice();
    super.didChangeMetrics();
  }

  void initializeDevices() {
    SplayTreeMap<double, MetricBuilder> _dev =
        SplayTreeMap.from(widget.multiconf.metrics);

    if (_dev.length == 0) return;
    if (_dev.length == 1) {
      metric = _dev[_dev.keys.first]();
      _orderedDevices = _dev;
      return;
    }
    // _orderedDevices = _dev.toList()
    //   ..sort((a, b) => a.minSize.compareTo(b.minSize));
    detectDevice(shouldUpdate: false);
  }

  void initializeLanguages() {
    assert(
        widget.multiconf.localeBuilders
            .containsKey(widget.multiconf.defaultLocale),
        "The default localce ${widget.multiconf.defaultLocale.toString()} could not be found in MultiConf.");
    if (widget.localeOverride != null &&
        widget.multiconf.localeBuilders.containsKey(widget.localeOverride)) {
      //If we override the language we return that one
      language = widget.multiconf.localeBuilders[widget.localeOverride]();
    } else if (widget.multiconf.localeBuilders
        .containsKey(ui.window.locale.languageCode)) {
      language = widget.multiconf.localeBuilders[ui.window.locale
          .languageCode](); //if we find the locale we build the language
    } else {
      language = widget.multiconf.localeBuilders[widget.multiconf
          .defaultLocale](); //If we don't find it, we build the default language
    }
  }

  void setPalette(Type type) {
    if (widget.multiconf.paletteBuilders != null &&
        widget.multiconf.paletteBuilders.containsKey(type)) {
      palette = widget.multiconf.paletteBuilders[type]();
      buildStyle();
      if (mounted) setState(() {});
    }
  }

  void setLanguage(Type type) {
    if (widget.multiconf.localeBuilders != null &&
        widget.multiconf.localeBuilders.containsKey(type)) {
      language = widget.multiconf.localeBuilders[type]();
      buildStyle();
      if (mounted) setState(() {});
    }
  }

  void setDevice() {} //This should not be possible ,antipattern

  void buildStyle() {
    style = widget.multiconf.styleBuilder(metric, palette, language);
  }

  void initializeColors() {
    assert(
        widget.multiconf.paletteBuilders
            .containsKey(widget.multiconf.defaultPalette),
        "The default palette ${widget.multiconf.defaultPalette.toString()} could not be found in MultiConf");
    if (widget.themeOverride != null &&
        widget.multiconf.paletteBuilders.containsKey(widget.themeOverride)) {
      // if we override the theme we return
      palette = widget.multiconf.paletteBuilders[widget.themeOverride]();
    } else {
      palette = widget.multiconf.paletteBuilders[widget
          .multiconf.defaultPalette](); // if not, we return the default theme
    }
  }

  void detectDevice({bool shouldUpdate = true}) {
    double size =
        ui.window.physicalSize.shortestSide / ui.window.devicePixelRatio;
    if (_nextMaxSize == 0 ||
        metric == null ||
        (size > _previousMinSize && size <= _nextMaxSize)) {
      for (var _t = 0; _t < _orderedDevices.length; _t++) {
        double _currentMin = _orderedDevices.keys.elementAt(_t);
        double _nextMax = _t + 1 == _orderedDevices.length
            ? double.infinity
            : _orderedDevices.keys.elementAt(_t);
        if (size > _currentMin && size <= _nextMax) {
          _previousMinSize = _currentMin;
          metric = _orderedDevices[_currentMin]();
          break;
        }
      }
    }
    buildStyle();
    if (shouldUpdate) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiPassData(
        child: widget.child,
        state: this,
        palette: palette,
        style: style,
        language: language,
        metric: metric);
  }
}

class MultiPassData extends InheritedModel<String> {
  const MultiPassData(
      {this.state,
      this.palette,
      this.language,
      this.metric,
      this.style,
      Widget child})
      : super(child: child);

  final _MultiPassState state;
  final MultiPalette palette;
  final MultiLanguage language;
  final MultiMetric metric;
  final MultiStyle style;
  static MultiPassData of(BuildContext context, String aspect) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: aspect);
  }

  @override
  bool updateShouldNotifyDependent(
      MultiPassData oldWidget, Set<String> aspects) {
    if (aspects.contains('palette') && palette != oldWidget.palette) {
      return true;
    } else if (aspects.contains('language') && language != oldWidget.language) {
      return true;
    } else if (aspects.contains('metric') && metric != oldWidget.metric) {
      return true;
    } else if (aspects.contains('style') && style != oldWidget.style) {
      return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(MultiPassData oldWidget) {
    return palette != oldWidget.palette ||
        style != oldWidget.style ||
        language != oldWidget.language ||
        metric != oldWidget.metric;
  }
}
