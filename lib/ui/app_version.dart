import 'package:flutter/material.dart';

class AppVersion extends StatelessWidget {
  final int version;
  final String versionStr;

  const AppVersion({
    Key? key,
    required this.version,
    required this.versionStr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Text("${versionStr} ${version}");
}
