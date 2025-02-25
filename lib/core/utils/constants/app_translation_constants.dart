
import 'package:flutter/cupertino.dart';

class AppTranslationConstants {

  static final List<String> supportedLanguages = ['english', 'spanish', 'french', 'deutsch'];

  static const Map<String, Locale> supportedLocales = {
    'english': Locale('en', 'US'),
    'spanish': Locale('es', 'MX'),
    'french': Locale('fr', 'FR'),
    'deutsch': Locale('de', 'DE')
  };

  static const String es = 'es';

  static String languageFromLocale(Locale locale) {
    String language = "";
    switch(locale.languageCode){
      case 'en':
        language = "english";
        break;
      case 'esp':
        language = "spanish";
        break;
      case 'es':
        language = "spanish";
        break;
      case 'fr':
        language = "french";
        break;
      case 'de':
        language = "deutsch";
        break;
    }

    return language;
  }

  static const String spanish = "spanish";
  static const String setLocale = "setLocale";

  static const String slogan = 'slogan';
  static const String login = 'login';
  static const String introLocale = "introLocale";
  static const String introProfileType = "introProfileType";
  static const String introFacilitatorType = "introFacilitatorType";
  static const String introEventPlannerType = "introEventPlannerType";
  static const String instrumentSelection = "instrumentSelection";
  static const String frequencySelection = "frequencySelection";

  static const String close = "close";

  static const String itemDetailsAddedMsg = "itemDetailsAddedMsg";
  static const String addToYourItemlist = "addToYourItemlist";
  static const String removeFromItemlist = "removeFromItemlist";
  static const String itemlistPrefs = "itemlistPrefs";
  static const String cantRemoveMainItemlist = "cantRemoveMainItemlist";

  static const String introInstruments = "introInstruments";
  static const String introGenres = "introGenres";
  static const String introReason = "introReason";

  static const String multimediaUpload = "multimediaUpload";
  static const String createEvent = "createEvent";
  static const String checkSummary = "checkSummary";
  static const String createEventType = "createEventType";
  static const String createEventActivities = "createEventActivities";
  static const String createEventBandOrMusicians = "createEventBandOrMusicians";
  static const String lookupForMusicians = "lookupForMusicians";
  static const String createEventBands = "createEventBands";
  static const String createEventInstr = "createEventInstr";
  static const String createEventItemlists = "createEventItemlists";
  static const String createEventItems = "createEventItems";
  static const String createEventReason = "createEventReason";
  static const String createEventNameDesc = "createEventNameDesc";
  static const String createEventCoverGenres = "createEventCoverGenres";
  static const String createEventGenres = "createEventGenres";
  static const String selectSpecificItems = "selectSpecificItems";

  static const String requiredInstruments = "requiredInstruments";
  static const String requiredItems = "requiredItems";
  static const String requiredPercentage = 'requiredPercentage';
  static const String eventType = "eventType";
  static const String eventReason = "eventReason";
  static const String type = "type";
  static const String reason = "reason";
  static const String eventInfo = "eventInfo";
  static const String dateAndLocation = 'dateAndLocation';
  static const String location = 'location';
  static const String place = 'place';
  static const String address = 'address';
  static const String eventTitle = "eventTitle";
  static const String eventDesc = "eventDesc";
  static const String itemlistTitle = "itemlistTitle";
  static const String itemlistDesc = "itemlistDesc";
  static const String appItemPrefs = 'appItemPrefs';
  static const String goHome = "goHome";
  static const String next = "next";
  static const String tbd = "TBD";
  static const String tbc = "TBC";
  static const String title = "title";
  static const String createItemlist = "createItemlist";
  static const String createReadlist = "createReadlist";
  static const String createPlaylist = "createPlaylist";
  static const String addItem = "addItem";
  static const String addItems = "addItems";
  static const String update = "update";
  static const String allEvents = "allEvents";
  static const String hello = "hello";
  static const String letsExploreEvents = "letsExploreEvents";
  static const String seeComments = "seeComments";
  static const String writeComment = "writeComment";
  static const String writeMessage = "writeMessage";
  static const String writeThought = "writeThought";
  static const String writeYourFeelingOrThinking = 'writeYourFeelingOrThinking';
  static const String popularEvents = "popularEvents";
  static const String recentEvents = "recentEvents";
  static const String comingEvents = "comingEvents";
  static const String previousEvents = "previousEvents";
  static const String loginToContinue = "loginToContinue";
  static const String language = 'language';
  static const String preferredLanguage = 'preferredLanguage';
  static const String safety = 'safety';
  static const String loadingAccount = 'loadingAccount';
  static const String blockedAccounts = 'blockedAccounts';
  static const String blockedProfiles = 'blockedProfiles';
  static const String blockedProfilesMsg = 'blockedProfilesMsg';

  static const String updateCoverImage = "updateCoverImage";
  static const String updateProfilePicture = "updateProfilePicture";
  static const String uploadImage = "uploadImage";
  static const String profileDetails = "profileDetails";
  static const String profileInformation = "profileInformation";

  static const String more = 'more';
  static const String about = 'about';
  static const String aboutMe = 'aboutMe';
  static const String itemmates = "Itemmates";
  static const String eventmates = "Eventmates";
  static const String itemmateSearch = "itemmateSearch";
  static const String following = "Following";
  static const String followers = "Followers";
  static const String unfollow = "unfollow";
  static const String follow = "follow";
  static const String message = "message";
  static const String messages = "messages";

  static const List<String> choices = ["more", "about", "logout"];
  static const String itemSearch = "itemSearch";
  static const String search = "search";
  static const String searchInApp = "searchInApp";
  static const String searchOnSpotify = "searchOnSpotify";
  // static const String searchOnGigmeoutAndSpotify = "searchOnGigmeoutAndSpotify";
  static const String synchronizeSpotifyPlaylists = "synchronizeSpotifyPlaylists";
  static const String synchronizePlaylists = "synchronizePlaylists";
  static const String finishingSpotifySync = "finishingSpotifySync";

