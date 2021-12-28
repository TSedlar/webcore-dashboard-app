// ignore_for_file: constant_identifier_names

import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:webcore_dashboard/dashboard_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

const KEY_JSON_CONFIG = 'jsonconfig';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'webCoRE Dashboard',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (BuildContext context) {
          return const Dashboard(
            title: 'webCoRE Dashboard',
          );
        },
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? config;
  bool _loadedPrefs = false;

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      if (config == null && prefs.containsKey(KEY_JSON_CONFIG)) {
        Map<String, dynamic> localJSON = json.decode(prefs.getString(KEY_JSON_CONFIG)!);
        setState(() => config = localJSON);
      }
      setState(() => _loadedPrefs = true);
    });
    super.initState();
  }

  void _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes != null) {
        String fileString = String.fromCharCodes(fileBytes);
        try {
          Map<String, dynamic> jsonImport = json.decode(fileString);
          setState(() => config = jsonImport);
          prefs.setString(KEY_JSON_CONFIG, fileString);
        } catch (err) {
          setState(() => config = null);
          prefs.remove(KEY_JSON_CONFIG);
        }
      } else {
        setState(() => config = null);
        prefs.remove(KEY_JSON_CONFIG);
      }
    }
  }

  List<Widget> _buildImportScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return [
      SizedBox(
        width: size.width,
        height: size.height - 90.0,
        child: Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            child: const Text('Import JSON'),
            onPressed: () => _importFile(),
            style: ElevatedButton.styleFrom(
              primary: COLOR_AMAZON_LIGHT_BLUE,
              padding: const EdgeInsets.all(25.0),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBlocks(BuildContext context) {
    if (config == null) {
      return <Widget>[];
    }

    final width = MediaQuery.of(context).size.width;
    final gridCount = (width / 200).floor();

    List<Widget> categories = [];

    for (final category in (config!['categories']! as List)) {
      final blocks = (category['blocks']! as List);
      categories.add(Stack(children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 15.0,
          ),
          child: Text(
            category['text']!.toString(),
            style: const TextStyle(
              fontSize: 28.0,
              color: Color(0xffcccccc),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: 50.0,
            bottom: 0.0,
          ),
          child: GridView.count(
            primary: false,
            shrinkWrap: true,
            crossAxisCount: gridCount,
            children: blocks.map((b) {
              final block = DashboardBlock(
                smartThingsToken: config!['smart_things_token']!,
                webcoreInstallationId: config!['webcore_installation_id']!,
                lightApiPistonId: config!['light_api_piston_id']!,
                text: b['text']!,
                icon: IconData(
                  int.parse(b['icon']!),
                  fontFamily: 'MaterialIcons',
                ),
                devices: b['devices'],
                type: b['type'] ?? 'normal',
                onTap: b['onTap'],
                onBulbDimmer: b['onBulbDimmer'],
                onBulbTemp: b['onBulbTemp'],
              );
              return block;
            }).toList(),
            childAspectRatio: width < 400 ? 1.65 : 1.25,
          ),
        )
      ]));
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xff1d232b),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (evt) {
              if (evt == 'Import JSON') {
                _importFile();
              }
            },
            itemBuilder: (BuildContext context) {
              return ['Import JSON'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListView(
          children: !_loadedPrefs
              ? <Widget>[]
              : (config == null
                  ? _buildImportScreen(context)
                  : _buildBlocks(context)),
          primary: true,
        ),
      ),
      backgroundColor: const Color(0xff151920),
    );
  }
}
