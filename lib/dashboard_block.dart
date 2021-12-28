// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:webcore_dashboard/dashboard_block_actions.dart';
import 'package:webcore_dashboard/dashboard_block_card_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

const COLOR_LIGHT_TEXT = Color(0xffcccccc);
const COLOR_AMAZON_LIGHT_BLUE = Color(0xff007185);
const COLOR_AMAZON_DARK_BLUE = Color(0xff1d232b);
const COLOR_AMAZON_ORANGE = Color(0xffe48a04);

const BULB_TEMP_MAX = 8000.0;
const BULB_BRIGHTNESS_MAX = 100.0;

// ignore: must_be_immutable
class DashboardBlock extends StatefulWidget {
  DashboardBlock({
    Key? key,
    required this.smartThingsToken,
    required this.webcoreInstallationId,
    required this.lightApiPistonId,
    required this.text,
    required this.icon,
    this.type = 'normal',
    this.devices,
    this.onTap,
    this.onBulbDimmer,
    this.onBulbTemp,
  }) : super(key: key);

  final String smartThingsToken;
  final String webcoreInstallationId;
  final String lightApiPistonId;
  final String text;
  final IconData icon;
  final String type;
  final List<dynamic>? devices;

  final dynamic onTap;
  final dynamic onBulbDimmer;
  final dynamic onBulbTemp;

  late final String keyDimness;
  late final String keyTemp;
  late final String keyPickerColor;
  late final String keyCurrentColor;

  late final double? initialValueDimness;
  late final double? initialValueTemp;
  late final Color? initialValuePickerColor;
  late final Color? initialValueCurrentColor;

  bool _loaded = false;

  @override
  State<DashboardBlock> createState() => DashboardBlockState();

  Future<void> loadInitialValues() async {
    if (_loaded) {
      return;
    }

    _loaded = true;

    keyDimness = '$text-dimness';
    keyTemp = '$text-temp';
    keyPickerColor = '$text-picker-color';
    keyCurrentColor = '$text-current-color';

    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(keyDimness)) {
      initialValueDimness = prefs.getDouble(keyDimness)!;
      print(
          'Loaded Initial Shared Key: $keyDimness -> ${initialValueDimness!.toString()}');
    } else {
      initialValueDimness = null;
    }

    if (prefs.containsKey(keyTemp)) {
      initialValueTemp = prefs.getDouble(keyTemp)!;
      print(
          'Loaded Initial Shared Key: $keyTemp -> ${initialValueTemp!.toString()}');
    } else {
      initialValueTemp = null;
    }

    if (prefs.containsKey(keyPickerColor)) {
      initialValuePickerColor = Color(prefs.getInt(keyPickerColor)!);
      print(
          'Loaded Initial Shared Key: $keyPickerColor -> ${initialValuePickerColor!.value.toString()}');
    } else {
      initialValuePickerColor = null;
    }

    if (prefs.containsKey(keyCurrentColor)) {
      initialValueCurrentColor = Color(prefs.getInt(keyCurrentColor)!);
      print(
          'Loaded Initial Shared Key: $keyCurrentColor -> ${initialValueCurrentColor!.value.toString()}');
    } else {
      initialValueCurrentColor = null;
    }
  }
}

class DashboardBlockState extends State<DashboardBlock> {
  bool hovered = false;

  double dimness = 50.0;
  double temp = 2500.0;
  Color pickerColor = COLOR_AMAZON_ORANGE;
  Color currentColor = COLOR_AMAZON_ORANGE;

  bool _loadedInitialState = false;

  final GlobalKey _globalKey = GlobalKey();
  double _width = 0.0;
  double _height = 0.0;

  late final DashboardBlockActions actions = DashboardBlockActions(
    state: this,
    smartThingsToken: widget.smartThingsToken,
    webcoreInstallationId: widget.webcoreInstallationId,
    lightApiPistonId: widget.lightApiPistonId,
  );

  late final DashboardBlockCardBuilder builder =
      DashboardBlockCardBuilder(state: this);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      _width = _globalKey.currentContext!.size!.width;
      _height = _globalKey.currentContext!.size!.height;
      setState(() {});
    });
  }

  void updateState(VoidCallback callback) {
    setState(callback);
  }

  double getWidth() {
    return _width;
  }

  double getHeight() {
    return _height;
  }

  void _loadInitialState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await widget.loadInitialValues();

      if (widget.initialValueDimness != null) {
        dimness = widget.initialValueDimness!;
      }

      if (widget.initialValueTemp != null) {
        temp = widget.initialValueTemp!;
      }

      if (widget.initialValuePickerColor != null) {
        pickerColor = widget.initialValuePickerColor!;
      }

      if (widget.initialValueCurrentColor != null) {
        currentColor = widget.initialValueCurrentColor!;
      }

      _loadedInitialState = true;
    });
  }

  void _updateSize() {
    // Account for resizing
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final w = _globalKey.currentContext?.size?.width;
      final h = _globalKey.currentContext?.size?.height;

      if (w != null && w != _width) {
        _width = w;
      }

      if (h != null && h != _height) {
        _height = h;
      }
    });
  }

  void _doAction(action) {
    if (action != null && action['action'] != null && action['args'] != null) {
      switch (action['action']) {
        case 'launch_url':
          actions.launchURL(action['args'][0]);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._loaded || !_loadedInitialState) {
      _loadInitialState();
    }

    _updateSize();

    bool showHoverStyles = widget.type != 'bulb';

    final itemText = SizedBox(
      width: max(0, _width - 60.0),
      child: Text(
        widget.text,
        style: const TextStyle(
          fontSize: 28.0,
          color: COLOR_LIGHT_TEXT,
        ),
      ),
    );

    final List<Widget> cardChildren;

    switch (widget.type) {
      case 'bulb':
        cardChildren = builder.buildBulbCardChildren(itemText);
        break;
      default:
        cardChildren = [
          itemText,
          Positioned(
            bottom: 5.0,
            right: 0.0,
            child: Icon(widget.icon, color: COLOR_AMAZON_ORANGE),
          )
        ];
        break;
    }

    return MouseRegion(
      cursor:
          showHoverStyles ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (evt) {
        if (!showHoverStyles) {
          return;
        }
        setState(() {
          hovered = true;
        });
      },
      onExit: (evt) {
        setState(() {
          if (!showHoverStyles) {
            return;
          }
          hovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            _doAction(widget.onTap);
          }
        },
        child: Card(
          key: _globalKey,
          color: hovered ? COLOR_AMAZON_LIGHT_BLUE : COLOR_AMAZON_DARK_BLUE,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10.0,
              right: 10.0,
              top: 10.0,
              bottom: 3.0,
            ),
            child: Stack(children: cardChildren),
          ),
        ),
      ),
    );
  }
}
