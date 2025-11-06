// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_url_validator/video_url_validator.dart';
import 'package:youtube_downloader_plus/service/get_youtube_id_from_url.dart';
import 'package:youtube_downloader_plus/service/merge_video_and_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'service/app_strings.dart';

class YoutubeDownloaderPlus {
  static final YoutubeDownloaderPlus _instance =
      YoutubeDownloaderPlus._internal();

  YoutubeDownloaderPlus._internal();

  factory YoutubeDownloaderPlus() {
    return _instance;
  }

  static bool _isDownloading = false;

  // Initialize notifications and permissions
  static Future<void> initialize({
    required String androidNotificationIcon,
  }) async {
    if (Platform.isAndroid) {
      PermissionStatus notificationPermissionStatus =
          await Permission.notification.status;
      if (!notificationPermissionStatus.isGranted) {
        await Permission.notification.request();
      }
    }

    AwesomeNotifications().initialize(
      androidNotificationIcon,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Basic notifications for the app.',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
        NotificationChannel(
          channelKey: 'download_channel',
          channelName: 'Download Progress',
          channelDescription: 'Displays download progress notifications.',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance:
              NotificationImportance.Low, // Lower importance to avoid floating
          enableVibration: false, // Disable vibration
          playSound: false, // Disable sound
          onlyAlertOnce: true, // Prevent multiple alerts for updates
        ),
      ],
    );
  }

  // Download YouTube video
  Future<void> downloadYoutubeVideo({
    required BuildContext context,
    required String ytUrl,
    required void Function(String e) error,
    required void Function(double progress) onProgress,
    required void Function(File videoFile, File thumbFile) onComplete,
    required void Function(bool isLoading) onLoading,
    required Widget Function(
            List<VideoOnlyStreamInfo>, void Function(StreamInfo) onSelected)
        qualityBuilderSheet,
    required String localeCode,
  }) async {
    if (_isDownloading) {
      error(AppStrings.get('another_download_in_progress',
          localeCode: localeCode));
      return;
    }

    _isDownloading = true;
    onLoading(true);

    try {
      // Validate YouTube URL
      if (!VideoURLValidator().validateYouTubeVideoURL(url: ytUrl)) {
        error(AppStrings.get('invalid_youtube_url', localeCode: localeCode));
        onLoading(false);
        return;
      }

      final videoId = getYoutubeIdFromUrl(ytUrl);

      // Fetch video details in a separate isolate
      final data = await _fetchVideoDetailsInBackground(videoId!);

      final video = data['video'] as Video;
      final manifest = data['manifest'] as StreamManifest;

      // Check if manifest contains video streams
      if (manifest.videoOnly.isEmpty) {
        error(AppStrings.get('no_available_video_streams',
            localeCode: localeCode));
        onLoading(false);
        return;
      }
      // Download thumbnail
      // final thumbFile = await _downloadThumbnail(video.thumbnails.highResUrl);

      // Show video quality selection
      // final selectedStream = await
      final date = await Future.wait([
        _showQualitySelection(
          context,
          videos: manifest.videoOnly,
          qualityBuilderSheet: qualityBuilderSheet,
        ),
        _downloadThumbnail(video.thumbnails.highResUrl),
      ]);
      final selectedStream = date[0] as StreamInfo?;
      final thumbFile = date[1] as File;
      if (selectedStream == null) {
        onLoading(false);
        return;
      }

      final videoUrl = selectedStream.url;
      final audioUrl = manifest.audioOnly.first.url;

      // Download and merge video & audio
      await mergeVideoAndAudio(
          videoUrl: videoUrl,
          audioUrl: audioUrl,
          totalFileDuration: video.duration!.inMilliseconds,
          error: (e) {
            error(e);
            onLoading(false);
          },
          onProgress: onProgress,
          onComplete: (videoFile) {
            _isDownloading = false;
            onComplete(videoFile, thumbFile);
            onLoading(false);
          },
          localeCode: localeCode);
    } catch (e) {
      error('${AppStrings.get('error', localeCode: localeCode)} $e');
      onLoading(false);
    } finally {
      _isDownloading = false;
    }
  }

  // Function to run in the background isolate
  Future<Map<String, dynamic>> _fetchVideoDetailsInBackground(
      String videoId) async {
    final receivePort =
        ReceivePort(); // ReceivePort to get the result from the isolate

    // Start a background isolate
    await Isolate.spawn(
      _fetchVideoDetailsIsolate,
      [videoId, receivePort.sendPort],
    );

    // Listen for the result from the isolate
    final result = await receivePort.first;
    return result as Map<String, dynamic>;
  }

  // Isolate function that does the async task and sends the result back
  static void _fetchVideoDetailsIsolate(List<dynamic> args) async {
    final videoId = args[0] as String;
    final sendPort = args[1] as SendPort;

    final yt = YoutubeExplode();
    final video = await yt.videos.get(videoId);
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    yt.close();

    // Send back the result to the main isolate
    sendPort.send({
      'video': video,
      'manifest': manifest,
    });
  }

  // Download thumbnail
  Future<File> _downloadThumbnail(String thumbUrl) async {
    final response = await http.get(Uri.parse(thumbUrl));
    final directory = await Directory.systemTemp.createTemp();
    final thumbFile = File(
        '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await thumbFile.writeAsBytes(response.bodyBytes);
    return thumbFile;
  }

  // Show quality selection bottom sheet
  static Future<StreamInfo?> _showQualitySelection(
    BuildContext context, {
    required Widget Function(
      List<VideoOnlyStreamInfo> video,
      void Function(StreamInfo) onPick,
    ) qualityBuilderSheet,
    required UnmodifiableListView<VideoOnlyStreamInfo> videos,
  }) async {
    StreamInfo? streamInfo;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        List<VideoOnlyStreamInfo> videoStreams = [];
        Set<String> seenQualityLabels = {};

        for (var element in videos) {
          if (element.container.name == 'mp4' &&
              !seenQualityLabels.contains(element.qualityLabel)) {
            videoStreams.add(element);
            seenQualityLabels.add(element.qualityLabel);
          }
        }
        return qualityBuilderSheet(
          videoStreams,
          (value) {
            streamInfo = value;
            Navigator.pop(context);
          },
        );
      },
    );
    return streamInfo;
  }
}