  static const String toComment = "toComment";
  static const String toReply = 'toReply';
  static const String replies = 'replies';
  static const String likes = "likes";
  static const String comment = "comment";
  static const String comments = "comments";
  static const String profile = "profile";
  static const String notifications = "notifications";
  static const String instruments = "instruments";
  static const String frequencies = "frequencies";
  static const String eventsCalendar = "eventsCalendar";
  static const String eventsRequests = "eventsRequests";
  static const String gig = "gig";
  static const String rehearsal = "rehearsal";

  static const String bands = "bands";
  static const String band = "band";

  static const String noProfileDesc = 'noProfileDesc';
  static const String noPostsYet = 'noPostsYet';
  static const String noItemsYet = 'noItemsYet';
  static const String done = 'done';
  static const String cancel = 'cancel';
  static const String photoFromGallery = 'photoFromGallery';
  static const String videoFromGallery = 'videoFromGallery';
  static const String takeVideo = 'takeVideo';
  static const String takePhoto = 'takePhoto';
  static const String tapToUploadImage = 'tapToUploadImage';
  static const String userCurrentLocation = 'userCurrentLocation';
  static const String createPost = 'createPost';
  static const String writeCaption = 'writeCaption';
  static const String wherePhotoTaken = 'wherePhotoTaken';
  static const String post = 'post';
  static const String posts = 'posts';
  static const String toPost = 'toPost';
  static const String writeYourMessage = 'writeYourMessage';
  static const String underConstruction = "underConstruction";
  static const String underConstructionMsg = "underConstructionMsg";
  static const String gatewayPaymentUnderConstructionMsg = "gatewayPaymentUnderConstructionMsg";
  static const String camera = "camera";
  static const String gallery = "gallery";
  static const String remove = "remove";
  static const String setFav = "setFav";
  static const String postOptions = "postOptions";
  static const String aboutApp = "aboutApp";
  static const String help = "help";
  static const String developer = "developer";
  static const String github = "Github";
  static const String linkedin = "LinkedIn" ;
  static const String twitter = "Twitter";
  static const String blog = "Blog";
  static const String checkMyBlog = "checkMyBlog";
  static const String prevVersion1 = "prevVersion1";
  static const String prevVersion2 = "prevVersion2";
  static const String prevVersion3 = "prevVersion3";
  static const String prevVersion4 = "prevVersion4";
  static const String contentPreferences = "contentPreferences";
  static const String privacyAndPolicy = 'privacyAndPolicy';
  static const String account = 'account';
  static const String settingPrivacyMsg = 'settingPrivacyMsg';
  static const String general = 'general';
  static const String legal = 'Legal';
  static const String websites = 'websites';

  static const String helpCenter = 'helpCenter';
  static const String termsOfService = 'termsOfService';
  static const String privacyPolicy = 'privacyPolicy';
  static const String cookieUse = 'cookieUse';
  static const String legalNotices = 'legalNotices';

  static const String accountSettings = 'accountSettings';
  static const String loginAndSecurity = 'loginAndSecurity';
  static const String fullName = 'fullName';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String username = 'username';
  static const String phone = 'phone';
  static const String emailAddress = 'emailAddress';
  static const String email = 'Email';
  static const String enterEmail = 'enterEmail';
  static const String password = 'password';
  static const String enterPassword = 'enterPassword';
  static const String confirmPassword = 'confirmPassword';
  static const String forgotPassword = 'forgotPassword';
  static const String passwordReset = 'passwordReset';
  static const String passwordEmailResetSent = 'passwordEmailResetSent';

  static const String enterDOB = 'enterDOB';
  static const String signInWith = 'signInWith';
  static const String or = 'or';
  static const String dontHaveAnAccount = 'dontHaveAnAccount';
  static const String signIn = 'signIn';
  static const String passwordResetInstruction = 'passwordResetInstruction';
  static const String sendingPasswordRecovery = 'sendingPasswordRecovery';
  static const String signUp = 'signUp';
  static const String invalidName = 'invalidName';
  static const String invalidCouponCode = 'invalidCouponCode';
  static const String invalidCouponCodeMsg = 'invalidCouponCodeMsg';
  static const String appliedCouponCode = 'appliedCouponCode';
  static const String appliedCouponCodeMsg = 'appliedCouponCodeMsg';
  static const String createCoupon = 'createCoupon';
  static const String createSponsor = 'createSponsor';
  static const String adminCenter = 'adminCenter';
  static const String usersDirectory = 'usersDirectory';
  static const String gotoUsersDirectory = 'gotoUsersDirectory';

  static const String createAccount = 'createAccount';
  static const String finishAccount = 'finishAccount';
  static const String finishProfile = 'finishProfile';
  static const String removeAccount = 'removeAccount';
  static const String removingAccount = 'removingAccount';
  static const String removeThisAccount = 'removeThisAccount';
  static const String removingProfile = 'removingProfile';
  static const String removeThisProfile = 'removeThisProfile';
  static const String addNewItemlist = 'addNewItemlist';
  static const String itemlistName = 'itemlistName';
  static const String description = 'description';
  static const String publicList = 'publicList';
  static const String add = 'add';
  static const String home = 'home';
  static const String events = 'events';
  static const String event = 'event';
  static const String eventDate = 'eventDate';
  static const String itemlists = 'itemlists';
  static const String myItemlists = 'myItemlists';
  static const String inbox = 'inbox';

  static const String myFavItemlistName = 'myFavItemlistName';
  static const String myFavItemlistDesc = 'myFavItemlistDesc';
  static const String myFavItemlistFanDesc = 'myFavItemlistFanDesc';

  static const String addInstrument = "addInstrument";
  static const String mainInstrument = "mainInstrument";
  static const String defaultInstrumentLevel = "defaultInstrumentLevel";
  static const String notDetermined = "notDetermined";
  static const String instrumentPreferences = "instrumentPreferences";
  static const String instrumentsPreferences = "instrumentsPreferences";
  static const String selectedAsMainInstrument = "selectedAsMainInstrument";

