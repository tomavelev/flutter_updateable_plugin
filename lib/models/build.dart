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

class BuildPage {
  final List<Build> list;
  final int count;

  BuildPage({
    required this.list,
    required this.count,
  });
}
