class AppRouteConstants {

  static const String root = "/";
  static const String notFound = "/not-found";
  static const String login = "/login";
  static const String forgotPassword = "/forgot_password";
  static const String forgotPasswordSending = "/forgot_password/sending";
  static const String signup = "/signup";
  static const String logout = "/logout";
  static const String introRequiredPermissions = "/intro/requiredPermissions";
  static const String introLocale = "/intro/locale";
  static const String introProfile = "/intro/profileType";
  ///DEPRECATED static const String introInstruments = "/intro/instruments";
  ///DEPRECATED static const String introGenres = "/intro/genres";
  static const String introFacility = "/intro/facility";
  static const String introPlace = "/intro/place";
  static const String introReason = "/intro/reason";
  static const String introAddImage = "/intro/addImage";
  static const String introCreating = "/intro/creating";
  static const String introWelcome = "/intro/welcome";
  static const String createAdditionalProfile = "/create/additionalProfile";
  static const String splashScreen = "/splashScreen";

  static const String home = "/home";
  static const String mobility = "/mobility";
  static const String timeline = "/timeline";
  static const String instruments = "/instrument";
  static const String instrumentsFav = '/instrument/fav';
  static const String influences = '/influences';
  static const String frequency = "/frequency";
  static const String frequencyFav = '/frequency/fav';
  static const String genresFav = '/genres/fav';
  static const String lists = '/lists';
  static const String listItems = '/list/items';
  static const String itemDetails = '/item/:itemId';
  static const String itemSearch = '/item/search';

  static const String profile = '/profile';
  static const String profileDetails = '/profile/:profileId';
  static const String profileEdit = '/profile/edit';
  static const String profileRemove = '/profile/remove';
  static const String spotifyPlaylists = '/spotify/playlists';
  static const String finishingSpotifySync = '/spotify/synchronization';

  static const String mates = '/mates';
  static const String mateDetails = '/mate/:mateId';
  static const String mateBlog = '/mate/blog';
  static const String mateSearch = '/mate/search';
  static const String following = '/following';
  static const String likedProfiles = '/likedProfiles';
  static const String followers = '/followers';
  static const String blockedProfiles = '/blockedProfiles';

  static const String search = '/search';

  static const String inbox = '/inbox';
  static const String inboxRoom = '/inbox/room';
  static const String postDetails = '/post/:postId';
  static const String postDetailsFullScreen = '/post/:postId/fullscreen';
  static const String post = '/post';
  static const String postComments = '/post/comments';
  static const String postUploadDescription = '/post/upload/description';
  static const String createPostText = '/createPost/text';

  static const String mediaUpload = '/media/upload';
  static const String imageFullScreen = '/image/fullscreen';
  static const String videoFullScreen = '/video/fullscreen';
  static const String videoEditor = '/video/editor';

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

  static const String eventDetails = '/event/:eventId';
  static const String events = '/event';

  static const String feedActivity = '/feed/activity';
  static const String feedActivityDrawer = '/drawer/activity';
  static const String calendar = '/calendar';

  static const String bands = '/bands';
  static const String bandsRoom = '/bands/room';
  static const String bandDetails = '/band/:bandId';
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
  static const String subscriptionPlans = '/subscription/plans';
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
  static const String requestDetails = '/request/:requestId';
  static const String invitationDetails = '/invitation/:invitationId';

  static const String createCoupon = '/coupon/create';
  static const String createSponsor = '/sponsor/create';
  static const String orderConfirmation = '/order/confirmation';
  static const String orderDetails = '/order/:orderId';
  static const String paymentGateway = '/payment/gateway';

  ///DEPRECATED static const String readlists  = '/readlists';
  static const String reading  = '/reading/:bookId';
  static const String epubViewer  = '/EPUBViewer';
  static const String digitalLibrary  = '/digitalLibrary';
  static const String libraryHome  = '/library/';
  static const String topBooks  = '/books/top';
  static const String bookDetails  = '/book/:bookId';

  static const String blog  = '/blog';
  static const String blogEditor  = '/blog/editor';
  static const String blogEntry  = '/blog/:entryId';
  static const String blogAdmin  = '/blog/admin';
  static const String blogAnalytics  = '/blog/analytics';

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
  static const String errorMonitor  = '/analytics/errorMonitor';
  static const String flowMonitor  = '/analytics/flowMonitor';

