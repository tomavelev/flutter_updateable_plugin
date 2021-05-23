# updatable

A Flutter Plugin to make an App Update-able

I've made this plugin to make easier integrating update functionality in my flutter apps. 

On this address you could find an administrative interface for uploading versions: 
https://programtom.com/app_distribution/

What a new App that wants to use it require is - adding the dependency: 

```yaml
 updatable:
 
     git: https://github.com/tomavelev/flutter_updateable_plugin.git

```
Include a constants.dart file:

//this should be application specific. Use it in your own app
```dart

const APP_VERSION = 2;// an integer

const APP_CHANNEL = "Stable"; // String specifying the distribution target 

const APP_GUID = "appGuid1123324"; // a String identifying your app

const UPDATE_HOST = "https://programtom.com/app_distribution/checkForNewVersion.php"; // the place to check for availability of new version. 

const BUILDS_LIST = "https://programtom.com/app_distribution/buildsList.php"; // list of changes between the current app version and the available new versions

const APP_PLATFORM = "Windows"; // Target Platform -  "Windows" | "Android" | "MacOS" | "Linux" | "WebApp" | "iOS"
```

//and use it like this:
```dart
import 'constants.dart';

import 'package:updatable/updatable.dart';
```
//If your app is an external process:
```dart
Updatable(
          
          appCurrentVersion: APP_VERSION,
          
          appPlatform: APP_PLATFORM,
          
          buildsList: BUILDS_LIST,
          
          channel: APP_CHANNEL,
          
          updateHost: UPDATE_HOST,
          
          processToStart: ['java', '-jar', "myJar.jar"],
          
          appGuid: APP_GUID,
          
        )

//Or if your app is a flutter app

Updatable(

          appCurrentVersion: APP_VERSION,
          
          appPlatform: APP_PLATFORM,
          
          buildsList: BUILDS_LIST,
          
          channel: APP_CHANNEL,
          
          updateHost: UPDATE_HOST,
          
          child: yourAppContent(),
          
          appGuid: APP_GUID,
          
        )
```

I've also exposed all functionality with parameters, so you could integrate your own backend and never depend on my Platform.

The checkForNewVersion URL is: 

Post Request containing a JSON Object :
```json
{
              "APP_VERSION": appCurrentVersion,
              "APP_CHANNEL": channel,
              "APP_GUID": appGuid,
              "PLATFORM": appPlatform,
}
```
and ideally will return JSON Object with:
 ```json
{
"appPackage" :"https://....",
"latestVersion": 3,
"shouldForceTheUpgrade": false

```
The buildsList URL is POST Request with JSON:                   

```json
{
              "APP_VERSION": appCurrentVersion,
              "APP_CHANNEL": channel,
              "APP_GUID": appGuid,
              "PLATFORM": appPlatform,
              "lang": "en"
}
```
and should return list of objects with the fields: 

 ```dart
  name: map['name'].toString(),
          number: map['number'] as int,
          changesInThisVersion: map['changesInThisVersion'].toString(),
          timestamp: map['timestamp'] as int?,
          appPackage: map['appPackage'].toString(),
          shouldForceTheUpgrade: map['shouldForceTheUpgrade'] as bool,                  
```
