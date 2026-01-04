# PokeWatch

PokeWatch is a SwiftUI iOS app that watches the nowinstock.net Pokemon card tracker and alerts you when any store shows inventory.

## Features
- Polls the nowinstock.net tracker at a 60-second cadence.
- Parses the tracker HTML without external dependencies.
- Presents a SwiftUI list of stores and their current status.
- Fires a local notification whenever a store transitions to **In Stock**.
- Requests and registers for remote notifications so the device token can be wired into your push provider.

## Project layout
- `PokeWatchApp.swift`: Application entry point with push registration via `AppDelegate`.
- `Views/ContentView.swift`: SwiftUI UI that lists store statuses and provides manual refresh.
- `ViewModels/TrackerViewModel.swift`: Coordinates polling, change detection, and notifications.
- `Services/TrackerService.swift`: Downloads and parses the tracker HTML.
- `Services/NotificationService.swift`: Manages notification permissions and scheduling.
- `Models/StockEntry.swift`: Data models and status helpers.

## Running the app
1. Open the project in Xcode (create an Xcode project using these sources if one is not already present).
2. Ensure the target has the **Push Notifications** capability enabled if you plan to deliver remote pushes.
3. Update the bundle identifier and provisioning profile as needed.
4. Build and run on a device (stock alerts are most meaningful on-device).

## Notes on notifications
- The app posts a local notification when a store status moves from not-in-stock to in-stock.
- The device token is captured in `NotificationService` for wiring into your push pipeline if you add a server component.
