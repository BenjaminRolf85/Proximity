/// App-wide constants for Proximity Social
class ProximityConstants {
  // Distance ranges in meters
  static const double neighborhoodRangeM = 5000; // <5km
  static const double cityRangeM = 30000; // <30km
  static const double countryRangeM = 200000; // <200km
  static const double maxDistanceM = 2000000; // 2000km max

  // Broadcast settings
  static const double broadcastRangeM = 100;
  static const Duration broadcastLifetime = Duration(seconds: 5);

  // Radar view settings
  static const double maxRadarRangeM = 30000; // 30km
  static const int maxVisibleDotsPerQuadrant = 9;
  static const double radarOuterPaddingPx = 12;
  static const double cornerButtonSizePx = 44;

  // Mock data
  static const double minMockDistanceM = 50;
  static const double maxMockDistanceM = 200000;
  static const double movementJitterM = 200;

  // Animation durations
  static const Duration dotAnimationDuration = Duration(milliseconds: 450);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 280);
  static const Duration pulseDuration = Duration(seconds: 2);

  // UI
  static const double defaultDotRadiusPx = 12;
  static const double minDotRadiusPx = 7;
  static const double avatarRadiusPx = 40;
}

