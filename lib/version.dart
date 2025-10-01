/// App version
class AppVersion {
  static const String version = '0.1.0';
  static const String buildNumber = '1';
  
  static String get fullVersion => 'v$version+$buildNumber';
  static String get shortVersion => 'v$version';
}

