# BLP Tools

**BLP Tools** is an iOS app I built to enhance the functionality of the Bushnell Launch Pro (BLP) launch monitor. It makes it easier to see the shot data from the screen, includes additional estimated shot metrics, a mini-game mode for practicing, and integrates with GSPro.

### Features

- **Unified Data View**: Displays ball and club data together on one screen (no constant switching away from the launch data).
- **Mini-Game Mode**: Score shots based on proximity to targets. Includes modes for regular shots and putting.
- **Estimated Ball Metrics**: Provides additional estimated parameters like total distance, offline distance, and apex height.
- **GSPro Integration**: Connects to [GSPro via OpenConnect](https://gsprogolf.com/GSProConnectV1.html) for data sharing.

## Why?

I was frustrated by not being able to customize the BLP display and especially annoyed by how rapidly the screens switched, making it hard to read numbers clearly. I wanted:

- All important data on a single screen.
- To gamify range sessions.
- Total / offline distances.
- Easy integration with GSPro.

## Installation

### Requirements

- macOS device (to build the app).
- iPhone (tested specifically on iPhone 15 Pro).
- A 3D printer to make the phone mount ([link](https://makerworld.com/en/models/1300907-bushnell-launch-pro-blp-iphone-holder#profileId-1333225)), or using a service to 3D print it for you.

### Step-by-step Installation

1. **Download the source code: [Link](https://github.com/heapsheeps/blp-tools/archive/refs/heads/main.zip)**
   - *Optional for developers: you can clone this repo instead, just ensure you clone it recursively to grab the submodule, and that you have git-lfs installed which is required for the submodule*

2. **Setup Xcode**
    - Install [Xcode](https://developer.apple.com/xcode/) from the Mac App Store.
    - Open `blp-ocr-ios.xcodeproj` located in the root folder.

3. **Provisioning Profile Setup**
    - Connect your iPhone to your Mac.
    - Select your device in Xcode (top menu bar).
    - Under "Signing & Capabilities," select your Apple ID account. Xcode may prompt you to create a free provisioning profile.

4. **Build and Run**
    - Press the ▶️ button in Xcode.
    - On first run, allow the app installation:
      - On your iPhone, go to **Settings → General → VPN & Device Management**.
      - Tap on your developer profile and select "Trust".

The app should now be installed on your device and running.

## Quickstart

- Launch the app.
- Rest your iPhone on the recommended [3D printed mount](https://makerworld.com/en/models/1300907-bushnell-launch-pro-blp-iphone-holder#profileId-1333225).
- Take a shot; data should populate on the screen immediately.

## Usage

- **Data Page**: Shows the last shot’s ball and club data.
    - "Start Mini Game": Select target distances, hit shots, and score based on accuracy.
- **Screens Page**: Displays captured images from the last shot, useful if you prefer the normal BLP interface.
- **Camera Page**: Shows the live camera feed, primarily for debugging. A green box indicates proper BLP screen detection.
- **Settings Page**: Adjust fairway and green speeds (used for distance estimation), and configure the GSPro IP.

## Caveats and Limitations

- Only tested on **iPhone 15 Pro**.
- No Android version planned due to reliance on Apple's Vision framework and Objective-C.
- For best OCR results, use the recommended [3D printed phone holder](https://makerworld.com/en/models/1300907-bushnell-launch-pro-blp-iphone-holder#profileId-1333225).

### Known Issues (Potentially Future Enhancements)
*I have not needed to address for my personal use, but if there is more demand, I would consider fixing.*
- Currently only works with default BLP settings: MPH, yards, and spin axis/rate (instead of backspin/sidespin).
- Does not work outdoors in bright sunlight (likely fixable with improved exposure settings or a specialized mount).

## Project Details
- 90%+ of the code in this repo was written with AI and not built for readability/consistency/extensibility, and lacks almost any documentation. Apologies in advance. It was a weekend project that turned into a little bit more.
- The app uses the ultra-wide camera and looks for a bright patch in the image (the BLP screen). Once it's detected the screen, it uses [Vision framework](https://developer.apple.com/documentation/vision/recognizing-text-in-images?language=objc) for OCR and several other special-purpose CNN detectors for consistent text (like HLA direction "L/R", and AOA "UP/DOWN", etc).
- Includes custom-trained CNN models for specific text detection (e.g., spin direction, angle of attack).
- There are various python and web helpers:
  - `python/blp-annotator`: Tool for annotating BLP screen positions.
  - `python/blp-trainer`: Trains other non-OCR detection CNNs.
  - `python/ballflight`: Estimates additional flight parameters.
  - See `python/README.md` for more details.

## About
[Heapsheeps LLC](https://heapsheeps.com/) is a side project of mine. I mostly work on apps and golf software, looking for ways to build helpful tools and maybe some day finding a way to make it full time effort. 
If you don't like losing golf balls on the course, check out my other app, [Fore Finder](https://apps.apple.com/us/app/fore-finder/id6478720860).
