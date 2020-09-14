library multipass;

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

abstract class MultiLanguage {}

abstract class MultiTheme {}

abstract class MultiDevice {
  final double multiplier = 1;
  final double minSize = 0;
}

typedef V MultiFunction<V>();

abstract class MultiConf<T extends MultiTheme, L extends MultiLanguage,
    D extends MultiDevice> {
  final Map<Type, MultiFunction<T>> themes = null;
  final List<D> devices = null;
  final Map<Type, MultiFunction<L>> languages = null;
  final Map<String, Type> supportedLocales = null;
}

class MultiReference<T extends MultiTheme, L extends MultiLanguage,
    D extends MultiDevice> {
  static MultiReference<T, L, D> createReference<T extends MultiTheme,
      L extends MultiLanguage, D extends MultiDevice>() {
    return MultiReference<T, L, D>(GlobalKey<_MultiPassState<T, L, D>>());
  }

  const MultiReference(this.key);
  final GlobalKey<_MultiPassState<T, L, D>> key;

  T get theme => key.currentState.theme;
  D get device => key.currentState.device;
  L get language => key.currentState.language;
}

class MultiSource<T extends MultiTheme, L extends MultiLanguage,
    D extends MultiDevice> extends StatefulWidget {
  MultiSource(
      {@required this.child,
      @required this.multiconf,
      @required this.reference,
      this.languageOverride,
      this.themeOverride})
      : super(key: reference.key);
  final L languageOverride;
  final MultiReference<T, L, D> reference;
  final T themeOverride;
  final Widget child;
  final MultiConf multiconf;
  static T useTheme<T extends MultiTheme>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'theme')
        .theme;
  }

  static L useLanguage<L extends MultiLanguage>(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context,
            aspect: 'language')
        .language;
  }

  static Type useDevice(BuildContext context) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: 'device')
        .device
        .runtimeType;
  }

  static void useAll(BuildContext context) {
    useDevice(context);
    useTheme(context);
    useLanguage(context);
  }

  static MultiPassData<T, L, D>
      of<T extends MultiTheme, L extends MultiLanguage, D extends MultiDevice>(
              BuildContext context) =>
          InheritedModel.inheritFrom<MultiPassData<T, L, D>>(context);
  @override
  _MultiPassState createState() => _MultiPassState<T, L, D>();
}

