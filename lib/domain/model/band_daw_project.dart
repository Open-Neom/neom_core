/// Status of a DAW project in its lifecycle.
///
/// Mirrors `DawProjectStatus` declared in `neom_daw` so JSON documents in
/// the shared `dawProjects` Firestore collection round-trip across both
/// modules.
enum BandDawProjectStatus {
  draft,
  recording,
  mixing,
  published,
  archived,
}

/// Lightweight projection of a DAW project for surfaces that only need
/// summary information (id, name, BPM, status, ownership) — typically the
/// band details / band studio tab.
///
/// This model lives in `neom_core` so consumers like `neom_bands` can show
/// and create DAW projects without depending on the full `neom_daw`
/// module. It writes a strict subset of the same Firestore document shape
/// used by `DawProject` in `neom_daw`, so the editor in `neom_daw` can read
/// the projects this class creates and vice versa.
class BandDawProject {
  String id;
  String name;
  String description;
  String ownerId;
  String ownerName;
  String ownerImgUrl;
  String? bandId;
  String? bandName;
  int bpm;
  int trackCount;
  String? coverImgUrl;
  BandDawProjectStatus status;
  int createdTime;
  int updatedTime;

  BandDawProject({
    this.id = '',
    this.name = '',
    this.description = '',
    this.ownerId = '',
    this.ownerName = '',
    this.ownerImgUrl = '',
    this.bandId,
    this.bandName,
    this.bpm = 120,
    this.trackCount = 0,
    this.coverImgUrl,
    this.status = BandDawProjectStatus.draft,
    this.createdTime = 0,
    this.updatedTime = 0,
  });

  bool get isBandProject => bandId != null && bandId!.isNotEmpty;

  /// Builds the JSON payload for inserting/updating into the
  /// `dawProjects` collection. Only writes the fields this lightweight
  /// model owns — the editor in `neom_daw` will fill in tracks, buses,
  /// tempo map, etc. on first open.
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImgUrl': ownerImgUrl,
      'bandId': bandId,
      'bandName': bandName,
      'bpm': bpm,
      'trackCount': trackCount,
      'coverImgUrl': coverImgUrl,
      'status': status.name,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
    };
  }

  factory BandDawProject.fromJSON(dynamic json) {
    return BandDawProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      ownerImgUrl: json['ownerImgUrl']?.toString() ?? '',
      bandId: json['bandId']?.toString(),
      bandName: json['bandName']?.toString(),
      bpm: (json['bpm'] as num?)?.toInt() ?? 120,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      coverImgUrl: json['coverImgUrl']?.toString(),
      status: BandDawProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BandDawProjectStatus.draft,
      ),
      createdTime: (json['createdTime'] as num?)?.toInt() ?? 0,
      updatedTime: (json['updatedTime'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() =>
      'BandDawProject{id: $id, name: $name, bandId: $bandId, bpm: $bpm, status: $status}';
}
