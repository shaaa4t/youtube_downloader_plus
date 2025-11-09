
# Youtube Downloader Plus - Flutter Plugin

`youtube_downloader_plus` is a **modified version** of the original [youtube_downloader_totalxsoftware](https://pub.dev/packages/youtube_downloader_totalxsoftware) Flutter package.  
It adds **Arabic localization (`localeCode`)**, enhanced notifications, and custom download progress handling.

---

## Features

- Download YouTube videos with quality selection.
- Arabic and English localization support.
- Download video thumbnails.
- Progress notifications with customizable UI.
- Compatible with Android and iOS.

---

## Installation

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  youtube_downloader_plus: ^1.0.2
````

Then run:

```bash
flutter pub get
```

---

## Usage

### Initialize Notifications

Call the `initialize` method to set up notifications (required for Android):

```dart
await YoutubeDownloaderPlus.initialize(
  androidNotificationIcon: 'resource://drawable/notification_icon',
);
```

#### Place the Icon in Drawable Folders

Save your notification icon in the following `res/drawable` directories based on screen density:

* `res/drawable-mdpi`: For medium-density screens (1x).
* `res/drawable-hdpi`: For high-density screens (1.5x).
* `res/drawable-xhdpi`: For extra-high-density screens (2x).
* `res/drawable-xxhdpi`: For extra-extra-high-density screens (3x).
* `res/drawable-xxxhdpi`: For extra-extra-extra-high-density screens (4x).

Make sure the icon file is named consistently across all folders, for example: `notification_icon.png`.

---

## Download a YouTube Video

```dart
YoutubeDownloaderPlus().downloadYoutubeVideo(
  context: context,
  ytUrl: 'https://youtube.com/shorts/G-2INFh7hpk?si=VWfSRsTYMzX69vpK',
  error: (e) => log('Error: $e'),
  onProgress: (progress) {
    this.progress = progress;
    setState(() {});
  },
  onComplete: (file, thumbnail) {
    log('Download complete: ${file.path}');
    log('Thumbnail downloaded: ${thumbnail.path}');
  },
  onLoading: (isLoading) {
    // Handle loading state
  },
  qualityBuilderSheet: qualityBuilderSheet,
  localeCode: 'ar', // Arabic localization example
);
```

---

## Example: Bottom Sheet Implementation

Customize your video quality selection UI:

```dart
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
```

---

## Platform Requirements

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS

Ensure your `Info.plist` includes the required keys for network and storage access.