class _MultiPassState<T extends MultiTheme, L extends MultiLanguage,
        D extends MultiDevice> extends State<MultiSource>
    with WidgetsBindingObserver {
  double _nextMaxSize = 0;
  List<D> _orderedDevices;
  D device;
  T theme;
  L language;

  @override
  void initState() {
    if (widget.multiconf.languages != null &&
        widget.multiconf.supportedLocales != null) initializeLanguages();
    if (widget.multiconf.themes != null) initializeThemes();
    if (widget.multiconf.devices != null) {
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
    if (widget.multiconf.devices != null) detectDevice();
    super.didChangeMetrics();
  }

  void initializeDevices() {
    List<MultiDevice> _dev = widget.multiconf.devices;
    if (_dev.length == 0) return;
    if (_dev.length == 1) {
      device = _dev.first;
      _orderedDevices = _dev;
      return;
    }
    _orderedDevices = _dev.toList()
      ..sort((a, b) => a.minSize.compareTo(b.minSize));
    detectDevice(shouldUpdate: false);
  }

  void initializeLanguages() {
    assert(widget.multiconf.languages.containsKey(L),
        "The base language ${L.toString()} could not be found");
    if (widget.languageOverride != null &&
        widget.multiconf.languages.containsKey(widget.languageOverride)) {
      //If we override the language we return that one
      language = widget.multiconf.languages[widget.languageOverride]();
    } else if (widget.multiconf.supportedLocales
        .containsKey(ui.window.locale.languageCode)) {
      language = widget.multiconf.languages[widget.multiconf.supportedLocales[ui
          .window
          .locale
          .languageCode]](); //if we find the locale we build the language
    } else {
      language = widget.multiconf
          .languages[L](); //If we don't find it, we build the default language
    }
  }

  void setTheme(Type type) {
    if (widget.multiconf.themes != null &&
        widget.multiconf.themes.containsKey(type)) {
      theme = widget.multiconf.themes[type]();
      if (mounted) setState(() {});
    }
  }

  void setLanguage(Type type) {
    if (widget.multiconf.languages != null &&
        widget.multiconf.languages.containsKey(type)) {
      language = widget.multiconf.languages[type]();
      if (mounted) setState(() {});
    }
  }

  void setDevice() {} //This should not be possible ,antipattern

  void initializeThemes() {
    assert(widget.multiconf.languages.containsKey(T),
        "The base theme ${T.toString()} could not be found");
    if (widget.themeOverride != null &&
        widget.multiconf.themes.containsKey(widget.themeOverride)) {
      // if we override the theme we return
      theme = widget.multiconf.themes[widget.themeOverride]();
    } else {
      theme =
          widget.multiconf.themes[T](); // if not, we return the default theme
    }
  }

  void detectDevice({bool shouldUpdate = true}) {
    List<MultiDevice> _devices = widget.multiconf.devices;
    if (_devices == null || _devices.length <= 1) return;
    double size =
        ui.window.physicalSize.shortestSide / ui.window.devicePixelRatio;
    if (_nextMaxSize == 0 ||
        device == null ||
        (size > device.minSize && size <= _nextMaxSize)) {
      for (var _t = 0; _t < _orderedDevices.length; _t++) {
        D _currentDevice = _orderedDevices[_t];
        double _nextMax = _t + 1 == _orderedDevices.length
            ? double.infinity
            : _orderedDevices[_t + 1].minSize;
        if (size > _currentDevice.minSize && size <= _nextMax) {
          device = _currentDevice;
          break;
        }
      }
    }
    if (shouldUpdate) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiPassData<T, L, D>(
        child: widget.child,
        state: this,
        theme: theme,
        language: language,
        device: device);
  }
}

class MultiPassData<T extends MultiTheme, L extends MultiLanguage,
    D extends MultiDevice> extends InheritedModel<String> {
  const MultiPassData(
      {this.state, this.theme, this.language, this.device, Widget child})
      : super(child: child);

  final _MultiPassState state;
  final T theme;
  final L language;
  final D device;
  static MultiPassData of(BuildContext context, String aspect) {
    return InheritedModel.inheritFrom<MultiPassData>(context, aspect: aspect);
  }

  @override
  bool updateShouldNotifyDependent(
      MultiPassData oldWidget, Set<String> aspects) {
    if (aspects.contains('theme') && theme != oldWidget.theme) {
      return true;
    } else if (aspects.contains('language') && language != oldWidget.language) {
      return true;
    } else if (aspects.contains('device') && device != oldWidget.device) {
      return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(MultiPassData oldWidget) {
    return theme != oldWidget.theme ||
        language != oldWidget.language ||
        device != oldWidget.device;
  }
}

// class DefaultTheme extends MultiTheme {}

// class DefaultLanguage extends MultiLanguage {}

// class DefaultDevice extends MultiDevice {
//   @override
//   double get minSize => 0;

//   @override
//   double get multiplier => 1;

//   int exampleInt = 10;
// }

// final GlobalKey<_MultiPassState<DefaultTheme, DefaultLanguage, DefaultDevice>>
//     _insideKey =
//     GlobalKey<_MultiPassState<DefaultTheme, DefaultLanguage, DefaultDevice>>();

// mixin Paco {
//   var language = _insideKey.currentState.language;
//   var theme = _insideKey.currentState.theme;
//   var device = _insideKey.currentState.device;
//   useTheme(BuildContext context) => MultiSource.useTheme(context);
//   useAll(BuildContext context) => MultiSource.useAll(context);
//   useLanguage(BuildContext context) => MultiSource.useLanguage(context);
//   useDevice(BuildContext context) => MultiSource.useDevice(context);
// }
