library updatable;

import 'package:flutter/material.dart';
import 'package:updatable/data_sources/app_distribution_dao.dart';
import '../Trans.dart';
import '../data_sources/utils.dart';
import 'build_list.dart';

class Updatable extends StatefulWidget {
  final Widget? child;
  final bool? checkOnlyOnce;
  final int appCurrentVersion;
  final String channel;
  final String appGuid;
  final String appPlatform;
  final String? buildsList;
  final String updateHost;
  final List<String>? processToStart;

  Updatable({
    Key? key,
    this.child,
    required this.appCurrentVersion,
    required this.updateHost,
    required this.channel,
    required this.appPlatform,
    this.buildsList,
    this.processToStart,
    required this.appGuid,
    this.checkOnlyOnce = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UpdatableState();
  }
}

class UpdatableState extends State<Updatable> {
  static var checkDone = false;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        loading ? Text(Trans.of(context).checkingForNewVersion) : Container(),
        isCurrentVersion || versionURL == null
            ? Container()
            : ElevatedButton(
                onPressed: () => _viewNewVersion(),
                child: Text(
                  "${Trans.of(context).newVersionIsAvailable} (${widget.appCurrentVersion} => $latestVersion)",
                  style: TextStyle(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
              ),
        Expanded(
          child:
              !isCurrentVersion && shouldForceTheUpgrade && versionURL != null
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Text(Trans.of(context).pleaseUpdateNow),
                          ElevatedButton(
                              onPressed: () => _viewNewVersion(),
                              child: Center(
                                  child: Text(
                                Trans.of(context).updateNow,
                              )))
                        ]))
                  : widget.processToStart != null &&
                          widget.processToStart!.length > 0
                      ? startApp()
                      : showChild(context),
        )
      ],
    );
  }

  void loadVersion() {
    if (widget.checkOnlyOnce! && checkDone) {
      return;
    }
    isOnline().then((isOnline) {
      setState(() {
        if (isOnline) {
          loading = true;
          isCurrentVersion = true;
          shouldForceTheUpgrade = false;
          _doLoad();
        } else {
          loading = false;
          isCurrentVersion = true;
          shouldForceTheUpgrade = false;
        }
      });
    });
  }

  Future<void> _viewNewVersion() async {
    if (versionURL != null) {
      if (widget.buildsList == null) {
        launchURL(versionURL!, context);
      } else {
        Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) => BuildList(
                shouldForceTheUpgrade: shouldForceTheUpgrade,
                updatable: this.widget,
                updateUrl: versionURL!),
            fullscreenDialog: true));
      }
    }
  }

  void _doLoad() {
    AppDistributionDao.getUpdateModel(
      appGuid: widget.appGuid,
      appPlatform: widget.appPlatform,
      appVersion: widget.appCurrentVersion,
      channel: widget.channel,
      updateHostIntEndpoint: widget.updateHost,
    ).then((result) {
      setState(() {
        loading = false;
        versionURL = result.appPackage;
        latestVersion = result.latestVersion;
        isCurrentVersion = latestVersion <= widget.appCurrentVersion;
        shouldForceTheUpgrade = result.shouldForceTheUpgrade;
      });
    }).onError((error, stackTrace) {
      setState(() {
        checkDone = true;
        loading = false;
        isCurrentVersion = true;
        shouldForceTheUpgrade = false;
      });
    });
  }

  Widget showChild(BuildContext context) {
    return widget.child != null ? widget.child! : Container();
  }

  Widget startApp() => TextButton(
        child: Text("Start"),
        onPressed: start,
      );

  void start() {
    if (widget.processToStart != null && widget.processToStart!.length > 0) {
      startNewProcess(widget.processToStart!);
    } else {
      SnackBar snackBar =
          SnackBar(content: Text("Not enough parameters for App Start"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
