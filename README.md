# 📱 iOS Image Editor with CPM35-like Filter

## 🎯 Features

- **CPM35-like Film Filter**: Simulates classic film photography with warm tones, lifted blacks, and soft highlights
  
## 🏗️ Architecture

### MVVM + Combine
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   View (UI)     │◄──►│   ViewModel      │◄──►│   Services      │
│ FilterViewController│ │ FilterViewModel  │    │ PhotoPicker     │
│                 │    │ (@Published)     │    │ ImageProcessor  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Core Image Pipeline
The CPM35-like filter consists of 5 main steps:

1. **Temperature Adjustment**: Makes the image warmer (6500K → 5200K)
2. **Color Controls**: Enhances saturation, brightness, and contrast
3. **Tone Curve**: Lifts blacks and softens highlights for film-like appearance
4. **Film Grain**: Adds subtle photographic grain texture
5. **Vignette**: Darkens edges to focus attention on the center

## 🚀 Getting Started

### Prerequisites
- Xcode 13.0+
- iOS 15.0+
- Swift 5.5+

### Installation
1. Clone the repository
```bash
git clone https://github.com/luchodelfuturo/yourImageWithFilterCPM35.git
```

2. Open the project in Xcode
```bash
open editImages.xcodeproj
```

3. Build and run on your device or simulator

### Permissions
The app requires photo library access. Add these keys to `Info.plist`:
- `NSPhotoLibraryUsageDescription`: For loading photos
- `NSPhotoLibraryAddUsageDescription`: For saving filtered images

## 📁 Project Structure

```
editImages/
├── AppDelegate.swift              # App lifecycle management
├── SceneDelegate.swift            # Window and scene setup
├── FilterViewController.swift     # Main UI with programmatic layout
├── FilterViewModel.swift          # Business logic with Combine
├── PhotoPickerService.swift       # Photo selection service
├── ImageProcessingService.swift   # Core Image filter pipeline
└── Info.plist                     # App configuration
```

## 🎨 Filter Details

### CPM35 Constants
```swift
// Temperature: 6500K → 5200K (warmer)
// Saturation: 1.15 (more vivid)
// Brightness: 0.02 (slightly brighter)
// Contrast: 1.08 (enhanced)
// Grain Alpha: 0.07 (subtle texture)
// Vignette: 0.8 intensity, 1.8 radius
```

### Tone Curve Points
```
(0, 0.05)   → Lift blacks
(0.25, 0.23) → Shadow adjustment
(0.5, 0.5)   → Midtones unchanged
(0.75, 0.78) → Highlight adjustment
(1, 0.95)    → Soft highlights
```

## 🔧 Technical Highlights


## 📱 Usage

1. **Load Image**: Tap "Load" to select a photo from your library
2. **Apply Filter**: Tap "Filter" to apply the CPM35-like effect
3. **Compare**: Use "Before/After" to toggle between original and filtered
4. **Save**: Tap "Save" to export the result to your photo library

