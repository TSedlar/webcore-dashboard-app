import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcore_dashboard/dashboard_block.dart';
import 'package:webcore_dashboard/slider_thumb_painter.dart';

class DashboardBlockCardBuilder {
  DashboardBlockCardBuilder({required this.state});

  final DashboardBlockState state;

  List<Widget> buildBulbCardChildren(itemText) {
    return [
      itemText,
      // Dimmer Icon & Slider
      const Positioned(
        child: Icon(Icons.wb_sunny, color: COLOR_AMAZON_ORANGE),
        right: 0.0,
        top: 5.0,
      ),
      Positioned(
        child: RotatedBox(
          quarterTurns: 3,
          child: SizedBox(
            width: max(0.0, state.getHeight() - 120.0),
            child: SliderTheme(
              data: SliderThemeData(
                overlayShape: SliderComponentShape.noThumb,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                trackShape: const RoundSliderTrackShape(radius: 20.0),
                activeTrackColor: COLOR_AMAZON_LIGHT_BLUE,
                thumbColor: COLOR_AMAZON_LIGHT_BLUE,
              ),
              child: Slider(
                value: state.dimness,
                min: 0.0,
                max: BULB_BRIGHTNESS_MAX,
                onChanged: (value) {
                  state.updateState(() => state.dimness = value);
                },
                onChangeEnd: (value) {
                  print('Changing Dimness to ${value.toInt().toString()}...');
                  state.actions.setLightDeviceParams(
                      {'Dimness': value.toInt().toString()});
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setDouble(state.widget.keyDimness, value);
                  });
                  print('Changed Dimness');
                },
              ),
            ),
          ),
        ),
        right: 0.5,
        top: 50.0,
      ),
      // Temperature Icon & Slider
      const Positioned(
        child: Icon(Icons.device_thermostat, color: COLOR_AMAZON_ORANGE),
        left: 0.0,
        bottom: 5.0,
      ),
      Positioned(
        child: SizedBox(
          width: max(0.0, state.getWidth() - 110.0),
          child: SliderTheme(
            data: SliderThemeData(
              overlayShape: SliderComponentShape.noThumb,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              trackShape: const RoundSliderTrackShape(radius: 20.0),
              activeTrackColor: COLOR_AMAZON_LIGHT_BLUE,
              thumbColor: COLOR_AMAZON_LIGHT_BLUE,
            ),
            child: Slider(
              value: state.temp,
              min: 0.0,
              max: BULB_TEMP_MAX,
              onChanged: (value) {
                state.updateState(() => state.temp = value);
              },
              onChangeEnd: (value) {
                state.updateState(() {
                  state.pickerColor = COLOR_AMAZON_ORANGE;
                  state.currentColor = COLOR_AMAZON_ORANGE;
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setInt(
                        state.widget.keyPickerColor, state.pickerColor.value);
                    prefs.setInt(
                        state.widget.keyCurrentColor, state.currentColor.value);
                  });
                });
                print('Setting ColorTemp to ${value.toInt().toString()}...');
                state.actions.setLightDeviceParams(
                    {'ColorTemp': value.toInt().toString()});
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setDouble(state.widget.keyTemp, value);
                });
                print('Changed ColorTemp');
              },
            ),
          ),
        ),
        bottom: 5.0,
        left: 40.0,
      ),
      // Power-on button
      Positioned(
        right: 70.0,
        bottom: 35.0,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            child: const Icon(Icons.flash_on, color: COLOR_AMAZON_ORANGE),
            onTap: () {
              state.actions.setLightDeviceParams({'Dimness': '100'});
              state.updateState(() => state.dimness = 100.0);
            },
          ),
        ),
      ),
      // Power-off button
      Positioned(
        right: 35.0,
        bottom: 35.0,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            child: const Icon(Icons.flash_off, color: COLOR_AMAZON_ORANGE),
            onTap: () {
              state.actions.setLightDeviceParams({'Dimness': '0'});
              state.updateState(() => state.dimness = 0.0);
            },
          ),
        ),
      ),
      // Bottom Right Icon
      Positioned(
        bottom: 5.0,
        right: 0.0,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              state.actions.showColorPicker();
            },
            child: Icon(state.widget.icon, color: state.currentColor),
          ),
        ),
      )
    ];
  }
}