  static const String generator  = '/generator';
  static const String chamber  = '/chamber';
  static const String chamberPresets  = '/chamber/presets';
  static const String oscilloscopeFullscreen  = '/oscilloscope/fullscreen';
  static const String flockingFullscreen  = '/flocking/fullscreen';
  static const String breathingFullscreen  = '/breathing/fullscreen';
  static const String spatial360Fullscreen  = '/360/spatial/fullscreen';
  static const String vr360MonoFullscreen  = '/360/vr/mono/fullscreen';
  static const String vr360StereoFullscreen  = '/360/vr/stereo/fullscreen';
  static const String fractalFullscreen  = '/fractal/fullscreen';

  static const String audioPlayer  = '/audioPlayer';
  static const String audioPlayerMedia  = '/audioPlayer/media';
  static const String audioPlayerMini  = '/audioPlayer/mini';
  static const String audioPlayerRecent  = '/audioPlayer/recent';
  static const String audioPlayerPref = '/audioPlayer/pref';
  static const String audioPlayerSetting = '/audioPlayer/setting';
  static const String audioPlayerPlaylists = '/audioPlayer/playlists';
  static const String audioPlayerNowPlaying = '/audioPlayer/nowPlaying';
  static const String audioPlayerDownloads = '/audioPlayer/downloads';
  static const String audioPlayerStats  = '/audioPlayer/stats';

  static const String wooWebView  = '/woo/webView';

  static const String nupaleHome  = '/nupale/home';
  static const String nupaleItemDetails  = '/nupale/item/:itemId';
  static const String nupaleMonthlyDetails  = '/nupale/monthly/:monthId';
  static const String nupaleStats1  = '/stats/nupale1';
  static const String nupaleStats2  = '/stats/nupale2';
  static const String nupaleStats3  = '/stats/nupale3';
  static const String nupaleStats4  = '/stats/nupale4';
  static const String nupaleStats5  = '/stats/nupale5';
  static const String nupaleRoyalties  = '/nupale/royalties';
  static const String nupaleAdmin  = '/nupale/admin';
  static const String caseteStats  = '/stats/casete';

  static const String camera  = '/camera';

  static const String wallet = '/wallet';
  static const String transactionDetails = '/transaction/:transactionId';

  static const String caseteHome  = '/casete/home';
  static const String caseteItemDetails  = '/casete/item/:itemId';
  static const String caseteMonthlyDetails  = '/casete/monthly/:monthId';

  static const String dawProjects = '/daw';
  static const String dawEditor = '/daw/editor';
  static const String dawMixer = '/daw/mixer';

  static const String vstHome = '/vst';

  static const String learning = '/learning';

  static const String games = '/games';
  static const String gamesWordChain = '/games/wordChain';
  static const String gamesStoryBuilder = '/games/storyBuilder';
  static const String gamesStories = '/games/stories';
  static const String gamesQuoteQuest = '/games/quoteQuest';
  static const String gamesVerseScramble = '/games/verseScramble';
  static const String gamesLiteraryChess = '/games/literaryChess';
  static const String gamesLibroverso = '/games/libroverso';
  static const String gamesLibrinder = '/games/librinder';
  static const String gamesLibroTerapia = '/games/libroTerapia';
  static const String findOpponent = '/games/findOpponent';
  static const String multiplayerChess = '/games/multiplayerChess';

  // Shop
  static const String shopCart = '/shop/cart';
  static const String shopCheckout = '/shop/checkout';
  static const String shopOrders = '/shop/orders';
  static const String shopOrderDetail = '/shop/order/:orderId';
  static const String shopAdmin = '/shop/admin';
  static const String shopAdminOrders = '/shop/admin/orders';
  static const String shopAdminOrderDetail = '/shop/admin/order/:orderId';
  static const String shopAdminShipping = '/shop/admin/shipping';
  static const String shopWishlist = '/shop/wishlist';
  static const String shopAddresses = '/shop/addresses';
  static const String shopRefundRequest = '/shop/refund/request';
  static const String shopReview = '/shop/review';
  static const String shopSellerDashboard = '/shop/seller';
  static const String shopSellerOrderDetail = '/shop/seller/order/:orderId';
  static const String shopSellerProducts = '/shop/seller/products';
  static const String shopProductEdit = '/shop/seller/product/edit';
  static const String shopSellerInventory = '/shop/seller/inventory';
  static const String shopSellerStats = '/shop/seller/stats';
  static const String shopSupport = '/shop/support';
  static const String shopCatalog = '/shop/admin/catalog';
  static const String shopGlobalInventory = '/shop/admin/inventory';
  static const String shopAnalytics = '/shop/admin/analytics';
  static const String shopMediaManager = '/shop/admin/media';
  static const String shopHome = '/shop';
  static const String shopSearch = '/shop/search';
  static const String shopProductDetail = '/shop/product/:productId';
  static const String shopMerchList = '/shop/admin/merch';
  static const String shopMerchEdit = '/shop/seller/merch/edit';
  static const String shopAdminBanners = '/shop/admin/banners';

