# Web Browser Notifications Support for Tamagonscrit

Since the game runs primarily on web browsers (`Flutter Web`), `flutter_local_notifications` is not supported on web. We need to implement browser-native notifications using the Web Notifications API (`dart:html` / browser `Notification` API) and timed triggers (`Future.delayed` / `Timer`).

## User Review Required

- **Web Permissions**: Browsers require explicit user permission (`Notification.requestPermission()`). When notifications are enabled, a browser prompt will appear asking the user to allow notifications.
- **Background Limitation on Web**: Browser notifications work via `Future.delayed` / `Timer` while the web tab is open (or running in background tabs where timers are active).

## Open Questions

- None.

## Proposed Changes

### Notification Service Refactoring
#### [MODIFY] [notification_service.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/services/notification_service.dart)
- Detect if running on Web (`kIsWeb`).
- If on Web:
  - Request permission via `html.Notification.requestPermission()`.
  - Schedule milestone alerts using `Future.delayed` for each calculated duration (energy = 0, birse = 50/100, trads = 0/50/100).
  - Trigger browser notifications using `html.Notification(title, body: body)`.
- If on mobile (Android/iOS):
  - Keep using `flutter_local_notifications`.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify compilation across platforms.

### Manual Verification
- Run app on Flutter Web (`flutter run -d chrome`), enable notifications in Profile, test starting an activity (e.g. Birse or Ronque) and verify browser notification when threshold is reached.
