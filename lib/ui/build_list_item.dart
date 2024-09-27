import 'package:flutter/widgets.dart';

import '../models/build.dart';

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
        appBuild.timestamp != null
            ? Text(
                DateTime.fromMillisecondsSinceEpoch(appBuild.timestamp! * 1000)
                    .toString())
            : Container()
      ],
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }
}
