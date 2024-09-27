import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Trans.dart';

List asList(jsonBody) {
  if (jsonBody is String) {
    return jsonDecode(jsonBody);
  } else {
    return jsonBody;
  }
}

void launchURL(String customUrl, BuildContext context) async {
  print(customUrl);
  await canLaunch(customUrl)
      ? await launch(customUrl)
      : toast(Trans.of(context).couldNotLaunch + ' $customUrl', context);
}

void toast(String s, BuildContext context) {
  SnackBar snackBar = SnackBar(content: Text(s));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Future<bool> isOnline() async {
  Connectivity connectivity = Connectivity();
  var connResult = await connectivity.checkConnectivity();
  return connResult != ConnectivityResult.none;
}

void startNewProcess(List<String> processToStart) {
  String process = processToStart[0];
  var args = <String>[];
  for (int i = 1; i < processToStart!.length; i++) {
    args.add(processToStart![i]);
  }
  Process.start(
    process,
    args,
    runInShell: true,
    mode: ProcessStartMode.detached, //all the magic is here
  ).then((value) {
    exit(0);
  });
}
