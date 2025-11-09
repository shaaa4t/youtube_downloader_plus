import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_strings.dart';

class NotificationManager {
  static final Map<String, int> _downloadTasks = {};
  static final Map<int, double> _lastProgress = {};
  static int _nextNotificationID = 1000;

  static int getNotificationID(String videoUrl) {
    if (_downloadTasks.containsKey(videoUrl)) {
      return _downloadTasks[videoUrl]!;
    }
    _downloadTasks[videoUrl] = _nextNotificationID++;
    return _downloadTasks[videoUrl]!;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> showProgressNotification({
    required int notificationID,
    required String title,
    required double progress,
    required String localeCode,
  }) async {
    // Only update if progress changed significantly (5%)
    if (_lastProgress.containsKey(notificationID)) {
      final diff = (progress - _lastProgress[notificationID]!).abs();
      if (diff < 5.0 && progress < 100) {
        return; // Skip update
      }
    }

    _lastProgress[notificationID] = progress;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationID,
        channelKey: 'download_channel',
        title: title,
        body:
            '${AppStrings.get('progress', localeCode: localeCode)} ${progress.toInt()}%',
        progress: progress,
        notificationLayout: NotificationLayout.ProgressBar,
        locked: true, // Prevent dismissal
        autoDismissible: false,
      ),
    );
  }

  static Future<void> showCompletionNotification({
    required int notificationID,
    required String title,
    required String body,
    required String localeCode,
  }) async {
    _lastProgress.remove(notificationID);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationID,
        channelKey: 'basic_channel', // Use basic_channel for completion
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        locked: false,
        autoDismissible: true,
      ),
    );
  }

  static Future<void> dismissNotification(int notificationID) async {
    await AwesomeNotifications().dismiss(notificationID);
    _lastProgress.remove(notificationID);
  }

  static void clearTask(String videoUrl) {
    final notificationID = _downloadTasks[videoUrl];
    if (notificationID != null) {
      _lastProgress.remove(notificationID);
    }
    _downloadTasks.remove(videoUrl);
  }
}