  static const String createEventHeader = 'createEventHeader';
  static const String createEventPlace = 'createEventPlace';
  static const String specifyEventPlace = 'specifyEventPlace';
  static const String pleaseEventDate = 'pleaseEventDate';
  static const String date = 'date';
  static const String dateOfBirth = 'dateOfBirth';
  static const String time = 'time';
  static const String specifyAmountContribute = 'specifyAmountContribute';
  static const String contributionAmountMusicians = 'contributionAmountMusicians';
  static const String contributionAmountBands = 'contributionAmountBands';
  static const String specifyCoverPrice = 'specifyCoverPrice';
  static const String coverPrice = 'coverPrice';
  static const String selectMaxDistanceKm = 'selectMaxDistanceKm';
  static const String selectPercentageCoverage = 'selectPercentageCoverage';
  static const String selectTime = 'selectTime';
  static const String addEventImg = 'addEventImg';
  static const String addItemlistImg = 'addItemlistImg';
  static const String hasCreatedEvent = 'hasCreatedEvent';
  static const String changeImage = 'changeImage';
  static const String changeName = 'changeName';
  static const String changeDesc = 'changeDesc';

  static const String sendReport = 'sendReport';
  static const String hasSentReport = 'hasSentReport';
  static const String sendRequest = 'sendRequest';
  static const String sendInvitation = 'sendInvitation';
  static const String by = 'by';
  static const String to = 'to';
  static const String from = 'from';
  static const String participants = 'participants';
  static const String participantsMax = 'participantsMax';
  static const String musicians = 'musicians';
  static const String noFulfilledInstrumentYet = 'noFulfilledInstrumentYet';
  static const String name = 'name';
  static const String optional = 'optional';
  static const String optionalMessage = 'optionalMessage';
  static const String optionalOffer = 'optionalOffer';
  static const String send = 'send';
  static const String dontHaveThisInfoYet = 'dontHaveThisInfoYet';
  static const String addProfileImg = 'addProfileImg';
  static const String addProfileImgMsg = 'addProfileImgMsg';
  static const String addLastProfileInfoMsg = 'addLastProfileInfoMsg';
  static const String addNewProfileInfoMsg = 'addNewProfileInfoMsg';
  static const String tellAboutYou = 'tellAboutYou';
  static const String couponCode = 'couponCode';


  static const String creatingAccount = 'creatingAccount';
  static const String creatingProfile = 'creatingProfile';
  static const String welcome = 'welcome';
  static const String welcomeToApp = 'welcomeToApp';
  static const String welcomeToAppMsg = 'welcomeToAppMsg';
  static const String youWillFindMsg = 'youWillFindMsg';
  static const String enjoyTheApp = 'enjoyTheApp';

  static const String notSpecified = 'notSpecified';

  static const String followingMsg = 'followingMsg';
  static const String followersMsg = 'followersMsg';
  static const String itemmatesMsg = 'itemmatesMsg';
  static const String eventmatesMsg = 'eventmatesMsg';

  static const String somewhereUniverse = 'somewhereUniverse';
  static const String searchByCountryName = 'searchByCountryName';
  static const String phoneNumber = 'phoneNumber';

  static const String searchPostProfileItemmates = 'searchPostProfileItemmates';
  static const String searchProfileItemmates = 'searchProfileItemmates';
  static const String chooseYourLanguage = 'chooseYourLanguage';

  static const String profileType = 'profileType';
  static const String usersLikeThis = 'usersLikeThis';
  static const String userLikeThis = 'userLikeThis';
  static const String featureComingSoon = 'featureComingSoon';
  static const String readArticle = 'readArticle';
  static const String visitSite = 'visitSite';
  static const String adjustImage = 'adjustImage';
  static const String newPost = 'newPost';

  static const String toHide = 'toHide';
  static const String hidePost = 'hidePost';
  static const String hidePostMsg = 'hidePostMsg';
  static const String hidePostMsg2 = 'hidePostMsg2';
  static const String hiddenPostMsg = 'hiddenPostMsg';

  static const String unfollowMsg = 'unfollowMsg';
  static const String reportPost = 'reportPost';
  static const String reportPostMsg = 'reportPostMsg';
  static const String reportThisPost = 'reportThisPost';
  static const String report = 'report';
  static const String toRemove = 'toRemove';
  static const String toExpel = 'toExpel';
  static const String removePost = 'removePost';
  static const String removePostMsg = 'removePostMsg';
  static const String removeThisPost = 'removeThisPost';
  static const String removedPostMsg = 'removedPostMsg';
  static const String editPost = 'editPost';
  static const String editPostMsg = 'editPostMsg';
  static const String removeProfile = 'removeProfile';
  static const String removeProfileMsg = 'removeProfileMsg';
  static const String removeProfileMsg2 = 'removeProfileMsg2';
  static const String removedProfileMsg = 'removedProfileMsg';
  static const String reportProfile = 'reportProfile';
  static const String toChange = 'toChange';
  static const String toUpdate = 'toUpdate';

  static const String reportComment = 'reportComment';
  static const String reportCommentMsg = 'reportCommentMsg';
  static const String removeComment = 'removeComment';
  static const String removeCommentMsg = 'removeCommentMsg';
  static const String removedCommentMsg = 'removedCommentMsg';
  static const String hideComment = 'hideComment';
  static const String hideCommentMsg = 'hideCommentMsg';
  static const String hideCommentMsg2 = 'hideCommentMsg2';
  static const String hiddenCommentMsg = 'hiddenCommentMsg';

  static const String toBlock = 'toBlock';
  static const String blockProfileMsg = 'blockProfileMsg';
  static const String blockProfileMsg2 = 'blockProfileMsg2';
  static const String blockProfile = 'blockProfile';
  static const String blockedProfileMsg = 'blockedProfileMsg';

  static const String toUnblock = 'toUnblock';
  static const String unblockProfile = 'unblockProfile';
  static const String unblockProfileMsg = 'unblockProfileMsg';
  static const String unblockedProfileMsg = 'unblockedProfileMsg';
  static const String unblockedProfile = 'unblockedProfile';

  static const String sharePostMsg = 'sharePostMsg';
  static const String copy = 'copy';
  static const String save = 'save';
  static const String link = 'link';
  static const String latestArticles = 'latestArticles';
  static const String sponsors = 'sponsors';
  static const String becomeSponsor = 'becomeSponsor';

