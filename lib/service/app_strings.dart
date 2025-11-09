class AppStrings {
  // You should set this when your app's locale changes (e.g., in main or a state management solution)
  // static String currentLocale = 'en';

  static const Map<String, Map<String, String>> _localized = {
    'en': {
      // Notification Manager Texts
      'downloading': 'Downloading...',
      'progress': 'Progress:',
      // YoutubeDownloaderTotalxsoftware Texts
      'another_download_in_progress':
          'Another download is already in progress.',
      'invalid_youtube_url': 'Invalid YouTube URL',
      'no_available_video_streams': 'No available video streams',
      'error': 'Error:',
    },
    'ar': {
      // Notification Manager Texts
      'downloading': 'جاري التحميل...',
      'progress': 'التقدم:',
      // YoutubeDownloaderTotalxsoftware Texts
      'another_download_in_progress': 'عملية تحميل أخرى جارية بالفعل.',
      'invalid_youtube_url': 'رابط يوتيوب غير صالح',
      'no_available_video_streams': 'لا توجد تدفقات فيديو متاحة',
      'error': 'خطأ:',
    },
    'merging': {
      'en': 'Merging video...',
      'ar': 'دمج الفيديو...',
    },
    'download_complete': {
      'en': 'Download Complete',
      'ar': 'اكتمل التنزيل',
    },
    'video_ready': {
      'en': 'Your video is ready!',
      'ar': 'الفيديو جاهز!',
    },
  };

  static String get(String key, {required String localeCode}) =>
      _localized[localeCode]?[key] ?? key;
}
