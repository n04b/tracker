# Tracker

A lightweight iOS app that continuously tracks the device's location and posts it as JSON to one or more HTTP endpoints you configure. It is meant for self-hosted setups: point it at your own server and get a live feed of where the device is, with battery status included.

## Features

- **Continuous background tracking.** Uses Core Location with background location updates, so tracking keeps running while the app is in the background.
- **Multiple servers.** Add as many endpoints as you like, toggle each one on or off, and edit or delete them at any time. The list is stored on the device.
- **Starts and stops on its own.** Tracking runs while at least one server is active and stops when none are.
- **Per-server status.** A dot next to each server shows its state: green when sending works, red when the last send failed, grey when the server is inactive.
- **Live coordinates.** Shows latitude, longitude, altitude and the time of the last successful send.
- **Device info.** Shows the device's `identifierForVendor`, which can be selected and copied, so you can tell devices apart on the server side.

## Requirements

- iOS 15.0 or later
- Xcode 14 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (the Xcode project is generated from `project.yml` and is not checked in)

## Getting started

1. Install XcodeGen:

   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:

   ```bash
   xcodegen generate
   ```

3. Open the project:

   ```bash
   open Tracker.xcodeproj
   ```

4. Pick your development team under **Signing & Capabilities**, change the bundle identifier if needed (the default prefix is `com.example`), then build and run on a device.

> Background location is best tested on a real device. The simulator can fake locations (**Features → Location**), but it doesn't behave the same way in the background.

## Usage

1. Launch the app and grant location access. For tracking in the background, choose **Always Allow** when iOS asks.
2. Tap **Add Server** and enter a name and the URL of your endpoint, e.g. `https://example.com/api/location`.
3. Make sure the server is toggled **Active**. Tracking starts right away.
4. Long-press a server to edit it, or swipe left to delete it.

## How it works

- The location manager runs at `kCLLocationAccuracyBest` with a 10 m distance filter, and automatic pausing is turned off.
- Every **5 seconds** the app takes the latest known location and sends it to every active server. If the location hasn't changed since the last successful send, nothing is sent.
- Each request times out after 10 seconds. Any non-2xx response counts as a failure, and that server is marked red until a later send to it succeeds.

## API

Each update is sent as an HTTP `POST` with `Content-Type: application/json`:

```json
{
  "identifierForVendor": "6F1C2A3B-4D5E-4F60-8172-93A4B5C6D7E8",
  "lat": 55.7558,
  "lon": 37.6173,
  "accuracy": 5.0,
  "altitude": 156.3,
  "speed": 1.4,
  "heading": 270.0,
  "batteryLevel": 0.82,
  "batteryState": "unplugged",
  "timestamp": 1761580800000
}
```

| Field                 | Type    | Description                                                                 |
| --------------------- | ------- | --------------------------------------------------------------------------- |
| `identifierForVendor` | string? | Device identifier for this vendor (`UIDevice.identifierForVendor`)          |
| `lat`                 | number  | Latitude in degrees                                                         |
| `lon`                 | number  | Longitude in degrees                                                        |
| `accuracy`            | number? | Horizontal accuracy in meters                                               |
| `altitude`            | number? | Altitude in meters                                                          |
| `speed`               | number? | Speed in m/s; omitted when not available                                    |
| `heading`             | number? | Course over ground in degrees (0–360); omitted when not available           |
| `batteryLevel`        | number? | Battery level from `0.0` to `1.0`; omitted when not available               |
| `batteryState`        | string? | `unplugged`, `charging` or `full`; omitted when unknown                     |
| `timestamp`           | integer | Time the location was recorded, in Unix milliseconds                        |

Fields that have no value are left out of the JSON. Your server should reply with a `2xx` status code to confirm it received the update.

## Project structure

```
Sources/
├── TrackerApp.swift            # App entry point
├── Models/
│   ├── LocationPayload.swift   # JSON payload sent to servers
│   └── ServerConfig.swift      # Server endpoint configuration
├── Services/
│   ├── LocationService.swift   # Core Location wrapper
│   ├── NetworkService.swift    # HTTP client that posts payloads
│   └── TrackingService.swift   # Tracking loop, server list and persistence
└── Views/
    ├── ContentView.swift       # Main screen: coordinates, servers, device info
    └── AddServerView.swift     # Add / edit server form
Tracker/Info.plist              # Permissions and background modes
project.yml                     # XcodeGen project spec
```

## Privacy and security notes

- Location data goes **only** to the servers you add. There is no analytics and no third-party service.
- `NSAllowsArbitraryLoads` is turned on so the app can reach plain `http://` endpoints, such as a server on your local network. Use `https://` for anything that goes over the internet.
- Requests carry no authentication. If your endpoint is public, protect it, for example with a secret token in the URL path or behind a reverse proxy that checks credentials.
