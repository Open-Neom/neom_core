import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/core_utilities.dart';
import '../../utils/enums/verification_level.dart';

/// Modelo independiente para entradas de blog.
/// Las reacciones (likes, comentarios) se manejan a través del Room asociado.
/// El roomId se genera con el patrón: blog_{id}
class BlogEntry {

  String id;
  String ownerId;
  String profileName;
  String profileImgUrl;

  // Contenido - separado en título y contenido (ya no usa caption con divider)
  String title;
  String content;
  String thumbnailUrl;
  List<String> hashtags;

  // Metadata
  int createdTime;
  int modifiedTime;
  int publishedTime;  // Cuando se publicó por primera vez
  Position? position;
  String location;

  // Estado
  bool isDraft;
  bool isHidden;
  bool isCommentEnabled;

  // Tema visual del blog (dark, light, sepia)
  String themeMode;

  // Estadísticas personales (no reacciones públicas - esas están en el Room)
  List<String> savedByProfiles;  // Bookmarks/Guardados
  int viewCount;  // Conteo de vistas

  // Verificación del autor
  VerificationLevel? verificationLevel;

  // ID del Post original (para migración, se puede eliminar después)
  String? legacyPostId;

  BlogEntry({
    this.id = '',
    this.ownerId = '',
    this.profileName = '',
    this.profileImgUrl = '',
    this.title = '',
    this.content = '',
    this.thumbnailUrl = '',
    this.hashtags = const [],
    this.createdTime = 0,
    this.modifiedTime = 0,
    this.publishedTime = 0,
    this.position,
    this.location = '',
    this.isDraft = true,
    this.isHidden = false,
    this.isCommentEnabled = true,
    this.themeMode = 'dark',
    this.savedByProfiles = const [],
    this.viewCount = 0,
    this.verificationLevel,
    this.legacyPostId,
  });

  /// Genera el roomId asociado a este blog.
  String get roomId => 'blog_$id';

  /// Verifica si el blog está publicado.
  bool get isPublished => !isDraft && publishedTime > 0;

  /// Calcula el número de palabras del contenido.
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Estima el tiempo de lectura en minutos.
  String get estimatedReadTime {
    final minutes = (wordCount / 200).ceil();
    return '$minutes min';
  }

  @override
  String toString() {
    return 'BlogEntry{id: $id, ownerId: $ownerId, profileName: $profileName, title: $title, '
        'createdTime: $createdTime, modifiedTime: $modifiedTime, publishedTime: $publishedTime, '
        'isDraft: $isDraft, isHidden: $isHidden, viewCount: $viewCount, '
        'savedByProfiles: ${savedByProfiles.length}, hashtags: $hashtags}';
  }

  BlogEntry.fromJSON(dynamic data) :
        id = data["id"] ?? "",
        ownerId = data["ownerId"] ?? "",
        profileName = data["profileName"] ?? "",
        profileImgUrl = data["profileImgUrl"] ?? "",
        title = data["title"] ?? "",
        content = data["content"] ?? "",
        thumbnailUrl = data["thumbnailUrl"] ?? "",
        hashtags = List<String>.from(data["hashtags"] ?? []),
        createdTime = data["createdTime"] ?? 0,
        modifiedTime = data["modifiedTime"] ?? 0,
        publishedTime = data["publishedTime"] ?? 0,
        position = CoreUtilities.JSONtoPosition(data["position"]),
        location = data["location"] ?? "",
        isDraft = data["isDraft"] ?? true,
        isHidden = data["isHidden"] ?? false,
        isCommentEnabled = data["isCommentEnabled"] ?? true,
        themeMode = data["themeMode"] ?? 'dark',
        savedByProfiles = List<String>.from(data["savedByProfiles"] ?? []),
        viewCount = data["viewCount"] ?? 0,
        verificationLevel = EnumToString.fromString(
          VerificationLevel.values,
          data["verificationLevel"] ?? VerificationLevel.none.name,
        ) ?? VerificationLevel.none,
        legacyPostId = data["legacyPostId"];

  Map<String, dynamic> toJSON() => {
    'ownerId': ownerId,
    'profileName': profileName,
    'profileImgUrl': profileImgUrl,
    'title': title,
    'content': content,
    'thumbnailUrl': thumbnailUrl,
    'hashtags': hashtags,
    'createdTime': createdTime,
    'modifiedTime': modifiedTime,
    'publishedTime': publishedTime,
    'position': jsonEncode(position),
    'location': location,
    'isDraft': isDraft,
    'isHidden': isHidden,
    'isCommentEnabled': isCommentEnabled,
    'themeMode': themeMode,
    'savedByProfiles': savedByProfiles,
    'viewCount': viewCount,
    'verificationLevel': verificationLevel?.name,
    if (legacyPostId != null) 'legacyPostId': legacyPostId,
  };

