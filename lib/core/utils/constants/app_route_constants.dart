import 'package:neom_booking/booking/ui/booking_home_page.dart';
import 'package:neom_events/events/ui/events_page.dart';
import 'package:neom_inbox/inbox/ui/inbox_page.dart';
import 'package:neom_itemlists/itemlists/ui/itemlist_page.dart';
import 'package:neom_music_player/ui/home/music_player_home_page.dart';
import 'package:neom_posts/blog/ui/blog_page.dart';
import 'package:neom_timeline/neom_timeline.dart';

class AppRouteConstants {

  static final eHomePages = [const TimelinePage(), const ItemlistPage(), const BlogPage(), const InboxPage()];
  static final gHomePages = [const TimelinePage(), const BookingHomePage(), const EventsPage(), const EventsPage()];
  static final nHomePages = [const TimelinePage(), const ItemlistPage(), const EventsPage(), const InboxPage()];

  static final eMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];
  static final gMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];
  static final nMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];

  static const String root = "/";
  static const String login = "/login";
  static const String forgotPassword = "/forgot_password";
  static const String forgotPasswordSending = "/forgot_password/sending";
  static const String signup = "/signup";
  static const String logout = "/logout";
  static const String introRequiredPermissions = "/intro/requiredPermissions";
  static const String introLocale = "/intro/locale";
  static const String introProfile = "/intro/profileType";
  static const String introInstruments = "/intro/instruments";
  static const String introGenres = "/intro/genres";
  static const String introFacility = "/intro/facility";
  static const String introPlace = "/intro/place";
  static const String introReason = "/intro/reason";
  static const String introAddImage = "/intro/addImage";
  static const String introCreating = "/intro/creating";
  static const String introWelcome = "/intro/welcome";
  static const String createAdditionalProfile = "/create/additionalProfile";
  static const String splashScreen = "/splashScreen";

  static const String home = "/home";
  static const String timeline = "/timeline";
  static const String instruments = "/instrument";
  static const String instrumentsFav = '/instrument/fav';
  static const String frequency = "/frequency";
  static const String frequencyFav = '/frequency/fav';
  static const String genresFav = '/genres/fav';
  static const String lists = '/list';
  static const String listItems = '/list/items';
  static const String itemDetails = '/item/details';
  static const String itemSearch = '/item/search';

  static const String profile = '/profile';
  static const String profileDetails = '/profile/details';
  static const String profileEdit = '/profile/edit';
  static const String profileRemove = '/profile/remove';
  static const String spotifyPlaylists = '/spotify/playlists';
  static const String finishingSpotifySync = '/spotify/synchronization';

  static const String mates = '/mates';
  static const String mateDetails = '/mate/details';
  static const String mateBlog = '/mate/blog';
  static const String mateSearch = '/mate/search';
  static const String following = '/following';
  static const String likedProfiles = '/likedProfiles';
  static const String followers = '/followers';
  static const String blockedProfiles = '/blockedProfiles';

  static const String search = '/search';

  static const String inbox = '/inbox';
  static const String inboxRoom = '/inbox/room';
  static const String postDetails = '/post/details';
  static const String post = '/post';
  static const String postComments = '/post/comments';
  static const String postUpload = '/post/upload';
  static const String postUploadDescription = '/post/upload/description';
  static const String createPostText = '/createPost/text';

  static const String mediaFullScreen = '/media/fullscreen';

  static const String createEventType = '/createEvent/type';
  static const String createNeomEventType = '/neom/createEvent/type';
  static const String createEventActivities = '/neom/createEvent/activities';
  static const String createEventBandOrMusicians = '/createEvent/bandOrMusicians';
  static const String createEventBands = '/createEvent/bands';
  static const String createEventLists = '/createEvent/lists';
  static const String createEventItems = '/createEvent/items';
  static const String createEventInstruments = '/createEvent/instruments';
  static const String createEventReason = '/createEvent/reason';
  static const String createEventInfo = '/createEvent/info';
  static const String createEventNameDesc = '/createEvent/nameDesc';
  static const String createEventCoverGenres = '/createEvent/coverGenres';
  static const String createEventEventSummary = '/createEvent/summary';

  static const String eventDetails = '/event/details';
  static const String events = '/event';

  static const String feedActivity = '/feed/activity';
  static const String feedActivityDrawer = '/drawer/activity';
  static const String calendar = '/calendar';

  static const String bands = '/bands';
  static const String bandsRoom = '/bands/room';
  static const String bandDetails = '/band/details';
  static const String bandLists = '/band/lists';
  static const String bandListItems = '/band/list/items';
  static const String createBandAddImage = '/createBand/addImage';
  static const String createBandInstruments = '/createBand/instruments';
  static const String createBandReason = '/createBand/reason';
  static const String createBandSummary = '/createBand/summary';

  static const String privacySafety = '/privacyAndSafety';
  static const String privacyAndTerms = '/privacyAndTerms';
  static const String settingsPrivacy = '/settingsAndPrivacy';
  static const String settingsAccount = '/settings/account';
  static const String settingsNotification = '/settings/notification';
  static const String contentPreferences = '/content/preferences';
  static const String about = '/about';
  static const String accountRemove = '/account/remove';
  static const String accountSettings = '/account/settings';
  static const String settingsDirectMessage = '/settings/directMessage';
  static const String previousVersion = '/previous-version';
  static const String underConstruction = '/under-construction';
  static const String verifyEmail = '/verify-email';

  static const String booking = '/booking';
  static const String bookingPlaces = '/booking/places';
  static const String bookingSearch = '/booking/search';
  static const String directory = '/directory';
  static const String request = '/request';
  static const String requestUp = '/request-up';
  static const String requestDetails = '/request/details';
  static const String invitationDetails = '/invitation/details';
  static const String wallet = '/wallet';

  static const String createCoupon = '/coupon/create';
  static const String createSponsor = '/sponsor/create';
  static const String orderConfirmation = '/order/confirmation';
  static const String orderDetails = '/order/details';
  static const String paymentGateway = '/payment/gateway';

  static const String refresh  = '/refresh';

  static const String readlists  = '/readlists';
  // ignore: constant_identifier_names
  static const String PDFViewer  = '/PDFViewer';
  // ignore: constant_identifier_names
  static const String EPUBViewer  = '/EPUBViewer';
  static const String digitalLibrary  = '/digitalLibrary';
  static const String libraryHome  = '/library/';
  static const String bookDetails  = '/book/details';

  static const String blog  = '/blog';
  static const String blogEditor  = '/blog/editor';
  static const String blogEntry  = '/blog/entry';

  static const String songDetails = '/song/details';
  static const String playlistSearch = '/playlist/search';
  static const String playlistItems = '/playlist/songs';
  static const String playlistNameDesc = '/playlist/nameDesc';

  static const String services = '/services';
  static const String quotation = '/quotation';
  static const String appItemQuotation = '/appItems/quotation';

  static const String releaseUpload  = '/releaseUpload';
  static const String releaseUploadType  = '/releaseUpload/type';
  static const String releaseUploadBandOrSolo  = '/releaseUpload/bandOrSolo';
  static const String releaseUploadInstr  = '/releaseUpload/instr';
  static const String releaseUploadCover  = '/releaseUpload/cover';
  static const String releaseUploadGenres  = '/releaseUpload/genres';
  static const String releaseUploadReason  = '/releaseUpload/reason';
  static const String releaseUploadInfo  = '/releaseUpload/info';

  static const String releaseUploadItemlistNameDesc  = '/releaseUpload/itemlist/nameDesc';
  static const String releaseUploadNameDesc  = '/releaseUpload/nameDesc';
  static const String releaseUploadSummary  = '/onlinePositioning/summary';

  static const String analytics  = '/analytics';

  static const String generator  = '/generator';
  static const String chamberPresets  = '/chamber/presets';

  static const String musicPlayer  = '/musicPlayer';
  static const String musicPlayerHome  = '/musicPlayer/home';
  static const String musicPlayerMedia  = '/musicPlayer/media';
  static const String musicPlayerMini  = '/musicPlayer/mini';
  static const String musicPlayerRecent  = '/musicPlayer/recent';
  static const String musicPlayerPref = '/musicPlayer//pref';
  static const String musicPlayerSetting = '/musicPlayer//setting';
  static const String musicPlayerPlaylists = '/musicPlayer//playlists';
  static const String musicPlayerNowPlaying = '/musicPlayer//nowPlaying';
  static const String musicPlayerDownloads = '/musicPlayer//downloads';
  static const String musicPlayerStats  = '/musicPlayer/stats';

}
