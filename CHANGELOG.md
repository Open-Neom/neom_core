## 1.4.0 - Architectural Changes and Major Refactoring

Dependency Inversion Principle (DIP) and Testability:

Created and/or refactored service interfaces (use_cases) for most core controllers, promoting decoupling and significantly improving testability:

UserService (interface for UserController).

MediaPlayerService (interface for MediaPlayerController).

ImageEditorService (interface for ImageEditorController).

AppHiveService (interface for AppHiveController).

GenresService (interface for GenresController).

DirectoryService (interface for DirectoryController).

AppDrawerService (interface for AppDrawerController).

Implementations of these services (e.g., UserController, MediaPlayerController) now explicitly implement their respective interfaces.

Adopted the two-step registration pattern in RootBinding for these services, linking the interface to its concrete implementation.

Consolidation and Clear Responsibilities:

AppUploadFirestore: Removed file upload methods (uploadImage, uploadVideo, uploadReleaseItem) from this class. The responsibility for binary file uploads now rests exclusively with neom_media_upload (MediaUploadService). AppUploadFirestore (if retained) would focus solely on managing upload metadata in Firestore.

UserController: Refactored to inject UserService into its consumers, and UserController is now the concrete implementation of UserService. Its state (user, profile) is accessible via the interface.

AppDrawerController: Refactored to implement AppDrawerService and inject UserService, removing direct dependencies on UserController and GetTickerProviderStateMixin if no longer needed.

Constants and Enums Management:

CoreConstants: Added and/or updated maximum file size constants (maxImageFileSize, maxVideoFileSize, maxAudioFileSize, maxPdfFileSize) with direct byte values.

CoreConstants: Expanded file extension lists (imageExtensions, videoExtensions, documentExtensions, audioExtensions) to include more common formats.

MediaUploadDestination: New enum created to define the context or destination of uploaded files (e.g., post, thumbnail, event), improving clarity in storage paths.

Performance and Maintainability Improvements:

Reduced App Size (Bundle Size): By delegating heavy functionalities and dependencies to specific modules (e.g., neom_media_upload, neom_image_editor), neom_core remains lighter, contributing to a smaller final application size.

Faster Compilation Speed: The reduction in direct dependencies within neom_core and the clear separation of responsibilities contribute to faster compilation times.

Clarity and Decoupling: The architecture is now easier to understand, maintain, and scale, as each module and service has a well-defined purpose and reduced coupling.