  static const String createPostMsg = 'createPostMsg';
  static const String organizeEvent = 'organizeEvent';
  static const String organizeEventMsg = 'organizeEventMsg';
  static const String organizeBandEventMsg = 'organizeBandEventMsg';
  static const String shareComment = 'shareComment';
  static const String shareCommentMsg = 'shareCommentMsg';
  static const String startPoll = 'startPoll';
  static const String startPollMsg = 'startPollMsg';
  static const String shareWriting = 'shareWriting';
  static const String shareWritingMsg = 'shareWritingMsg';
  static const String releaseUpload = 'releaseUpload';
  static const String uploadYourReleaseItem = 'uploadYourReleaseItem';
  static const String uploadYourReleaseItemMsg = 'uploadYourReleaseItemMsg';


  static const String explore = 'explore';

  static const String placeTBD = "placeTBD";
  static const String dateTBD = "dateTBD";

  static const String timeTBD = "timeTBD";

  static const String findItemmatesNearYourPlace = "findItemmatesNearYourPlace";
  static const String findItemmatesNearYourPlaceMsg = "findItemmatesNearYourPlaceMsg";
  static const String letsGig  = "letsGig";
  static const String letsGigMsg  = "letsGigMsg";
  static const String addPictures  = "addPictures";
  static const String later  = "later";
  static const String country  = "country";
  static const String state  = "state";
  static const String city  = "city";
  static const String street  = "street";
  static const String propertyNumber  = "propertyNumber";
  static const String zipCode  = "zipCode";

  static const String acousticConditioning  = "acousticConditioning";
  static const String roomService  = "roomService";
  static const String parking  = "parking";
  static const String equipment  = "equipment";
  static const String audioEquipment  = "audioEquipment";
  static const String musicalInstrument  = "musicalInstrument";
  static const String musicalInstruments  = "musicalInstruments";
  static const String childAllowance  = "childAllowance";
  static const String smokingAllowance  = "smokingAllowance";
  static const String smokeDetector  = "smokeDetector";
  static const String publicBathroom  = "publicBathroom";
  static const String privateBathroom  = "privateBathroom";
  static const String sharedPlace  = "sharedPlace";
  static const String whereToGig  = "whereToGig";

  static const String day  = "day";
  static const String verifyAvailability  = "verifyAvailability";

  static const String rehearsalRoom = "rehearsalRoom";
  static const String recordStudio = "recordStudio";
  static const String liveSessions = "liveSessions";
  static const String forums = "forums";
  static const String numberOfPlaces = "numberOfPlaces";
  static const String numberOfMusicians  = "numberOfMusicians";
  static const String numberOfGuests  = "numberOfGuests";
  static const String rating = "rating";
  static const String rates = "rates";
  static const String score = "score";
  static const String price = "price";
  static const String wallet = "wallet";
  static const String totalWallet = "totalWallet";
  static const String totalToPay = "totalToPay";
  static const String filter = "filter";
  static const String hour = "hour";
  static const String toContact = "toContact";
  static const String bookNow = "bookNow";
  static const String confirmAndPay = "confirmAndPay";
  static const String confirmAndProceed = "confirmAndProceed";
  static const String confirmAndUpdate = "confirmAndUpdate";
  static const String proceedToOrder = "proceedToOrder";
  static const String confirmOrder = "confirmOrder";
  static const String orderDate = "orderDate";
  static const String orderDetails = "orderDetails";
  static const String yourGig = "yourGig";
  static const String yourPurchase = "yourPurchase";
  static const String modify = "modify";
  static const String priceDetails = "priceDetails";
  static const String product = "product";
  static const String productDetails = "productDetails";
  static const String tax = "tax";
  static const String taxes = "taxes";
  static const String fee = "fee";
  static const String fees = "fees";
  static const String order = "order";
  static const String orders = "orders";
  static const String discount = "discount";


  static const String chooseBookingDate = "chooseBookingDate";
  static const String bookingSearchHint = "bookingSearchHint";
  static const String bookingWelcome = "bookingWelcome";
  static const String currentAmount = "currentAmount";
  static const String noHistoryToShow = "noHistoryToShow";
  static const String appCoinComingSoon = "appCoinComingSoon";
  static const String transactionsHistory = "transactionsHistory";
  static const String appCoinsToAcquire = "appCoinsToAcquire";
  static const String acquireAppCoinsMsg = "acquireAppCoinsMsg";

  static const String all = "all";
  static const String booking = "booking";
  static const String gigs = "gigs";

  static const String checkRequests = "checkRequests";
  static const String goToEvent = "goToEvent";
  static const String goingEvent = "goingEvent";
  static const String stopGoingEvent = "stopGoingEvent";
  static const String seeMoreElements = "seeMoreElements";

  static const String requests = "requests";
  static const String invitations = "invitations";
  static const String homeStudio = "homeStudio";
  static const String production = "production";

  static const String no = "no";
  static const String yes = "yes";

  static const String updateProfile = "updateProfile";
  static const String editProfile = "editProfile";
  static const String profileUpdatedMsg = "profileUpdatedMsg";

  static const String waitingForResponse = "waitingForResponse";
  static const String requestAccepted = "requestAccepted";
  static const String requestRejected = "requestRejected";
  static const String invitationAccepted = "invitationAccepted";
  static const String participationCancelled = "participationCancelled";

  static const String askedAQuestion = "askedAQuestion";
  static const String createdAPoll = "createdAPoll";
  static const String createdAnEvent = "createdAnEvent";
  static const String goingToYourEvent = "goingToYourEvent";
  static const String ads = "ads";

