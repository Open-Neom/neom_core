# neom_core
Core for Open Neom Modules.
neom_core serves as the foundational package for the entire Open Neom ecosystem.
It is meticulously designed to encapsulate the absolute essentials:
the central business logic, fundamental data models, and the universal abstract interfaces
(services) that define the contracts for communication across all other modules.
This package is key to embodying the foundational principles for integrating neuroscience
and biofeedback within the platform's robust, modular, and testable architecture.

🌟 Features & Responsibilities
neom_core is the backbone of the Open Neom platform, responsible for:
•	Universal Models & Enums: Defining core data models (e.g., AppUser, AppProfile, Post base structure)
    and universal enums (e.g., MediaType, MediaUploadDestination, UserRole, SubscriptionLevel)
    that are utilized across the entire Neom ecosystem.
•	Core Services Interfaces (Use Cases): Providing abstract interfaces (services) for fundamental
    functionalities that are consumed by multiple modules. This adheres to the Dependency Inversion Principle (DIP),
    ensuring minimal coupling and facilitating flexible implementations.
•	Infrastructure Utilities: Offering essential, application-wide utilities for concerns such as logging (AppConfig),
    application routing constants (AppRouteConstants), and common Firebase-related constants.
•	Base Implementations: Housing the core implementations for foundational services like UserController
    (implementing UserService) and AppHiveController (implementing AppHiveService), which are then registered
    and injected at the application's composition root.
•	Firebase Integration (Core Services): Managing the foundational Firebase SDKs (firebase_core, cloud_firestore,
    cloud_functions, firebase_storage, firebase_auth, firebase_messaging, firebase_crashlytics) that provide essential
    backend services for data persistence, cloud functions, and messaging.
•	Authentication Integration: Incorporating core authentication SDKs (firebase_auth, google_sign_in, sign_in_with_apple,
    googleapis_auth) to provide the fundamental layers for user authentication flows across the ecosystem.
•	Location & Maps Integration: Providing core functionalities and models related to geolocation (geolocator, geocoding)
    and map services (Maps_flutter, google_api_headers, neom_maps_services, neom_google_places).
•	In-App Purchase Integration: Handling the foundational integration for platform-specific in-app purchase functionalities.
•	Dynamic Configuration & Flavor Management (AppConfig & AppProperties):
    -	AppConfig: Manages application-wide configurations, including the active application flavor (AppInUse),
    current app versioning, and logic for selecting the appropriate root page based on authentication status or version compatibility.
    It centralizes initialization flows and provides a global logger instance.
    -	AppProperties: Facilitates the loading of dynamic properties from JSON assets (e.g., properties.json, service_account.json).
    This allows for granular, flavor-specific data such as API keys, external URLs, contact information, and other configurable values
    to be managed outside the codebase, enabling modifications without requiring code changes or recompilation for different application flavors.


📦 Installation
Add neom_core to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  neom_core: ^2.0.0
```

Then, run `flutter pub get` in your project's root directory.

🚀 Usage
As a foundational package, neom_core is primarily consumed by other domain-specific Neom modules (e.g., neom_auth, neom_home, neom_posts)
and the main application (neom_app). It is not typically used to build direct UI components but rather provides the underlying contracts and data.

Example of consuming a core service interface (e.g., in neom_posts):
Dart
// In a controller from another module (e.g., neom_posts)
import 'package:sint/sint.dart';
import 'package:neom_core/core/domain/use_cases/user_service.dart'; // Import the interface from neom_core

class MyFeatureController extends SintController {
    // Inject the UserService interface
    final UserService _userService = Sint.find<UserService>();

    void displayUserName() {
        print("Current User: ${_userService.user.name}");
    }
}

Registering the implementation at the Composition Root (e.g., in neom_app/lib/root_binding.dart):
Dart
// In your main application's RootBinding
import 'package:sint/sint.dart';
import 'package:neom_core/core/domain/use_cases/user_service.dart'; // Interface from neom_core
import 'package:neom_core/core/data/implementations/user_controller.dart'; // Implementation from neom_core

class RootBinding extends SintBinding {
    @override
    List<Bind> dependencies() {
        return [
            // Register the concrete implementation (UserController)
            Bind.put(UserController(), permanent: true),
            // Bind the interface (UserService) to the concrete implementation
            Bind.lazyPut<UserService>(() => Sint.find<UserController>(), fenix: true),
            // ... other core service bindings
        ];
    }
}

🛠️ Dependencies
neom_core relies on the following key packages to provide its foundational functionalities:
•	flutter: The Flutter SDK.
•	sint: For state management and robust dependency injection.
•	Firebase SDKs: firebase_core, cloud_firestore, cloud_functions, firebase_storage, firebase_auth, firebase_messaging,
    firebase_crashlytics for comprehensive backend services.
•	Authentication: google_sign_in, sign_in_with_apple, googleapis_auth for various user authentication methods.
•	System Utilities: logger, url_launcher, http, hive_flutter, path_provider, rflutter_alert, enum_to_string,
    package_info_plus, upgrader, permission_handler.
•	Location & Maps: geolocator, geocoding, Maps_flutter, google_api_headers, neom_maps_services, neom_google_places.
•	Networking & Caching: cached_network_image.
•	In-App Purchases: in_app_purchase.

🤝 Contributing
We welcome contributions to neom_core! Please refer to the main Open Neom repository for detailed contribution guidelines and code of conduct.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
