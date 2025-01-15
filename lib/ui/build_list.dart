import 'package:flutter/material.dart';
import 'package:updatable/ui/build_list_item.dart';

import '../Trans.dart';
import '../data_sources/app_distribution_dao.dart';
import '../data_sources/utils.dart';
import '../models/build.dart';
import 'updatable.dart';

class BuildList extends StatefulWidget {
  final bool shouldForceTheUpgrade;
  final Updatable updatable;
  final String updateUrl;

  const BuildList({
    Key? key,
    required this.shouldForceTheUpgrade,
    required this.updatable,
    required this.updateUrl,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BuildState();
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
    AppDistributionDao.loadBuildsPage(
      buildsList: widget.updatable.buildsList!,
      appGuid: widget.updatable.appGuid,
      appPlatform: widget.updatable.appPlatform,
      appVersion: widget.updatable.appCurrentVersion,
      channel: widget.updatable.channel,
      lang: Trans.of(context).locale.languageCode,
    ).then((response) {
      setState(() {
        _isLoading = false;
        //TODO introduce paging
        _items = response.list;
      });
    }).onError((e, stack) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        leading: widget.shouldForceTheUpgrade
            ? Container()
            : InkWell(
                child: Icon(Icons.arrow_back),
                onTap: () => Navigator.of(context).pop(),
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
              onPressed: () => launchURL(widget.updateUrl, context),
              child: Text(Trans.of(context).downloadUpdate),
            )
          ],
        ),
        padding: EdgeInsets.all(16),
      ));
}