  static const String wantToCloseApp = "wantToCloseApp";
  static const String wantToGoHome = "wantToGoHome";
  static const String youHave = "youHave";
  static const String youAre = "youAre";
  static const String of = "of";
  static const String distance = "distance";
  static const String maximum = "maximum";
  static const String searchSpotifyPlaylist = "searchSpotifyPlaylist";
  static const String requestInfo = "requestInfo";
  static const String accept = "accept";
  static const String decline = "decline";
  static const String eventPrefs = "eventPrefs";
  static const String commentPrefs = "commentPrefs";
  static const String edit = "edit";
  static const String eventEnded = "eventEnded";
  static const String pending = "pending";
  static const String found = "found";
  static const String wereFound = "wereFound";
  static const String noRequestsWereFound = "noRequestsWereFound";
  static const String noEntriesWereFound = "noEntriesWereFound";
  static const String noDraftsWereFound = "noDraftsWereFound";
  static const String noNotificationsWereFound = "noNotificationsWereFound";
  static const String noMsgsWereFound = "noMsgsWereFound";
  static const String noInvitationsWereFound = "noInvitationsWereFound";
  static const String requestConfirmationMsg = "requestConfirmationMsg";
  static const String requestAlreadySent = "requestAlreadySent";
  static const String startedFollowingYou = "startedFollowingYou";
  static const String hasMentionedYou = "hasMentionedYou";
  static const String likedYourPost = "likedYourPost";
  static const String commentedYourPost = "commentedYourPost";
  static const String hasCommented = "hasCommented";
  static const String likedYourComment = "likedYourComment";
  static const String repliedYourComment = "repliedYourComment";
  static const String hasReactedToThePostOf = "hasReactedToThePostOf";
  static const String commentedThePostOf = "commentedThePostOf";
  static const String sentRequestTo = "sentRequestTo";
  static const String sentMessageTo = "sentMessageTo";
  static const String goingToEvent = "goingToEvent";
  static const String eventCreated = "eventCreated";
  static const String hasSentRequest = "hasSentRequest";
  static const String hasSentMessage = "hasSentMessage";

  static const String viewedYourProfile = "viewedYourProfile";
  static const String viewedProfileOf = "viewedProfileOf";
  static const String isFollowingTo = "isFollowingTo";
  static const String hasPostedSomethingNew = "hasPostedSomethingNew";
  static const String hasPostedInBlog = "hasPostedInBlog";
  static const String addedAppItemToList = "addedAppItemToList";
  static const String addedReleaseAppItem = "addedReleaseAppItem";

  static const String receivedInvitationRequest = "receivedInvitationRequest";
  static const String hasAcceptedYourRequest = "hasAcceptedYourRequest";
  static const String hasDeclinedYourRequest = "hasDeclinedYourRequest";
  static const String eventHasBeenFulfilled = "eventHasBeenFulfilled";
  static const String isYourNewItemmate = "isYourNewItemmate";
  static const String toContinue = "toContinue";
  static const String changeThisInTheAppSettings = "changeThisInTheAppSettings";
  static const String locationUsage = "locationUsage";
  static const String locationRequiredTitle = "locationRequiredTitle";
  static const String locationRequiredMsg1 = "locationRequiredMsg1";
  static const String locationRequiredMsg2 = "locationRequiredMsg2";
  static const String allow = "allow";
  static const String deny = "deny";
  static const String changeThisSettingLater = "changeThisSettingLater";
  static const String noAvailablePreviewUrl = "noAvailablePreviewUrl";
  static const String noAvailablePreviewUrlMsg = "noAvailablePreviewUrlMsg";
  static const String goingEventWithCoverMsg = "goingEventWithCoverMsg";
  static const String paymentMethod = "paymentMethod";
  static const String paymentDetails = "paymentDetails";
  static const String paymentCurrency = "paymentCurrency";
  static const String paymentProcessed = "paymentProcessed";
  static const String paymentProcessedMsg = "paymentProcessedMsg";
  static const String paymentProcessing = "paymentProcessing";
  static const String toPay = "toPay";
  static const String using = "using";
  static const String total = "total";
  static const String qrTicket = "QRTicket";
  static const String tapToGetQRTicket = "tapToGetQRTicket";
  static const String getQRTicket = "getQRTicket";

  static const String bandName = "bandName";
  static const String addBand = "addBand";
  static const String createBand = "createBand";
  static const String addBandImg = 'addBandImg';
  static const String addBandImgMsg = 'addBandImgMsg';
  static const String addLastBandInfoMsg = 'addLastBandInfoMsg';
  static const String tellAboutYourBand = 'tellAboutYourBand';
  static const String yourBand = 'yourBand';
  static const String wasInvitedTotheEvent = 'wasInvitedTotheEvent';
  static const String createBandInstruments = 'createBandInstruments';
  static const String pricePerHour = 'pricePerHour';
  static const String playingInstrument = 'playingInstrument';
  static const String select = 'select';
  static const String bandPrefs = 'bandPrefs';
  static const String vocal = 'vocal';
  static const String vocalType = 'vocalType';
  static const String none = 'none';
  static const String main = 'main';
  static const String second = 'second';
  static const String third = 'third';
  static const String chorist = 'chorist';
  static const String instrument = 'instrument';
  static const String invite = 'invite';
  static const String invited = 'invited';
  static const String goBack = 'goBack';
  static const String loadingPossibleBandmates = 'loadingPossibleBandmates';
  static const String noBandmatesWereFound = 'noBandmatesWereFound';
  static const String noItemlistsWereFound = 'noItemlistsWereFound';
  static const String receivedEventInvitationRequest = 'receivedEventInvitationRequest';
  static const String receivedBandInvitationRequest = 'receivedBandInvitationRequest';
  static const String isInvitingYouTo = 'isInvitingYouTo';
  static const String iHaveReadAndAccept = 'iHaveReadAndAccept';
  static const String termsAndConditions = 'termsAndConditions';

  static const String checkBandDetails = 'checkBandDetails';
  static const String checkBandDetailsMsg = 'checkBandDetailsMsg';
  static const String checkItemlists = 'checkItemlists';
  static const String checkItemlistsMsg = 'checkItemlistsMsg';
  static const String addNewMember = 'addNewMember';
  static const String addNewMemberMsg = 'addNewMemberMsg';

  static const String createdCoupon = 'createdCoupon';
  static const String createdCouponMsg = 'createdCouponMsg';
  static const String couponDesc = 'couponDesc';
  static const String couponAmount = 'couponAmount';
  static const String alreadyExists = 'alreadyExists';

  static const String updatingApp = 'updatingApp';
  static const String version = 'version';
  static const String adding = 'adding';
  static const String outOf = 'outOf';

