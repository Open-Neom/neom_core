/// A shared file within a collective workspace.
///
/// Stored as subcollection `collectives/{id}/files/{fileId}`.
/// Supports various file types grouped by optional folders.
class CollectiveFile {

  String id;
  String collectiveId;
  String name;
  String description;
  String url;
  String thumbnailUrl;
  String fileType;  // 'pdf', 'image', 'audio', 'video', 'document', 'other'
  int fileSize;     // bytes
  String uploadedBy;    // profile ID
  String uploaderName;
  String uploaderImgUrl;
  String folder;    // optional folder grouping (e.g. 'demos', 'docs', 'fotos')
  int createdAt;

  CollectiveFile({
    this.id = '',
    this.collectiveId = '',
    this.name = '',
    this.description = '',
    this.url = '',
    this.thumbnailUrl = '',
    this.fileType = 'other',
    this.fileSize = 0,
    this.uploadedBy = '',
    this.uploaderName = '',
    this.uploaderImgUrl = '',
    this.folder = '',
    this.createdAt = 0,
  });

  Map<String, dynamic> toJSON() => {
    'collectiveId': collectiveId,
    'name': name,
    'description': description,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'fileType': fileType,
    'fileSize': fileSize,
    'uploadedBy': uploadedBy,
    'uploaderName': uploaderName,
    'uploaderImgUrl': uploaderImgUrl,
    'folder': folder,
    'createdAt': createdAt,
  };

  factory CollectiveFile.fromJSON(Map<String, dynamic> data) => CollectiveFile(
    id: data['id'] ?? '',
    collectiveId: data['collectiveId'] ?? '',
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    url: data['url'] ?? '',
    thumbnailUrl: data['thumbnailUrl'] ?? '',
    fileType: data['fileType'] ?? 'other',
    fileSize: data['fileSize'] ?? 0,
    uploadedBy: data['uploadedBy'] ?? '',
    uploaderName: data['uploaderName'] ?? '',
    uploaderImgUrl: data['uploaderImgUrl'] ?? '',
    folder: data['folder'] ?? '',
    createdAt: data['createdAt'] ?? 0,
  );

  @override
  String toString() => 'CollectiveFile{id: $id, name: $name, collectiveId: $collectiveId, fileType: $fileType, folder: $folder}';
}
