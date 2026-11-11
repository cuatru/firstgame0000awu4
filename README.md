# firstgame0000awu4 — FlowWatch

A standalone watchOS app containing two small, fluid games:

- **HALO:** tap-to-time orbital gameplay, twelve gates per run.
- **CURRENT:** hold/release movement through a 35-second gate course.

Designed for a 49 mm Apple Watch Ultra-class display. It uses SwiftUI materials,
animated gradients, SpriteKit, local personal bests, and WatchKit haptics.
There is no companion iPhone app, networking, advertising, analytics, account,
or in-app purchase.

## Requirements

- macOS with a current Xcode installation and watchOS SDK
- XcodeGen: `brew install xcodegen`
- watchOS 11 or later on the destination device/simulator

## Open and run

```sh
cd ~/Desktop/firstgame0000awu4
make open
```

In Xcode:

1. Select the **FlowWatch** scheme.
2. Select a 49 mm Apple Watch Ultra simulator or your physical watch.
3. For a physical device, choose your development team and, if necessary,
   change the bundle identifier.
4. Press **Run**.

## Build and tests

```sh
make build
```

Run tests using the exact simulator name available on your Mac:

```sh
make test \
  WATCH_DESTINATION='platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm)'
```

The GitHub Actions workflow generates the project and performs a watchOS
simulator-SDK build. The generated `.xcodeproj` is intentionally ignored;
`project.yml` is its reproducible source.

## Device targeting

`TARGETED_DEVICE_FAMILY=4` makes this a watch-only app. Apple does not expose a
supported App Store switch for limiting distribution to a single marketing
model such as a particular Ultra generation. No unverified hardware-model lock
is included.

## Research and design

See [`docs/engagement-research.md`](docs/engagement-research.md). The project
uses engagement research without implementing gambling-like rewards, punitive
streaks, manipulative notifications, or infinite sessions.

## Repository layout

```text
firstgame0000awu4/
├── .github/workflows/build.yml
├── Sources/FlowWatch/
│   ├── FlowWatchApp.swift
│   ├── GameRules.swift
│   ├── GlassStyle.swift
│   ├── HaloScene.swift
│   ├── CurrentScene.swift
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── Tests/FlowWatchTests/GameRulesTests.swift
├── docs/engagement-research.md
├── project.yml
├── Makefile
└── README.md
```

## First Git commit

```sh
git add .
git commit -m "Add FlowWatch games for Apple Watch"
```

Create an empty GitHub repository, then add its URL as `origin` and push `main`.