  static const String category = 'category';
  static const String categories = 'categories';
  static const String startReading = 'startReading';
  static const String readOn = 'readOn';
  static const String suggestedReading = 'suggestedReading';
  static const String releaseShelfSuggestion = 'releaseShelfSuggestion';
  static const String digitalLibrary = 'digitalLibrary';
  static const String audioLibrary = 'audioLibrary';
  static const String music = 'music';
  static const String player = 'player';
  static const String library = 'library';
  static const String bookShop = 'bookShop';
  static const String bookshelf = 'bookshelf';
  static const String searchBooks = 'searchBooks';
  static const String popular = 'popular';
  static const String author = 'author';
  static const String publisher = 'publisher';
  static const String publishedDate = 'publishedDate';
  static const String publishedYear = 'publishedYear';
  static const String toViewOnline = 'toViewOnline';
  static const String toReadOnline = 'toReadOnline';
  static const String readMore = 'readMore';
  static const String less = 'less';
  static const String toBuy = 'toBuy';
  static const String toBuyPhysical = 'toBuyPhysical';
  static const String toAcquire = 'toAcquire';
  static const String page = 'page';
  static const String pages = 'pages';
  static const String details = 'details';
  static const String inspiration = 'inspiration';
  static const String createBlogEntry = 'createBlogEntry';
  static const String moderator = 'moderator';
  static const String participation = 'participation';
  static const String playingRole = 'playingRole';
  static const String onlineEvent = 'onlineEvent';
  static const String coverFree = 'coverFree';
  static const String test = 'test';
  static const String directory = 'directory';
  static const String businessDirectory = 'businessDirectory';

  static const String dirWhatsappMsgA = 'dirWhatsappMsgA';
  static const String dirWhatsappMsgB = 'dirWhatsappMsgB';

  static const String dirWhatsappAdminMsgA = 'dirWhatsappAdminMsgA';
  static const String dirWhatsappAdminMsgB = 'dirWhatsappAdminMsgB';
  static const String dirWhatsappAdminMsgC = 'dirWhatsappAdminMsgC';
  static const String dirWhatsappAdminMsgCFan = 'dirWhatsappAdminMsgCFan';

  static const String noItemlistsMsg = 'noItemlistsMsg';
  static const String noItemlistsMsg2 = 'noItemlistsMsg2';

  static const String offeredServices = 'offeredServices';
  static const String offeredServicesMsg = 'offeredServicesMsg';

  static const String memberships = 'memberships';
  static const String subscriptionPlans = 'subscriptionPlans';
  static const String promotion = 'promotion';
  static const String presskit = 'presskit';
  static const String mediatour = 'mediatour';
  static const String interview = 'interview';
  static const String publishingHouse = 'publishingHouse';
  static const String digitalPositioning = 'digitalPositioning';
  static const String copyright = 'copyright';
  static const String isbnProcedure = 'isbnProcedure';
  static const String onlineClinics = 'onlineClinics';
  static const String onlineInterview = 'onlineInterview';
  static const String education = 'education';
  static const String consultancy = 'consultancy';
  static const String coverDesignUrl = 'coverDesignUrl';
  static const String crowdfunding = 'crowdfunding';
  static const String startCampaignUrl = 'startCampaignUrl';
  static const String appItemQuotation = 'appItemQuotation';
  static const String quotation = 'quotation';
  static const String quotationWithUs = 'quotationWithUs';
  static const String appItemSize = 'appItemSize';
  static const String appSizeWarningMsg = 'appSizeWarningMsg';
  static const String chooseAppItemSize = 'chooseAppItemSize';
  static const String appItemDuration = 'appItemDuration';
  static const String appItemDurationShort = 'appItemDurationShort';
  static const String specifyAppItemDuration = 'specifyAppItemDuration';
  static const String specifyAppItemQty = 'specifyAppItemQty';
  static const String qty = 'qty';
  static const String appItemQty = 'appItemQty';
  static const String appItemQtyShort = 'appItemQtyShort';
  static const String appDigitalItem = 'appDigitalItem';
  static const String appPhysicalItem = 'appPhysicalItem';
  static const String coverDesign = 'coverDesign';
  static const String coverDesignRequired = 'coverDesignRequired';
  static const String typeAOrB = 'typeAOrB';
  static const String processAAndB = 'processAAndB';
  static const String processA = 'processA';
  static const String processB = 'processB';
  static const String pricePerUnit = 'pricePerUnit';
  static const String quotationTotalMsg1 = 'quotationTotalMsg1';
  static const String quotationTotalMsg2 = 'quotationTotalMsg2';
  static const String contactUsViaWhatsapp = 'contactUsViaWhatsapp';
  static const String subscriberQuotationWhatsappMsg = 'subscriberQuotationWhatsappMsg';
  static const String adminQuotationWhatsappMsg = 'adminQuotationWhatsappMsg';
  static const String thanksForYourAttention = 'thanksForYourAttention';
  static const String whatsappQuotation = 'whatsappQuotation';
  static const String downloadAppMsg = 'downloadAppMsg';

  static const String releaseItem = 'releaseItem';
  static const String releaseUploadIntro = 'releaseUploadIntro';
  static const String releaseUploadType = 'releaseUploadType';
  static const String releaseUploadInstr = 'releaseUploadInstr';
  static const String releaseUploadGenres = 'releaseUploadGenres';
  static const String releaseUploadNameDesc = 'releaseUploadNameDesc';
  static const String releaseUploadItemlistNameDesc1 = 'releaseUploadItemlistNameDesc1';
  static const String releaseUploadItemlistNameDesc2 = 'releaseUploadItemlistNameDesc2';
  static const String releaseUploadPLaceDate = 'releaseUploadPLaceDate';
  static const String releaseTitle = 'releaseTitle';
  static const String releaseDesc = 'releaseDesc';
  static const String releaseItemlistTitle = 'releaseItemlistTitle';
  static const String releaseItemlistDesc = 'releaseItemlistDesc';
  static const String releaseDuration = 'releaseDuration';
  static const String releasePreview = 'releasePreview';
  static const String releasePrice = 'releasePrice';
  static const String releasePriceMsg = 'releasePriceMsg';
  static const String addReleaseFile = 'addReleaseFile';
  static const String changeReleaseFile = 'changeReleaseFile';
  static const String autoPublishing = 'autoPublishing';
  static const String autoEditing = 'autoEditing';
  static const String autoPublishingEditingMsg = 'autoPublishingEditingMsg';
  static const String includesPhysical = 'includesPhysical';
  static const String specifyPublishingPlace = 'specifyPublishingPlace';
  static const String addReleaseCoverImg = 'addReleaseCoverImg';
  static const String submitRelease = 'submitRelease';
  static const String submitReleaseMsg = 'submitReleaseMsg';
  static const String initialPrice = 'initialPrice';
  static const String digitalReleasePrice = 'digitalReleasePrice';
  static const String physicalReleasePrice = 'physicalReleasePrice';
  static const String digitalSalesModel = 'digitalSalesModel';
  static const String digitalSalesModelMsg = 'digitalSalesModelMsg';
  static const String physicalSalesModel = 'physicalSalesModel';
  static const String physicalSalesModelMsg = 'physicalSalesModelMsg';
  static const String salesModelMsg = 'salesModelMsg';
  static const String toStart = 'toStart';
  static const String tapCoverToPreviewRelease = 'tapCoverToPreviewRelease';
  static const String releaseUploadPostCaptionMsg1 = 'releaseUploadPostCaptionMsg1';
  static const String releaseUploadPostCaptionMsg2 = 'releaseUploadPostCaptionMsg2';
  static const String buyReleaseItemMsg = 'buyReleaseItemMsg';
  static const String buySubscriptionMsg = 'buySubscriptionMsg';

