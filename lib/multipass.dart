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
  final Map<MultiOption, PaletteBuilder> paletteBuilders = null;
  final Map<double, MetricBuilder> metrics = null;
  final Map<MultiOption, LocaleBuilder> localeBuilders = null;
  final String defaultLocaleId = null;
  final String defaultPaletteId = null;

  MultiStyle styleBuilder(M metrics, P palette, L language) => null;
}

class MultiSource extends StatefulWidget {
  MultiSource(
      {@required this.child,
      @required this.multiconf,
      this.languageId,
      this.themeId});
  final String languageId;
  final String themeId;
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
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'metric')
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
  String currentPaletteId;
  String currentLocaleId;
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
      return;
    }
    _orderedDevices = _dev;
    if (_dev.length != 1) detectDevice(shouldUpdate: false);
  }

  void initializeLanguages() {
    MultiOption opt = containsId(
        widget.multiconf.defaultLocaleId, widget.multiconf.localeBuilders.keys);
    MultiOption _opt;
    assert(opt != null,
        "The default defaultLocale ${widget.multiconf.defaultLocaleId} could not be found in MultiConf.");
    if (widget.languageId != null) {
      _opt =
          containsId(widget.languageId, widget.multiconf.localeBuilders.keys);
      //If we override the language we return that one
    } else {
      _opt = containsId(
          ui.window.locale.languageCode, widget.multiconf.localeBuilders.keys);
    }
    if (_opt != null) opt = _opt;
    currentLocaleId = opt.id;
    language =
        getFromKey<LocaleBuilder>(opt, widget.multiconf.localeBuilders)();

    // widget.multiconf.localeBuilders[opt]();
  }

  MultiOption containsId(String id, Iterable<MultiOption> list) {
    for (int i = 0; i < list.length; i++)
      if (list.elementAt(i).id == id) return list.elementAt(i);
    return null;
  }

  T getFromKey<T>(MultiOption option, Map<MultiOption, dynamic> list) {
    for (int o = 0; o < list.length; o++) {
      MultiOption obj = list.keys.elementAt(o);
      if (obj.id == option.id) {
        return list[obj];
      }
      // if(list[list.keys[o]].)
    }
    return null;
  }

  void setPalette(MultiOption pal) {
    if (widget.multiconf.paletteBuilders != null &&
        pal != null &&
        containsId(pal.id, widget.multiconf.paletteBuilders.keys) != null) {
      palette =
          getFromKey<PaletteBuilder>(pal, widget.multiconf.paletteBuilders)();
      // widget.multiconf.paletteBuilders[pal]();
      buildStyle();
      currentPaletteId = pal.id;
      if (mounted) setState(() {});
    }
  }

  void setLanguage(MultiOption lang) {
    if (widget.multiconf.localeBuilders != null &&
        lang != null &&
        containsId(lang.id, widget.multiconf.localeBuilders.keys) != null) {
      language =
          getFromKey<LocaleBuilder>(lang, widget.multiconf.localeBuilders)();
      // widget.multiconf.localeBuilders[lang]();
      buildStyle();
      currentLocaleId = lang.id;
      if (mounted) setState(() {});
    }
  }

  void setDevice() {} //This should not be possible ,antipattern

  void buildStyle() {
    style = widget.multiconf.styleBuilder(metric, palette, language);
  }

  void initializeColors() {
    MultiOption opt = containsId(widget.multiconf.defaultPaletteId,
        widget.multiconf.paletteBuilders.keys);
    MultiOption _opt;
    assert(opt != null,
        "The default palette ${widget.multiconf.defaultPaletteId} could not be found in MultiConf");
    if (widget.themeId != null) {
      _opt = containsId(widget.themeId, widget.multiconf.paletteBuilders.keys);
      if (_opt != null) opt = _opt;
    }
    currentPaletteId = opt.id;
    palette =
        getFromKey<PaletteBuilder>(opt, widget.multiconf.paletteBuilders)();
    // widget.multiconf.paletteBuilders[opt]();
  }

  void detectDevice({bool shouldUpdate = true}) {
    double size =
        ui.window.physicalSize.shortestSide / ui.window.devicePixelRatio;
    if (_nextMaxSize == 0 ||
        metric == null ||
        (size > _previousMinSize && size <= _nextMaxSize)) {
      for (var _t = 0; _t < _orderedDevices.keys.length; _t++) {
        double _currentMin = _orderedDevices.keys.elementAt(_t);
        double _nextMax = _t + 1 == _orderedDevices.length
            ? double.infinity
            : _orderedDevices.keys.elementAt(_t + 1);
        if (size >= _currentMin && size < _nextMax) {
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

class MultiOption {
  const MultiOption({this.textBuilder, this.icon, @required this.id});
  final StringBuilder textBuilder;
  final IconData icon;
  final String id;
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is MultiOption && other.id == id;
  }
}

typedef String StringBuilder(BuildContext context);
