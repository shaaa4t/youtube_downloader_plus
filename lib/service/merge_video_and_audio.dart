import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_plus/service/notification_manager.dart';

import 'app_strings.dart';

Future<void> mergeVideoAndAudio(
    {required Uri videoUrl,
    required Uri audioUrl,
    required int totalFileDuration,
    required void Function(String e) error,
    required void Function(double progress) onProgress,
    required void Function(File file) onComplete,
    required String localeCode}) async {
  final appDir = await getApplicationDocumentsDirectory();
  final outputFilePath =
      '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

  // String ffmpegCommand = '-i $videoUrl -i $audioUrl -c copy $outputFilePath';
  String ffmpegCommand =
      '-hwaccel auto -i $videoUrl -i $audioUrl -c copy $outputFilePath';

  int? lastReportedProgress;

  await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      onComplete(File(outputFilePath));
      NotificationManager.dismissNotification(
          NotificationManager.getNotificationID(videoUrl.toString()));
    } else {
      error("Failed to merge video and audio streams.");
    }
  }, (lo) {
    // log("FFmpeg Log: ${lo.getMessage()}");
  }, (statistics) {
    final progress = //= (statistics.time * 100) ~/ totalFileDuration;
        ((statistics.getTime() * 100) ~/ totalFileDuration).clamp(0, 100);
    if (progress != lastReportedProgress) {
      lastReportedProgress = progress;
      onProgress(progress.toDouble());
    }
    NotificationManager.showProgressNotification(
        notificationID:
            NotificationManager.getNotificationID(videoUrl.toString()),
        title: AppStrings.get('downloading', localeCode: localeCode),
        progress: progress.toDouble(),
        localeCode: localeCode);
  });
}