  static const String analytics = 'analytics';
  static const String seeAnalytics = 'seeAnalytics';
  static const String runAnalyticsJobs = 'runAnalyticsJobs';
  static const String runProfileJobs = 'runProfileJobs';
  static const String recentReleases = 'recentReleases';
  static const String createEventWithFlyer = 'createEventWithFlyer';

  static const String addFrequency = "addFrequency";
  static const String mainFrequency = "mainFrequency";
  static const String exploreFrequencies = "exploreFrequencies";
  static const String frequency = 'frequency';
  static const String frequencyGenerator = 'frequencyGenerator';
  static const String rootFrequency = 'rootFrequency';
  static const String rootFrequencies = 'rootFrequencies';
  static const String generator = 'generator';
  static const String parameters = 'parameters';
  static const String savePreset = 'savePreset';
  static const String removePreset = 'removePreset';
  static const String updatePreset = 'updatePreset';
  static const String chamberPrefs = 'chamberPrefs';
  static const String session = 'session';
  static const String barter = 'barter';
  static const String barters = 'barters';
  static const String bartersNetwork = 'bartersNetwork';

  static const String volume = 'volume';
  static const String surroundSound = 'surroundSound';
  static const String xAxis = 'xAxis';
  static const String yAxis = 'yAxis';
  static const String zAxis = 'zAxis';

  static const String getDefaultNameDesc = 'getDefaultNameDesc';
  static const String presets = 'presets';
  static const String frequencyPreferences = 'frequencyPreferences';
  static const String selectedAsMainFrequency = 'selectedAsMainFrequency';

  static const String inAppPurchase = 'inAppPurchase';
  static const String payWithInAppPurchaseAndroid = 'payWithInAppPurchaseAndroid';
  static const String payWithInAppPurchaseIOS = 'payWithInAppPurchaseIOS';
  static const String freeDistribution = 'freeDistribution';
  static const String freeAccess = 'freeAccess';

  static const String likeMyWork = 'likeMyWork';
  static const String buyCoffee = 'buyCoffee';
  static const String contactUs = 'contactUs';
  static const String gmail = 'gmail';
  static const String contactUsSub = 'contactUsSub';
  static const String insta = 'insta';
  static const String joinWhats = 'joinWhats';
  static const String joinWhatsSub = 'joinWhatsSub';
  static const String whatsapp = 'whatsapp';
  static const String whatsRock = 'whatsRock';
  static const String whatsCommunity = 'whatsCommunity';
  static const String whatsContact = 'whatsContact';
  static const String searchResults = 'searchResults';
  static const String searchedText = 'searchedText';
  static const String aroundYou = 'aroundYou';
  static const String selectedPlaylist = "selectedPlaylist";
  static const String playlistToChoose = "playlistToChoose";
  static const String lookingForNewMusic = "lookingForNewMusic";
  static const String lookingForInspiration = "lookingForInspiration";
  static const String tryOurPlatform = "tryOurPlatform";
  static const String goBackHome = "goBackHome";
  static const String noResultsWereFound = "noResultsWereFound";
  static const String noNearResultsWereFound = "noNearResultsWereFound";
  static const String appReleaseItemsQty = "appReleaseItemsQty";
  static const String seconds = "seconds";
  static const String minutes = "minutes";  
  static const String releaseItemDurationMsg = "releaseItemDurationMsg";
  static const String releaseItemNameMsg = "releaseItemNameMsg";
  static const String releaseItemFileMsg = "releaseItemFileMsg";
  static const String noLyricsAvailable = "noLyricsAvailable";
  static const String splashSubtitle = "splashSubtitle";
  static const String poweredBy = 'Powered by';
  static const String listenOnSpotify = 'listenOnSpotify';
  static const String listenFullOnSpotify = 'listenFullOnSpotify';
  static const String copied = 'copied';
  static const String videoAboveSizeMsg = 'videoAboveSizeMsg';
  static const String loose = 'loose';
  static const String allowedContentReminderMsg = 'allowedContentReminderMsg';