  BlogEntry.createClone(BlogEntry entry) :
    id = entry.id,
    ownerId = entry.ownerId,
    profileName = entry.profileName,
    profileImgUrl = entry.profileImgUrl,
    title = entry.title,
    content = entry.content,
    thumbnailUrl = entry.thumbnailUrl,
    hashtags = List<String>.from(entry.hashtags),
    createdTime = entry.createdTime,
    modifiedTime = entry.modifiedTime,
    publishedTime = entry.publishedTime,
    position = entry.position,
    location = entry.location,
    isDraft = entry.isDraft,
    isHidden = entry.isHidden,
    isCommentEnabled = entry.isCommentEnabled,
    themeMode = entry.themeMode,
    savedByProfiles = List<String>.from(entry.savedByProfiles),
    viewCount = entry.viewCount,
    verificationLevel = entry.verificationLevel,
    legacyPostId = entry.legacyPostId;

  /// Convierte este BlogEntry a un Post para mostrarlo en el feed/timeline.
  /// El caption del Post incluirá un preview del contenido.
  /// El referenceId apunta al BlogEntry original.
  Map<String, dynamic> toFeedPost() {
    // Crear un preview del contenido (sin marcadores de formato)
    String preview = content
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1')  // Remove **bold**
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1')      // Remove *italic*
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'\1')      // Remove ~~strike~~
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // Remove # headers
        .replaceAll(RegExp(r'\n+'), ' ')                // Replace newlines with spaces
        .trim();

    // Limitar el preview a ~150 caracteres
    if (preview.length > 150) {
      preview = '${preview.substring(0, 147)}...';
    }

    // El caption será: Título + preview (o solo preview si no hay título)
    final caption = title.isNotEmpty
        ? '$title\n\n$preview'
        : preview;

    return {
      'ownerId': ownerId,
      'profileName': profileName,
      'profileImgUrl': profileImgUrl,
      'caption': caption,
      'type': 'blogEntry',
      'mediaUrl': '',
      'thumbnailUrl': thumbnailUrl,
      'externalUrl': '',
      'createdTime': createdTime,
      'modifiedTime': modifiedTime,
      'position': null,
      'location': location,
      'likedProfiles': <String>[],
      'sharedProfiles': <String>[],
      'savedByProfiles': savedByProfiles,
      'mentionedProfiles': <String>[],
      'commentIds': <String>[],
      'hashtags': hashtags,
      'isCommentEnabled': isCommentEnabled,
      'isPrivate': false,
      'isDraft': false,
      'isHidden': isHidden,
      'verificationLevel': verificationLevel?.name,
      'mediaOwner': '',
      'referenceId': id,  // Referencia al BlogEntry original
      'lastInteraction': DateTime.now().millisecondsSinceEpoch,
      'aspectRatio': 1,
      'textStyleId': '',
    };
  }

  /// Crea un BlogEntry a partir de un Post de tipo blogEntry (para migración).
  factory BlogEntry.fromLegacyPost(dynamic post, {String titleDivider = '|||TITLE|||'}) {
    String title = '';
    String content = '';

    // Parsear el caption que contiene título y contenido separados por divider
    final caption = post.caption ?? '';
    if (caption.contains(titleDivider)) {
      final parts = caption.split(titleDivider);
      title = parts[0].trim();
      content = parts.length > 1 ? parts[1].trim() : '';
    } else {
      content = caption;
    }

    return BlogEntry(
      id: '', // Se generará nuevo ID
      ownerId: post.ownerId ?? '',
      profileName: post.profileName ?? '',
      profileImgUrl: post.profileImgUrl ?? '',
      title: title,
      content: content,
      thumbnailUrl: post.thumbnailUrl ?? '',
      hashtags: List<String>.from(post.hashtags ?? []),
      createdTime: post.createdTime ?? 0,
      modifiedTime: post.modifiedTime ?? 0,
      publishedTime: (post.isDraft ?? true) ? 0 : (post.createdTime ?? 0),
      position: post.position,
      location: post.location ?? '',
      isDraft: post.isDraft ?? true,
      isHidden: post.isHidden ?? false,
      isCommentEnabled: post.isCommentEnabled ?? true,
      themeMode: 'dark',
      savedByProfiles: List<String>.from(post.savedByProfiles ?? []),
      viewCount: 0,
      verificationLevel: post.verificationLevel,
      legacyPostId: post.id,
    );
  }
}
