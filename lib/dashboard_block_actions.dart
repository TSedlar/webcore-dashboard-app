import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:webcore_dashboard/dashboard_block.dart';

class DashboardBlockActions {
  DashboardBlockActions({required this.state, required this.smartThingsToken, required this.webcoreInstallationId, required this.lightApiPistonId});

  final DashboardBlockState state;
  final String smartThingsToken;
  final String webcoreInstallationId;
  final String lightApiPistonId;

  String getLightAPI() {
    return 'https://graph-na04-useast2.api.smartthings.com/api/token/$smartThingsToken/smartapps/installations/$webcoreInstallationId/execute/$lightApiPistonId';
  }

  Future<bool> setLightDeviceParams(params) async {
    if (state.widget.devices == null) {
      return false;
    }

    try {
      await http.post(Uri.parse(getLightAPI()),
          body: {...params, 'Devices': state.widget.devices!.join(',')});
    } catch (err) {
      // ignored, really.
    }

    return true;
  }

  void launchURL(url) async {
    if (!await launch(url)) {
      throw 'Could not launch $url';
    }
  }

  void showColorPicker() {
    if (state.widget.devices == null) {
      return;
    }

    showDialog(
      context: state.context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Pick Bulb Color(s)'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: state.pickerColor,
            onColorChanged: (color) {
              state.updateState(() => state.pickerColor = color);
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              final colorString = (0xFFFFFF & state.pickerColor.value)
                  .toRadixString(16)
                  .padLeft(6, '0')
                  .toUpperCase();
              print('Changing light colors... ($colorString)');
              await setLightDeviceParams({'Color': colorString});
              SharedPreferences.getInstance().then((prefs) {
                prefs.setInt(
                    state.widget.keyPickerColor, state.pickerColor.value);
                prefs.setInt(
                    state.widget.keyCurrentColor, state.pickerColor.value);
              });
              print('Changed light colors');

              state.updateState(() => state.currentColor = state.pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
