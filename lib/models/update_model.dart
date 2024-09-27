class UpdateModel {
  final String appPackage;
  final int latestVersion;
  final bool shouldForceTheUpgrade;

  UpdateModel({
    required this.appPackage,
    required this.latestVersion,
    required this.shouldForceTheUpgrade,
  });
}
