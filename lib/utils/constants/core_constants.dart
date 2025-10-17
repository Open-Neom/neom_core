
class CoreConstants {

  static const String appBank = 'appBank';
  static const String firstChamberPreset = "firstChamberPreset";
  static const String customPreset = "customPreset";

  static const String search = "search";
  static const String updateProfileType = "updateProfileType";
  static const String updateProfileTypeSuccess = "updateProfileTypeSuccess";
  static const String errorSigningOut = "errorSigningOut";
  static const String somewhereUniverse = "somewhereUniverse";
  static const String errorCreatingAccount = "errorCreatingAccount";
  static const String errorRetrievingProfiles = "errorRetrievingProfiles";
  static const String updatePhone = "updatePhone";
  static const String phoneNotAvailable = "phoneNotAvailable";
  static const String myFavorites = "myFavorites";

  static const String prevVersion1 = "prevVersion1";
  static const String prevVersion2 = "prevVersion2";
  static const String prevVersion3 = "prevVersion3";
  static const String prevVersion4 = "prevVersion4";

  static const int profilePostsLimit = 15;
  static const int timelineLimit = 25;
  static const int nextTimelineLimit = 15;
  static const int recentTimelineLimit = 10;
  static const int diverseTimelineLimit = 6;
  static const int activityFeedLimit = 30;
  static const int sponsorsLimit = 20;
  static const int eventsLimit = 30;
  static const int followingProfilesLimit = 15;
  static const int followerProfilesLimit = 15;
  static const int matesLimit = 15;
  static const int profilesLimit = 1500;
  static const int maxPlaceNameLength = 28;
  static const int maxEventNameDescLength = 50;
  static const int maxEventNameLength = 22;
  static const int maxLocationNameLength = 20;
  static const int significantDistanceKM = 5;
  static const int directoryLimit = 20;
  static const int mainItemFeedTurn = 2;
  static const int secondaryItemFeedTurn = 2;
  static const int sponsorsFeedTurn = 5;
  static const int articlesFeedTurn = 5;

  static const itemTab = 'items';
  static const goingTab = 'going';
  static final walletTabs = ['all', 'events', 'booking'];


  static const nameMinimumLength = 2;
  static const usernameMinimumLength = 4;
  static const usernameMaximumLength = 20;
  static const passwordMinimumLength = 6;
  static const passwordMaximumLength = 16;
  static const emailMaximumLength = 26;
  static const firstYearDOB = 1930;
  static const lastYearDOB = 2010;
  static const firstReleaseYear = 1970;
  static const maxAudioDuration = 1500;

  static const String initialTimeSeconds = '0:00';
  static const String grid = 'grid';

  static const List<String> listCategory = ['All posts', 'Media', 'Events', 'Videos', 'Questions', 'Polls'];

  static const double cameraPositionZoom = 20;
  static const int imageQuality = 100;
  static const int videoQuality = 100;

  static const String wifi = "Wi-FI";
  static const String km = "KM";

  static const String youtube = "Youtube";
  static const String spotify = "Spotify";

  static const String appBot = "appBot";
  static const String referenceId = "referenceId";

  //TODO Change with env and flavour to bot of each app
  static const String appBotName = "Bot";
  static const String http = "http";

  static const int blogMinWords = 2;
  static final blogTabs = ['published', 'drafts'];
  static const String titleTextDivider = "_titleTextDivider_";
  static const String digitalLibrary = "digitalLibrary";
  static const String quotation = "quotation";
  static const String appItemQuotation = "appItemQuotation";

  static final List<String> appItemSize = ['Tamaño Carta - 21x29.7 - 8.5x11 ', 'Medía carta - 14x21.6cm - 6x9in', 'french', 'deutsch'];
  static const int maxVideoFileSize = 100000000; //100 MB
  static const int userMaxVideoDurationInSeconds = 90;
  static const int verifiedMaxVideoDurationInSeconds = 150;
  static const int adminMaxVideoDurationInSeconds = 300;
  static const List<double> playbackRates = [0.75, 1.0, 1.5, 2.0, 2.5, 3.0,];

  static const String yyyyMMddHHmm = "yyyy-MM-dd HH:mm";
  static const String timeAgoPattern = 'dd/MM/yyyy';
  static const String dev = "Dev";
  static const int maxVideosPerWeek = 5;

  static const int firstHomeTabIndex = 0;
  static const int secondHomeTabIndex = 1;
  static const int thirdHomeTabIndex = 2;
  static const int forthHomeTabIndex = 3;
  static const int fifthHomeTabIndex = 4;

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  static const List<String> videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'];
  static const List<String> documentExtensions = ['pdf'];
  static const List<String> audioExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];

  static const String transparentImageBase64 = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
}
