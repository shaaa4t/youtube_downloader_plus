import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_plus/service/notification_manager.dart';
import 'package:http/http.dart' as http;

import 'app_strings.dart';

Future<void> mergeVideoAndAudio({
  required Uri videoUrl,
  required Uri audioUrl,
  required int totalFileDuration,
  required void Function(String e) error,
  required void Function(double progress) onProgress,
  required void Function(File file) onComplete,
  required String localeCode,
}) async {
  String? videoTempPath;
  String? audioTempPath;

  try {
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final tempDir = Directory('${appDir.path}/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    final notificationID =
        NotificationManager.getNotificationID(videoUrl.toString());

    // Show initial notification
    await NotificationManager.showProgressNotification(
      notificationID: notificationID,
      title: AppStrings.get('downloading', localeCode: localeCode),
      progress: 0,
      localeCode: localeCode,
    );

    print('📥 Downloading video from: $videoUrl');
    videoTempPath = '${tempDir.path}/video_$timestamp.mp4';
    int lastVideoProgress = -1;

    await _downloadFile(videoUrl.toString(), videoTempPath, (p) {
      final currentProgress = p.toInt();
      if (currentProgress != lastVideoProgress && currentProgress % 5 == 0) {
        lastVideoProgress = currentProgress;
        final totalProgress = p * 0.4; // 0-40% for video
        onProgress(totalProgress);
        NotificationManager.showProgressNotification(
          notificationID: notificationID,
          title: AppStrings.get('downloading', localeCode: localeCode),
          progress: totalProgress,
          localeCode: localeCode,
        );
      }
    });

    print('📥 Downloading audio from: $audioUrl');
    audioTempPath = '${tempDir.path}/audio_$timestamp.m4a';
    int lastAudioProgress = -1;

    await _downloadFile(audioUrl.toString(), audioTempPath, (p) {
      final currentProgress = p.toInt();
      if (currentProgress != lastAudioProgress && currentProgress % 5 == 0) {
        lastAudioProgress = currentProgress;
        final totalProgress = 40 + (p * 0.1); // 40-50% for audio
        onProgress(totalProgress);
        NotificationManager.showProgressNotification(
          notificationID: notificationID,
          title: AppStrings.get('downloading', localeCode: localeCode),
          progress: totalProgress,
          localeCode: localeCode,
        );
      }
    });

    final outputFilePath = '${appDir.path}/merged_video_$timestamp.mp4';

    print('🔧 Starting FFmpeg merge...');

    // Update notification for merging stage
    await NotificationManager.showProgressNotification(
      notificationID: notificationID,
      title:
          AppStrings.get('downloading', localeCode: localeCode), // Or 'merging'
      progress: 50,
      localeCode: localeCode,
    );

    String ffmpegCommand =
        '-i "$videoTempPath" -i "$audioTempPath" -c:v copy -c:a aac -strict experimental "$outputFilePath"';

    int lastReportedProgress = -1;
    bool isCompleted = false;

    await FFmpegKit.executeAsync(
      ffmpegCommand,
      (session) async {
        if (isCompleted) return;
        isCompleted = true;

        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final outputFile = File(outputFilePath);
          if (await outputFile.exists()) {
            final fileSize = await outputFile.length();
            print('✅ Output file size: ${fileSize} bytes');

            if (fileSize > 0) {
              onProgress(100.0);

              // Show completion notification - IMPORTANT: Different channel
              await NotificationManager.showCompletionNotification(
                notificationID: notificationID,
                title: AppStrings.get('downloading', localeCode: localeCode),
                body:
                    AppStrings.get('download_complete', localeCode: localeCode),
                localeCode: localeCode,
              );

              onComplete(outputFile);

              // Cleanup temp files
              await _cleanupFile(videoTempPath!);
              await _cleanupFile(audioTempPath!);

              // Clear task AFTER a delay to keep notification visible
              Future.delayed(Duration(seconds: 3), () {
                NotificationManager.clearTask(videoUrl.toString());
              });
            } else {
              error("Merged file is empty");
              await NotificationManager.dismissNotification(notificationID);
              await _cleanupFile(outputFilePath);
            }
          } else {
            error("Output file not found");
            await NotificationManager.dismissNotification(notificationID);
          }
        } else {
          final output = await session.getOutput();
          print('❌ FFmpeg failed: $output');

          error("Failed to merge");
          await NotificationManager.dismissNotification(notificationID);
          await _cleanupFile(outputFilePath);
        }

        // Cleanup temp files
        if (videoTempPath != null) await _cleanupFile(videoTempPath);
        if (audioTempPath != null) await _cleanupFile(audioTempPath);
      },
      (log) {
        // Optional: log messages
      },
      (statistics) {
        if (isCompleted) return;

        final timeInMilliseconds = statistics.getTime();
        if (timeInMilliseconds > 0 && totalFileDuration > 0) {
          final mergeProgress = ((timeInMilliseconds / totalFileDuration) * 100)
              .clamp(0, 100)
              .toInt();
          final totalProgress = 50 + (mergeProgress * 0.5);

          // Update only every 5%
          if (totalProgress.toInt() != lastReportedProgress &&
              totalProgress.toInt() % 5 == 0) {
            lastReportedProgress = totalProgress.toInt();
            onProgress(totalProgress);

            NotificationManager.showProgressNotification(
              notificationID: notificationID,
              title: AppStrings.get('downloading', localeCode: localeCode),
              progress: totalProgress,
              localeCode: localeCode,
            );
          }
        }
      },
    );
  } catch (e, stackTrace) {
    print('❌ Exception during merge: $e');
    print('Stack trace: $stackTrace');
    error("Error during merge: $e");

    final notificationID =
        NotificationManager.getNotificationID(videoUrl.toString());
    await NotificationManager.dismissNotification(notificationID);

    if (videoTempPath != null) await _cleanupFile(videoTempPath);
    if (audioTempPath != null) await _cleanupFile(audioTempPath);
  }
}

Future<void> _downloadFile(
  String url,
  String savePath,
  void Function(double progress) onProgress,
) async {
  final client = http.Client();
  try {
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    final file = File(savePath);
    final sink = file.openWrite();

    int downloaded = 0;

    await for (var chunk in response.stream) {
      sink.add(chunk);
      downloaded += chunk.length;

      if (contentLength > 0) {
        final progress = ((downloaded / contentLength * 100)).clamp(0.0, 100.0);
        onProgress(progress);
      }
    }

    await sink.close();
    print('✅ Downloaded: $savePath (${downloaded} bytes)');
  } finally {
    client.close();
  }
}

Future<void> _cleanupFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      print('🗑️ Cleaned up: $filePath');
    }
  } catch (e) {
    print("Failed to cleanup file $filePath: $e");
  }
}
