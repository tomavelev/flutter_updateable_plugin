library updatable;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:url_launcher/url_launcher.dart';
import 'Trans.dart';
import 'constants.dart';

class Updatable extends StatefulWidget {
  final Widget child;

  const Updatable({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UpdatableState();
  }
}

class UpdatableState extends State<Updatable> {
  var isCurrentVersion = true;
  var loading = false;
  var shouldForceTheUpgrade = false;
  String? versionURL = "";
  int latestVersion = -1;

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        loading ? Text(Trans.of(context).checkingForNewVersion) : Container(),
        isCurrentVersion
            ? Container()
            : ElevatedButton(
                onPressed: () {
                  viewNewVersion();
                },
                child: Center(
                    child: Text(
                  "${Trans.of(context).newVersionIsAvailable} ($APP_VERSION => $latestVersion)",
                  style: TextStyle(fontSize: 40),
                  textAlign: TextAlign.center,
                )),
              ),
        Expanded(
          child: !isCurrentVersion && shouldForceTheUpgrade
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(Trans.of(context).pleaseUpdateNow),
                  ElevatedButton(
                      onPressed: () {
                        viewNewVersion();
                      },
                      child: Center(
                          child: Text(
                        Trans.of(context).updateNow,
                      )))
                ]))
              : widget.child,
        )
      ],
    );
  }

  void loadVersion() {
    isOnline().then((isOnline) {
      setState(() {
        if (isOnline) {
          loading = true;
          isCurrentVersion = true;
          shouldForceTheUpgrade = false;
          doLoad();
        } else {
          loading = false;
          isCurrentVersion = true;
          shouldForceTheUpgrade = false;
        }
      });
    });
  }

  static Future<bool> isOnline() async {
    Connectivity connectivity = Connectivity();
    var connResult = await connectivity.checkConnectivity();
    return connResult != ConnectivityResult.none;
  }

  Future<void> viewNewVersion() async {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return BuildList(
            shouldForceTheUpgrade: shouldForceTheUpgrade,
            appPackage: versionURL!,
          );
        },
        fullscreenDialog: true));
  }

  void doLoad() {
    var uri = Uri.parse(UPDATE_HOST);
    http
        .post(uri,
            body: jsonEncode({
              "APP_VERSION": APP_VERSION,
              "APP_CHANNEL": APP_CHANNEL,
              "APP_GUID": APP_GUID,
              "PLATFORM": APP_PLATFORM,
            }))
        .catchError((resp) {
      setState(() {
        loading = false;
        isCurrentVersion = true;
        shouldForceTheUpgrade = false;
      });
    }).then((response) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          loading = false;
          isCurrentVersion = true;
          shouldForceTheUpgrade = false;
        });
      }
      var result = json.decode(response.body);

      setState(() {
        loading = false;

        if (result != null && result['appPackage'] != null) {
          versionURL = result['appPackage'];
          latestVersion = result['latestVersion'];
          isCurrentVersion = latestVersion <= APP_VERSION;
          shouldForceTheUpgrade = result['shouldForceTheUpgrade'];
        }
      });
    });
  }
}

class BuildList extends StatefulWidget {
  final bool shouldForceTheUpgrade;
  final String appPackage;

  const BuildList({Key? key, required this.shouldForceTheUpgrade, required this.appPackage}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BuildState();
  }
}

class Build {
  String name;
  int number;
  String appPackage;
  bool shouldForceTheUpgrade;
  int? timestamp;
  String changesInThisVersion;

  Build({
    required this.name,
    required this.number,
    required this.changesInThisVersion,
    required this.timestamp,
    required this.shouldForceTheUpgrade,
    required this.appPackage,
  });

  Build.fromJson(Map<String, dynamic> map)
      : this(
          name: map['name'].toString(),
          number: map['number'] as int,
          changesInThisVersion: map['changesInThisVersion'].toString(),
          timestamp: map['timestamp'] as int?,
          appPackage: map['appPackage'].toString(),
          shouldForceTheUpgrade: map['shouldForceTheUpgrade'] as bool,
        );
}

class BuildListItem extends StatelessWidget {
  final Build appBuild;

  const BuildListItem({Key? key, required this.appBuild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          appBuild.number.toString() + ": " + appBuild.name.toString(),
          textAlign: TextAlign.center,
        ),
        Text(appBuild.changesInThisVersion),
        appBuild.timestamp != null ? Text(DateTime.fromMillisecondsSinceEpoch(appBuild.timestamp! * 1000).toString()) : Container()
      ],
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }
}

class BuildState extends State<BuildList> {
  List<Build>? _items = <Build>[];
  bool _isLoading = false;

  @override
  void initState() {
    load();
    super.initState();
  }

  void load() {
    setState(() {
      _isLoading = true;
    });

    var uri = Uri.parse(BUILDS_LIST);
    http
        .post(uri,
            body: jsonEncode({
              "APP_VERSION": APP_VERSION,
              "APP_CHANNEL": APP_CHANNEL,
              "APP_GUID": APP_GUID,
              "PLATFORM": APP_PLATFORM,
              "lang": Trans.of(context).locale.languageCode
            }))
        .catchError((resp) {
      setState(() {
        _isLoading = false;
      });
    }).then((response) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _isLoading = false;
        });
      }
      var list = json.decode(response.body);
      setState(() {
        _isLoading = false;
        _items = list != null ? (asList(list)).map((i) => Build.fromJson(i)).toList() : [];
      });
    });
  }

  static List asList(jsonBody) {
    if (jsonBody is String) {
      return jsonDecode(jsonBody);
    } else {
      return jsonBody;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: widget.shouldForceTheUpgrade
              ? Container()
              : InkWell(
                  child: Icon(Icons.arrow_back),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
          title: Text(Trans.of(context).changes),
        ),
        body: Padding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _isLoading
                  ? CircularProgressIndicator()
                  : Container(
                      width: 0,
                      height: 0,
                    ),
              Expanded(
                  child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: _items!.length,
                itemBuilder: (BuildContext context, int index) {
                  return BuildListItem(appBuild: _items![index]);
                },
              )),
              ElevatedButton(
                onPressed: () {
                  launch1(widget.appPackage, context);
                },
                child: Text(Trans.of(context).downloadUpdate),
              )
            ],
          ),
          padding: EdgeInsets.all(16),
        ));
  }

  void launch1(String customUrl, BuildContext context) async {
    print(customUrl);
    await canLaunch(customUrl) ? await launch(customUrl) : toast(Trans.of(context).couldNotLaunch + ' $customUrl', context);
  }

  toast(String s, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(s));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
