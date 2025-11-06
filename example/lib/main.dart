import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_downloader_plus/youtube_downloader_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await YoutubeDownloaderTotalxsoftware.initialize(
    androidNotificationIcon: 'resource://drawable/ic_launcher',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  double progress = 0;
  String? downloadFilePath;
  VideoPlayerController? _videoController;
  final TextEditingController _youtubeUrlController = TextEditingController(
    text: 'https://youtube.com/shorts/G-2INFh7hpk?si=VWfSRsTYMzX69vpK',
  );

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  void _playDownloadedVideo(String filePath) {
    _videoController = VideoPlayerController.file(File(filePath))
      ..initialize().then((_) {
        setState(() {});
        _videoController?.play();
      });
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController?.pause();
    } else {
      _videoController?.play();
    }
    setState(() {});
  }

  void _startDownload() {
    final youtubeUrl = _youtubeUrlController.text.trim();
    if (youtubeUrl.isEmpty) {
      log('Error: No YouTube URL provided.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube URL.')),
      );
      return;
    }

    YoutubeDownloaderTotalxsoftware().downloadYoutubeVideo(
      context: context,
      ytUrl: youtubeUrl,
      error: (e) => log('Error: $e'),
      onProgress: (progress) {
        this.progress = progress;
        setState(() {});
      },
      onComplete: (file, thumbnail) {
        log('Download complete: ${file.path}');
        log('Download complete thumbnail: ${thumbnail.path}');
        downloadFilePath = file.path;
        _playDownloadedVideo(file.path);
        setState(() {});
      },
      onLoading: (isLoading) {
        this.isLoading = isLoading;
        setState(() {});
      },
      qualityBuilderSheet: qualityBuilderSheet,
      localeCode: 'ar',
    );
  }

  void _clearVideo() {
    _videoController?.dispose();
    _videoController = null;
    downloadFilePath = null;
    progress = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _youtubeUrlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _startDownload,
              child: isLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                    )
                  : const Text('Download Video'),
            ),
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                ),
              ),
            const SizedBox(height: 16),
            if (downloadFilePath != null)
              Column(
                children: [
                  Text('Downloaded to: $downloadFilePath'),
                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: _clearVideo,
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Widget qualityBuilderSheet(videos, onSelected) {
  return Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Download quality',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var video in videos)
          ListTile(
            onTap: () => onSelected(video),
            title: Text(
              video.qualityLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            trailing: Text(
              '${video.size}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
