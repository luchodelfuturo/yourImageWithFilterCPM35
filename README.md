# 📱 iOS Image Editor with CPM35-like Filter

A professional iOS image editing app that applies a CPM35-like film filter to photos, built with modern iOS development practices.

## 🎯 Features

- **CPM35-like Film Filter**: Simulates classic film photography with warm tones, lifted blacks, and soft highlights
- **MVVM Architecture**: Clean separation of concerns with Combine for reactive programming
- **Core Image Pipeline**: High-performance GPU-accelerated image processing
- **Modern UI**: Programmatic UI with smooth animations and responsive design
- **Photo Integration**: Seamless photo selection using PHPicker
- **Before/After Comparison**: Toggle between original and filtered images
- **Save to Photos**: Export filtered images to the photo library

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

### Modern Swift Features
- **Async/Await**: Non-blocking image processing
- **Combine**: Reactive UI updates
- **Protocols**: Dependency injection and testability
- **Core Image**: GPU-accelerated processing

### Performance Optimizations
- **Shared CIContext**: Reused for better performance
- **Background Processing**: UI remains responsive
- **Memory Management**: Proper cleanup and optimization
- **Color Space**: sRGB for consistent results

## 📱 Usage

1. **Load Image**: Tap "Load" to select a photo from your library
2. **Apply Filter**: Tap "Filter" to apply the CPM35-like effect
3. **Compare**: Use "Before/After" to toggle between original and filtered
4. **Save**: Tap "Save" to export the result to your photo library

## 🧪 Testing

The architecture supports easy testing:
- **Protocols**: Mock services for unit testing
- **MVVM**: Test business logic independently
- **Combine**: Test reactive streams
- **Dependency Injection**: Inject test doubles

## 🔮 Future Enhancements

- [ ] Multiple filter presets
- [ ] Real-time filter intensity adjustment
- [ ] Custom filter parameters
- [ ] Batch processing
- [ ] Social media sharing
- [ ] Filter history

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

Built with ❤️ for demonstrating modern iOS development practices and Core Image capabilities.

---

**Perfect for:** iOS developer portfolios, Core Image learning, MVVM architecture examples, and photo editing app demos.
