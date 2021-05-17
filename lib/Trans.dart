import 'package:flutter/cupertino.dart';

class Trans {
  static final Trans _singleton = Trans._internal(Locale("en"));

  Locale locale;

  factory Trans() {
    return _singleton;
  }

  Trans._internal(this.locale);

  String get checkingForNewVersion => _localizedValues[locale.languageCode]!['checkingForNewVersion']!;

  String get newVersionIsAvailable => _localizedValues[locale.languageCode]!['newVersionIsAvailable']!;

  String get pleaseUpdateNow => _localizedValues[locale.languageCode]!['pleaseUpdateNow']!;

  String get updateNow => _localizedValues[locale.languageCode]!['updateNow']!;

  String get changes => _localizedValues[locale.languageCode]!['changes']!;

  String get downloadUpdate => _localizedValues[locale.languageCode]!['downloadUpdate']!;

  String get couldNotLaunch => _localizedValues[locale.languageCode]!['couldNotLaunch']!;

  static Trans of(BuildContext context) {
    //Change locale from System, App Preferences or other variables.
    return _singleton;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      "newVersionIsAvailable": "New Version is Available",
      "checkingForNewVersion": "Checking for new Version ...",
      "pleaseUpdateNow": "Please, Update your App, Now!",
      "updateNow": "Update Now",
      "changes": "Changes",
      "couldNotLaunch": "Could not launch",
      "downloadUpdate": "Download Update"
    }
  };
}