  // New features 2026
  static const String scheduledPosts = '/post/scheduled';
  static const String achievements = '/achievements';
  static const String stories = '/stories';
  static const String storyCreate = '/stories/create';
  static const String storyViewer = '/stories/viewer';
  static const String communities = '/communities';
  static const String communityDetail = '/community/:communityId';
  static const String communityChat = '/community/chat';
  static const String communityCreate = '/community/create';
  static const String creatorAnalytics = '/creator/analytics';
  static const String trackAnalytics = '/creator/analytics/track';
  static const String liveDiscover = '/live';
  static const String liveHost = '/live/host';
  static const String liveListener = '/live/listener';
  static const String goLive = '/live/setup';
  static const String tipHistory = '/tip/history';

  // Stripe Financial Intelligence
  static const String stripeWebView  = '/stripe/webview';
  static const String stripeDashboard = '/stripe/dashboard';
  static const String stripeSubscriptions = '/stripe/subscriptions';

  // ERP Hub (Operations Center)
  static const String erpDashboard = '/erp/dashboard';
  static const String erpOperations = '/erp/operations';
  static const String erpBenchmark = '/erp/benchmark';

  // Subscription status
  static const String subscriptionSuspended = '/subscription/suspended';

  // Admin
  static const String slugMigration = '/admin/slug-migration';

  // Museum / Gallery
  static const String museumHome = '/museum';
  static const String museumArtworkDetail = '/museum/artwork/:artworkId';
  static const String museumGallery = '/museum/gallery/:galleryId';
  static const String museumGalleryCreate = '/museum/gallery/create';
  static const String museumAuctionDetail = '/museum/auction/:auctionId';
  static const String museumMyGalleries = '/museum/my-galleries';
  static const String museumHallway = '/museum/hallway';
  static const String museumRoom = '/museum/room';

  // Remote Control
  static const String rc = '/rc';

  // ─── RESTful Path Builders (for navigation with dynamic IDs) ───
  // When a slug is provided and non-empty, it is used instead of the id
  // for web-friendly URLs, SEO, and deep linking compatibility.

  static String _slugOrId(String id, String slug) => slug.isNotEmpty ? slug : id;

  static String bookPath(String id, {String slug = ''}) => '/book/${_slugOrId(id, slug)}';
  static String readingPath(String id, {String slug = ''}) => '/reading/${_slugOrId(id, slug)}';
  static String matePath(String id, {String slug = ''}) => '/mate/${_slugOrId(id, slug)}';
  static String postPath(String id, {String slug = ''}) => '/post/${_slugOrId(id, slug)}';
  static String postFullScreenPath(String id, {String slug = ''}) => '/post/${_slugOrId(id, slug)}/fullscreen';
  static String eventPath(String id, {String slug = ''}) => '/event/${_slugOrId(id, slug)}';
  static String bandPath(String id, {String slug = ''}) => '/band/${_slugOrId(id, slug)}';
  static String itemPath(String id, {String slug = ''}) => '/item/${_slugOrId(id, slug)}';
  static String profilePath(String id, {String slug = ''}) => '/profile/${_slugOrId(id, slug)}';
  static String requestPath(String id) => '/request/$id';
  static String invitationPath(String id) => '/invitation/$id';
  static String orderPath(String id) => '/order/$id';
  static String transactionPath(String id) => '/transaction/$id';
  static String communityPath(String id) => '/community/$id';
  static String shopOrderPath(String id) => '/shop/order/$id';
  static String shopProductPath(String id) => '/shop/product/$id';
  static String shopAdminOrderPath(String id) => '/shop/admin/order/$id';
  static String shopSellerOrderPath(String id) => '/shop/seller/order/$id';
  static String nupaleItemPath(String id) => '/nupale/item/$id';
  static String nupaleMonthlyPath(String id) => '/nupale/monthly/$id';
  static String caseteItemPath(String id) => '/casete/item/$id';
  static String caseteMonthlyPath(String id) => '/casete/monthly/$id';
  static String museumArtworkPath(String id) => '/museum/artwork/$id';
  static String museumGalleryPath(String id) => '/museum/gallery/$id';
  static String museumAuctionPath(String id) => '/museum/auction/$id';
  static String blogEntryPath(String id, {String slug = ''}) => '/blog/${_slugOrId(id, slug)}';

}
