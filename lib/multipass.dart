library multipass;

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

abstract class MultiLanguage {}

abstract class MultiTheme {}

abstract class MultiDevice {
  final double multiplier = 1;
  final double minSize = 0;
}

class _MultiDevice {
  _MultiDevice(
      {this.type, this.multiplier = 1, this.minSize = 0, this.maxSize = 0});

  _MultiDevice.fromDevice(MultiDevice device, double maxValue)
      : this.minSize = device.minSize,
        this.maxSize = maxValue,
        this.type = device.runtimeType,
        this.multiplier = device.multiplier;
  final Type type;
  final double multiplier;
  final double minSize;
  final double maxSize;
}

typedef V MultiFunction<V>();

abstract class MultiConf<T extends MultiTheme, L extends MultiLanguage> {
  final Map<T, MultiFunction<T>> themes = null;
  final List<MultiDevice> devices = null;
  final Map<L, MultiFunction<L>> languages = null;
  final Map<String, L> supportedLocales = null;
}

class MultiPass<T extends MultiTheme, L extends MultiLanguage>
    extends StatefulWidget {
  const MultiPass(
      {@required this.child,
      @required this.multiconf,
      this.languageOverride,
      this.themeOverride});
  final L languageOverride;
  final T themeOverride;
  final Widget child;
  final MultiConf multiconf;
  static _MThemeProvider theme(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MThemeProvider>();
  static _MLanguageProvider language(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MLanguageProvider>();
  static _MDeviceProvider device(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MDeviceProvider>();
  static void setTheme(BuildContext context, Type themeType) => context
      .dependOnInheritedWidgetOfExactType<_MultiState>()
      .state
      .setTheme(themeType);
  static void setLanguage(BuildContext context, Type languageType) => context
      .dependOnInheritedWidgetOfExactType<_MultiState>()
      .state
      .setLanguage(languageType);
  @override
  _MultiPassState createState() => _MultiPassState<T, L>();
}

class _MultiPassState<T extends MultiTheme, L extends MultiLanguage>
    extends State<MultiPass> with WidgetsBindingObserver {
  _MultiDevice device = _MultiDevice();
  List<_MultiDevice> devices;
  T theme;
  L language;

  @override
  void initState() {
    if (widget.multiconf.devices != null) initializeDevices();
    if (widget.multiconf.languages != null &&
        widget.multiconf.supportedLocales != null) initializeLanguages();
    if (widget.multiconf.themes != null) initializeThemes();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      device = _MultiDevice.fromDevice(_dev.first, _dev.first.minSize);
    }
    List<MultiDevice> _devices = _dev.toList()
      ..sort((a, b) => a.minSize.compareTo(b.minSize));
    List<_MultiDevice> _orderedList = [];
    for (int i = 0; i < _devices.length; i++) {
      _orderedList.add(_MultiDevice.fromDevice(_devices[i],
          _devices[i + 1 != _devices.length ? i : _devices.length].minSize));
    }
    devices = _orderedList;
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

  void setDevice() {} //This should not be that, is anti pattern

  void initializeThemes() {
    assert(widget.multiconf.languages.containsKey(L),
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
    if (_devices == null || _devices.length == 0) return;
    double size =
        ui.window.physicalSize.shortestSide / ui.window.devicePixelRatio;
    if (size > device.minSize && size <= device.maxSize) return;
    for (var _t = 0; _t < devices.length; _t++) {
      _MultiDevice _currentDevice = devices[_t];
      if (size > _currentDevice.minSize && size <= _currentDevice.maxSize) {
        device = _currentDevice;
        break;
      }
    }
    if (shouldUpdate) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _MultiState(
        state: this,
        child: _MThemeProvider<T>(
          theme: theme,
          child: _MDeviceProvider(
            device: device,
            child: _MLanguageProvider<L>(
              language: language,
              child: widget.child,
            ),
          ),
        ));
  }
}

class _MultiState extends InheritedWidget {
  final _MultiPassState state;
  const _MultiState({Key key, @required Widget child, @required this.state})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_MultiState oldWidget) => oldWidget.state != state;
}

class _MThemeProvider<T extends MultiTheme> extends InheritedWidget {
  final T theme;
  const _MThemeProvider({Key key, @required Widget child, @required this.theme})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_MThemeProvider oldWidget) =>
      oldWidget.theme != theme;
}

class _MDeviceProvider extends InheritedWidget {
  final _MultiDevice device;
  const _MDeviceProvider({
    Key key,
    @required Widget child,
    @required this.device,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_MDeviceProvider oldWidget) =>
      oldWidget.device != device;
}

class _MLanguageProvider<L extends MultiLanguage> extends InheritedWidget {
  final L language;
  const _MLanguageProvider(
      {Key key, @required Widget child, @required this.language})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_MLanguageProvider oldWidget) =>
      oldWidget.language != language;
}
