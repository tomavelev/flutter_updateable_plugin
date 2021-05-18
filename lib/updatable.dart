library updatable;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:url_launcher/url_launcher.dart';
import 'Trans.dart';

class Updatable extends StatefulWidget {
  final Widget? child;
  final int appCurrentVersion;
  final String channel;
  final String appGuid;
  final String appPlatform;
  final String buildsList;
  final String updateHost;
  final List<String>? processToStart;

  Updatable({Key? key, this.child, required this.appCurrentVersion, required this.updateHost, required this.channel, required this.appPlatform, required this.buildsList, this.processToStart, required this.appGuid}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UpdatableState();
  }
}

class UpdatableState extends State<Updatable> {
  var isCurrentVersion = true;
  var loading = false;
  var shouldForceTheUpgrade = false;
  int latestVersion = -1;

  String? versionURL;

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Column( crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        loading ? Text(Trans.of(context).checkingForNewVersion) : Container(),
        isCurrentVersion
            ? Container()
            : ElevatedButton(
                onPressed: () {
                  viewNewVersion();
                },
                child: Text(
                  "${Trans.of(context).newVersionIsAvailable} (${widget.appCurrentVersion} => $latestVersion)",
                  style: TextStyle(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
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
              : widget.processToStart != null && widget.processToStart!.length > 0
                  ? startApp()
                  : showChild(context),
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
          return BuildList(shouldForceTheUpgrade: shouldForceTheUpgrade, updatable: this.widget, updateUrl: versionURL!);
        },
        fullscreenDialog: true));
  }

  void doLoad() {
    var uri = Uri.parse(widget.updateHost);
    int appCurrentVersion = widget.appCurrentVersion;
    String channel = widget.channel;
    String appPlatform = widget.appPlatform;
    String appGuid = widget.appGuid;
    http
        .post(uri,
            body: jsonEncode({
              "APP_VERSION": appCurrentVersion,
              "APP_CHANNEL": channel,
              "APP_GUID": appGuid,
              "PLATFORM": appPlatform,
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
          isCurrentVersion = latestVersion <= widget.appCurrentVersion;
          shouldForceTheUpgrade = result['shouldForceTheUpgrade'];
        }
      });
    });
  }

  Widget showChild(BuildContext context) {
    return widget.child != null ? widget.child! : Container();
  }

  Widget startApp() {
    return TextButton(
      child: Text("Start"),
      onPressed: start,
    );
  }

  void start() {
    if (widget.processToStart != null && widget.processToStart!.length > 0) {
      String process = widget.processToStart![0];
      var args = <String>[];
      for (int i = 1; i < widget.processToStart!.length; i++) {
        args.add(widget.processToStart![i]);
      }
      Process.start(
        process,
        args,
        runInShell: true,
        mode: ProcessStartMode.detached, //all the magic is here
      ).then((value) {
        exit(0);
      });
    } else {
      SnackBar snackBar = SnackBar(content: Text("Not enough parameters for App Start"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

class BuildList extends StatefulWidget {
  final bool shouldForceTheUpgrade;
  final Updatable updatable;
  final String updateUrl;

  const BuildList({Key? key, required this.shouldForceTheUpgrade, required this.updatable, required this.updateUrl}) : super(key: key);

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

    var uri = Uri.parse(widget.updatable.buildsList);
    http
        .post(uri,
            body:
                jsonEncode({"APP_VERSION": widget.updatable.appCurrentVersion, "APP_CHANNEL": widget.updatable.channel,
                  "APP_GUID": widget.updatable.appGuid, "PLATFORM": widget.updatable.appPlatform, "lang": Trans.of(context).locale.languageCode}))
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
                  launch1(widget.updateUrl, context);
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
