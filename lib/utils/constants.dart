class Constants {
  // App
  static const String appName = 'Telvo';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'https://api.telvo.app';
  static const int apiTimeoutSeconds = 30;

  // Auth
  static const int otpLength = 6;
  static const int otpResendTimeout = 60; // seconds
  static const int maxLoginAttempts = 5;

  // User
  static const int maxPhotosPerJob = 10;
  static const int maxPhotosPerReview = 5;
  static const int maxPortfolioPhotos = 20;
  static const int maxSkills = 20;
  static const int maxServiceAreas = 10;

  // Location
  static const double defaultLatitude = 3.8480;
  static const double defaultLongitude = 11.5021;
  static const int maxSearchRadiusKm = 50;

  // Pagination
  static const int itemsPerPage = 20;
  static const int itemsPerPageSmall = 10;

  // Chat
  static const int maxMessageLength = 5000;
  static const int maxAttachmentSizeMB = 10;
  static const List<String> allowedFileTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'mp4',
    'mov',
    'pdf',
    'doc',
    'docx',
  ];

  // Cache
  static const int cacheExpiryDays = 30;
  static const int cacheMaxSizeMB = 50;

  // Notification
  static const String notificationChannelId = 'telvo_channel';
  static const String notificationChannelName = 'Telvo Notifications';
  static const String notificationChannelDescription =
      'Notifications from Telvo';

  // Deep Links
  static const String deepLinkScheme = 'telvo';
  static const String deepLinkHost = 'app.telvo.com';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String timeFormat = 'HH:mm';

  // RegEx
  static const String phoneRegex = r'^\+?[0-9]{8,15}$';
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String passwordRegex = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$';

  // Currencies
  static const List<String> supportedCurrencies = ['XAF', 'USD', 'EUR', 'GBP'];
  static const Map<String, String> currencySymbols = {
    'XAF': 'FCFA',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  // Languages
  static const List<String> supportedLanguages = ['en', 'fr', 'pt', 'es'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'French',
    'pt': 'Portuguese',
    'es': 'Spanish',
  };

  // Categories
  static const List<String> categories = [
    'Plumber',
    'Electrician',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Mechanic',
    'Gardener',
    'Tutor',
    'Photographer',
    'Chef',
    'Babysitter',
    'Nanny',
    'Caregiver',
    'Driver',
    'Security Guard',
    'Mason',
    'Welder',
    'Interior Designer',
    'Event Planner',
    'DJ',
    'MC',
    'Decorator',
  ];

  // Job Status
  static const List<String> jobStatuses = [
    'posted',
    'notified',
    'quotes_received',
    'quotes_expired',
    'accepted',
    'rejected',
    'on_the_way',
    'completed',
    'cancelled',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'momo',
    'orange',
    'card',
    'escrow',
  ];

  // Urgency Levels
  static const List<String> urgencyLevels = [
    'emergency',
    'today',
    'tomorrow',
    'flexible',
  ];
}
