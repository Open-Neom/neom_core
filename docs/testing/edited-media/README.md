# Edited media core contract and metadata — 2026-10-15

Added optional `EditedMediaReceiver` without changing `MediaUploadService` or the
upload repository signature. Implementations must stage before commit, honor the
provided current-draft guard, return false for stale output and throw for errors.

`UploadMetadataResolver.resolveBytesExtension` recognizes the eight-byte PNG
signature for image byte uploads. `AppUploadFirestore.uploadMediaBytes` uses this
extension for both filename and MIME metadata. Other formats retain historical
fallbacks. This resolver identifies upload metadata; it does not decode/validate
an entire image. Edited-media ingestion validates its own container structure.

- [metadata-vm.log](metadata-vm.log): 10 tests passed, including PNG signature,
  truncated signature, JPEG/defaults and media-type isolation.
- [analyze.log](analyze.log): changed interface/resolver/Firestore integration/test
  analyzed with fatal infos; no issues.

No Firebase uploads were made. Runtime receiver evidence belongs to
`neom_media_upload/docs/testing/edited-media`.
