# Youtube Downloader Totalxsoftware Plus - Flutter Plugin

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
  youtube_downloader_plus: ^1.0.0
```

Then run:

```bash
flutter pub get

```

## Usage

### Initialize Notifications

Call the `initialize` method to set up notifications (required for Android):

```dart

await YoutubeDownloaderTotalxsoftware.initialize(
  androidNotificationIcon: 'resource://drawable/notification_icon',
);

```

#### Place the Icon in Drawable Folders

Save your notification icon in the following `res/drawable` directories based on screen density:

- `res/drawable-mdpi`: For medium-density screens (1x).
- `res/drawable-hdpi`: For high-density screens (1.5x).
- `res/drawable-xhdpi`: For extra-high-density screens (2x).
- `res/drawable-xxhdpi`: For extra-extra-high-density screens (3x).
- `res/drawable-xxxhdpi`: For extra-extra-extra-high-density screens (4x).

Make sure the icon file is named consistently across all folders, for example: `notification_icon.png.`

---

## Download a YouTube Video

```dart
 YoutubeDownloaderTotalxsoftware().downloadYoutubeVideo(
      context: context,
      ytUrl: 'https://youtube.com/shorts/G-2INFh7hpk?si=VWfSRsTYMzX69vpK',
      error: (e) => log('Error: $e'),
      onProgress: (progress) {
        this.progress = progress;
        setState(() {});
      },
      onComplete: (file,thumbnail) {
        log('Download complete: ${file.path}');
        log('Download complete thumbnail: ${thumbnail.path}');

      },
      onLoading: (isLoading) {
        // Loading

      },
      qualityBuilderSheet: qualityBuilderSheet,
    );
```
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
- Add the following permissions to your `AndroidManifest.xml`:

```xml 
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## iOS

Ensure your `Info.plist` includes the required keys for network and storage access.



## Explore more about TotalX at www.totalx.in - Your trusted software development company!





<div style="display: flex; gap: 20px; justify-content: center; align-items: center; margin-top: 15px;"> <a href="https://www.youtube.com/channel/UCWysKlrrg4_a3W4Usw5MYKw" target="_blank"> <img src="https://cdn-icons-png.flaticon.com/512/1384/1384060.png" alt="YouTube" width="60" height="60"> <p style="text-align: center;">YouTube</p> </a> <a href="https://x.com/i/flow/login?redirect_after_login=%2FTOTALXsoftware" target="_blank"> <img src="https://cdn-icons-png.flaticon.com/512/733/733579.png" alt="X (Twitter)" width="60" height="60"> <p style="text-align: center;">Twitter</p> </a> <a href="https://www.instagram.com/totalx.in/" target="_blank"> <img src="https://cdn-icons-png.flaticon.com/512/1384/1384063.png" alt="Instagram" width="60" height="60"> <p style="text-align: center;">Instagram</p> </a> <a href="https://www.linkedin.com/company/total-x-softwares/" target="_blank"> <img src="https://cdn-icons-png.flaticon.com/512/145/145807.png" alt="LinkedIn" width="60" height="60"> <p style="text-align: center;">LinkedIn</p> </a> </div>

## 🌐 Connect with Totalx Software

Join the vibrant Flutter Firebase Kerala community for updates, discussions, and support:

<a href="https://t.me/Flutter_Firebase_Kerala" target="_blank" style="text-decoration: none;"> <img src="https://cdn-icons-png.flaticon.com/512/2111/2111646.png" alt="Telegram" width="90" height="90"> <p><b>Flutter Firebase Kerala Totax</b></p> </a>