  static const String openCropPage = 'openCropPage';
  static const String videoEditor = 'videoEditor';
  static const String videoCropper = 'videoCropper';
  static const String leaveVideoEditor = 'leaveVideoEditor';
  static const String processingVideo = 'processingVideo';
  static const String processVideo = 'processVideo';
  static const String wantToCloseEditor = 'wantToCloseEditor';
  static const String removeThisComment = 'removeThisComment';
  static const String removedEventMsg = 'removedEventMsg';
  static const String noBandsWereFound = 'noBandsWereFound';
  static const String postUploadErrorMsg = 'postUploadErrorMsg';
  static const String reasonToPlay = 'reasonToPlay';
  static const String preferenceToPlay = 'preferenceToPlay';
  static const String thereWasNoChanges = 'thereWasNoChanges';
  static const String requestDetails = 'requestDetails';
  static const String invitationRequestConfirmationMsg = 'invitationRequestConfirmationMsg';
  static const String wouldYouLikeAnInterview = 'wouldYouLikeAnInterview';
  static const String iWouldLikeAnInterview = 'iWouldLikeAnInterview';
  static const String isAlreadyInPlaylist = 'isAlreadyInPlaylist';
  static const String unknown = 'unknown';
  static const String favoriteItems = 'favoriteItems';
  static const String itemlistRemoved = 'itemlistRemoved';
  static const String itemlistRemovedErrorMsg = 'itemlistRemovedErrorMsg';
  static const String itemlistCreated = 'itemlistCreated';
  static const String itemlistCreatedErrorMsg = 'itemlistCreatedErrorMsg';
  static const String itemlistUpdated = 'itemlistUpdated';
  static const String itemlistUpdatedErrorMsg = 'itemlistUpdatedErrorMsg';
  static const String itemlistUpdateSameInfo = 'itemlistUpdateSameInfo';
  static const String releaseUploadBandSelection = 'releaseUploadBandSelection';
  static const String publishAsSoloist = 'publishAsSoloist';
  static const String myProject = 'myProject';
  static const String wasAddedToItemList = 'wasAddedToItemList';
  static const String requestSuccessfullySent = 'requestSuccessfullySent';
  static const String playlistSynchFinished = 'playlistSynchFinished';
  static const String digitalPositioningSuccess = 'digitalPositioningSuccess';
  static const String playbackSpeed = 'playbackSpeed';
  static const String previewFromSpotify = 'previewFromSpotify';
  static const String playOnSpotify = 'playOnSpotify';
  static const String instagram = 'instagram';
  static const String verifyProfile = 'verifyProfile';
  static const String meditations = 'meditations';
  static const String chamberCreated = 'chamberCreated';
  static const String chamberPresetAdded = 'chamberPresetAdded';
  static const String maxVideosPerWeekReachedMsg = 'maxVideosPerWeekReachedMsg';
  static const String freeSingleReleaseUploadMsg = 'freeSingleReleaseUploadMsg';
  static const String membershipFreeTrialReached = 'membershipFreeTrialReached';
  static const String membershipFreeTrialTimeReached = 'membershipFreeTrialTimeReached';
  static const String productFreeTrialReached = 'productFreeTrialReached';

  static const String professionalTools = 'professionalTools';
  static const String professionals = 'professionals';
  static const String podcastUpload = 'podcastUpload';
  static const String audiobookUpload = 'audiobookUpload';

  static const String verificationLevel = 'verificationLevel';
  static const String updateVerificationLevel = 'updateVerificationLevel';
  static const String updateVerificationLevelMsg = 'updateVerificationLevelMsg';
  static const String updateVerificationLevelSame = 'updateVerificationLevelSame';
  static const String updateUserRole = 'updateUserRole';
  static const String updateUserRoleMsg = 'updateUserRoleMsg';
  static const String updateUserRoleSame = 'updateUserRoleSame';
  static const String updateUserRoleSuccess = 'updateUserRoleSuccess';
  static const String checkInvoice = 'checkInvoice';

  static const String publicDomainReadings = 'publicDomainReadings';
  static const String freeDomain = 'freeDomain';
  static const String toSubscribe = 'toSubscribe';
  static const String subscription = 'subscription';
  static const String activateSubscription = 'activateSubscription';
  static const String cancelSubscription = 'cancelSubscription';
  static const String cancelThisSubscription = 'cancelThisSubscription';
  static const String activeSubscription = 'activeSubscription';
  static const String active = 'active';
  static const String activate = 'activate';
  static const String comingSoon = 'comingSoon';

  static const String verifyPhone = 'verifyPhone';
  static const String tryAgain = 'tryAgain';
  static const String sendCodeAgain = 'sendCodeAgain';

  static const String printing = 'printing';
  static const String paper = 'paper';
  static const String paperType = 'paperType';
  static const String coverType = 'coverType';
  static const String coverLamination = 'coverLamination';
  static const String flap = 'flap';
  static const String flapRequired = 'flapRequired';

  static const String subscriptionMainName = 'subscriptionMainName';
  static const String subscriptionMainDesc = 'subscriptionMainDesc';

  static const String thanksForFinishingItem = 'thanksForFinishingItem';
  static const String startItem = 'startItem';

  static const String onlyPrinting = 'onlyPrinting';
  static const String onlyDigital = 'onlyDigital';
  static const String subtotal = "subtotal";
  static const String and = "and";
  static const String updatePhone = "updatePhone";

  static const String offline = "offline";
  static const String download = "download";
  static const String downloads = "downloads";
  static const String toDownload = "toDownload";
  static const String inDownloads = "inDownloads";
  static const String noItemOwnerFound = "noItemOwnerFound";

  static const String phoneVerified = "phoneVerified";
  static const String phoneVerificationFailed = "phoneVerificationFailed";

  static const String subscriptionConfirmed = "subscriptionConfirmed";
  static const String subscriptionConfirmedMsg = "subscriptionConfirmedMsg";

  static const String neomChamber = 'neomChamber';
  static const String findsYourVoiceFrequency = 'findsYourVoiceFrequency';

  static const String updateProfileType = 'updateProfileType';
  static const String updateProfileTypeMsg = 'updateProfileTypeMsg';
  static const String updateProfileTypeSuccess = 'updateProfileTypeSuccess';
  static const String updateProfileTypeSame = 'updateProfileTypeSame';

  static const String secondaryShelfTitle = 'secondaryShelfTitle';
  static const String secondaryShelfSubtitle = 'secondaryShelfSubtitle';

  static const String myFirstPlaylist = 'myFirstPlaylist';
  static const String myFirstPlaylistDesc = 'myFirstPlaylistDesc';
  static const String myFirstReadlist = 'myFirstReadlist';
  static const String myFirstReadlistDesc = 'myFirstReadlistDesc';

  static const String catalog = 'catalog';
  static const String readlists = 'readlists';
  static const String readings = 'readings';
  static const String acquireSubscription = 'acquireSubscription';

  static const String waveLength = 'waveLength';
  static const String period = 'period';
  static const String emailNotFound = 'emailNotFound';

}
