import 'package:flutter/material.dart';

class NearbyNotificationService {
  static void sendPing(BuildContext context, String toName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sent: \"I'm nearby\" to $toName")),
    );
  }

  static void showBroadcastReceived(BuildContext context, String text, String fromName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📡 Broadcast from $fromName: $text'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showMessageReceived(BuildContext context, String text, String fromName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💬 Message from $fromName: $text'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Navigate to chat
          },
        ),
      ),
    );
  }
}


