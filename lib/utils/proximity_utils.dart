import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/group.dart';

/// Get the proximity icon based on distance in meters
IconData getProximityIcon(double distanceMeters) {
  if (distanceMeters < ProximityConstants.neighborhoodRangeM) {
    return Icons.house_outlined;
  }
  if (distanceMeters < ProximityConstants.cityRangeM) {
    return Icons.location_city_outlined;
  }
  if (distanceMeters < ProximityConstants.countryRangeM) {
    return Icons.flag_outlined;
  }
  return Icons.all_inclusive;
}

/// Get the bucket index (quadrant) for a given distance
int getBucketForDistance(double meters) {
  if (meters < ProximityConstants.neighborhoodRangeM) return 0; // Neighborhood
  if (meters < ProximityConstants.cityRangeM) return 1; // City
  if (meters < ProximityConstants.countryRangeM) return 2; // Country
  return 3; // All/Extras
}

/// Get the icon for a group type
IconData getGroupIcon(GroupType type) {
  switch (type) {
    case GroupType.friends:
      return Icons.favorite_outline;
    case GroupType.business:
      return Icons.work_outline;
    case GroupType.custom:
      return Icons.tag;
  }
}

/// Show a text input dialog
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

