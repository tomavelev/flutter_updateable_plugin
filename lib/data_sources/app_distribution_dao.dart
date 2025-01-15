import 'dart:convert';

import 'package:updatable/models/update_model.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import '../models/build.dart';

class AppDistributionDao {
  static Future<UpdateModel> getUpdateModel({
    required String updateHostIntEndpoint,
    required int appVersion,
    required String appGuid,
    required String channel,
    required String appPlatform,
  }) async {
    var uri = Uri.parse(updateHostIntEndpoint);
    var response = await http.get(uri);
    var responseData = jsonDecode(response.body);
    return UpdateModel(
      appPackage: responseData['appPackage'],
      latestVersion: responseData['latestVersion'],
      shouldForceTheUpgrade: responseData['shouldForceTheUpgrade'],
    );
  }

  static Future<List<Build>> loadBuildsList({
    required String buildsList,
    required String appGuid,
    required String appPlatform,
    required int appVersion,
    required String channel,
    required String lang,
  }) async {
    var uri = Uri.parse(buildsList!);

    var response = await http.post(uri,
        body: jsonEncode({
          "APP_VERSION": appVersion,
          "APP_CHANNEL": channel,
          "APP_GUID": appGuid,
          "PLATFORM": appPlatform,
          "lang": lang,
        }));

    var list = json.decode(response.body);
    return (asList(list)).map((i) => Build.fromJson(i)).toList();
  }

  static Future<BuildPage> loadBuildsPage({
    required String buildsList,
    required String appGuid,
    required String appPlatform,
    required int appVersion,
    required String channel,
    required String lang,
  }) async {
    var uri = Uri.parse(buildsList!);

    var response = await http.post(uri,
        body: jsonEncode({
          "APP_VERSION": appVersion,
          "APP_CHANNEL": channel,
          "APP_GUID": appGuid,
          "PLATFORM": appPlatform,
          "lang": lang,
        }));

    var page = json.decode(response.body);
    var list = (asList(page['list'])).map((i) => Build.fromJson(i)).toList();
    var count = page['count'];
    return BuildPage(list: list, count: count);
  }
}
