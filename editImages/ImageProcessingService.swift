//
//  ImageProcessingService.swift
//  editImages
//
//  Created by Luciano Castro on 18/08/2025.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Image Processing Protocol
/// Protocol defining the interface for image processing and filter application.
/// This protocol enables dependency injection and facilitates unit testing.
protocol ImageProcessingServiceType {
    /// Applies a CPM35-like film filter to the provided image.
    /// The filter simulates the look of classic film photography with warm tones,
    /// lifted blacks, soft highlights, and subtle grain.
    /// - Parameter image: The source UIImage to be processed
    /// - Returns: A new UIImage with the CPM35 filter applied
    /// - Throws: ImageProcessingError if the processing fails
    func applyCPM35Like(to image: UIImage) async throws -> UIImage
}

// MARK: - Implementation
class ImageProcessingService: ImageProcessingServiceType {
    
    // MARK: - Shared Context
    /// Reusable CIContext for optimal performance and memory usage.
    /// Configured with sRGB color space for consistent color reproduction across devices.
    private static let sharedContext: CIContext = {
        CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])
    }()
    
    // MARK: - CPM35 Filter Constants
    private struct CPM35Constants {
        static let temperatureNeutral = CIVector(x: 6500, y: 0)
        static let temperatureTarget  = CIVector(x: 5800, y: 0)

        static let saturation: Float = 0.95
        static let brightness: Float = -0.02
        static let contrast:   Float = 0.90

        static let toneCurvePoints = [
            CGPoint(x: 0.00, y: 0.08),
            CGPoint(x: 0.25, y: 0.24),
            CGPoint(x: 0.50, y: 0.48),
            CGPoint(x: 0.75, y: 0.78),
            CGPoint(x: 1.00, y: 0.96)
        ]

        static let shadowsColor = CIColor(red: 0.12, green: 0.18, blue: 0.18)
        static let highlightsColor = CIColor(red: 1.04, green: 0.93, blue: 0.83)
        static let splitToningIntensity: Float = 0.25

        static let bloomRadius: Float = 2.5
        static let bloomIntensity: Float = 0.25

        static let vignetteIntensity: Float = 0.2
        static let vignetteRadius: Float = 1.2

        static let grainAlpha: Float = 0.50
    }
    
    func applyCPM35Like(to image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.processImage(image)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Processing Methods
    /// Core image processing pipeline that applies the CPM35 filter step by step.
    /// Each step builds upon the previous one to create the final film-like effect.
    /// - Parameter image: The source UIImage to be processed
    /// - Returns: A new UIImage with all filter effects applied
    /// - Throws: ImageProcessingError if any step in the pipeline fails
    private func processImage(_ image: UIImage) throws -> UIImage {
        guard let ciImage = CIImage(image: image) else { throw ImageProcessingError.invalidInput }
        var img = ciImage

        // Step 1: Temperature adjustment
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(img, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CPM35Constants.temperatureNeutral, forKey: "inputNeutral")
            temperatureFilter.setValue(CPM35Constants.temperatureTarget, forKey: "inputTargetNeutral")
            img = temperatureFilter.outputImage ?? img
        }

        // Step 2: Color controls
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = img
        colorControls.saturation = CPM35Constants.saturation
        colorControls.brightness = CPM35Constants.brightness
        colorControls.contrast = CPM35Constants.contrast
        img = colorControls.outputImage ?? img

        // Step 3: Tone curve
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = img
        toneCurve.point0 = CPM35Constants.toneCurvePoints[0]
        toneCurve.point1 = CPM35Constants.toneCurvePoints[1]
        toneCurve.point2 = CPM35Constants.toneCurvePoints[2]
        toneCurve.point3 = CPM35Constants.toneCurvePoints[3]
        toneCurve.point4 = CPM35Constants.toneCurvePoints[4]
        img = toneCurve.outputImage ?? img

        // Step 4: Subtle green tint
        let greenTint = CIFilter.colorMatrix()
        greenTint.inputImage = img
        greenTint.rVector = CIVector(x: 0.99, y: 0, z: 0, w: 0)
        greenTint.gVector = CIVector(x: 0, y: 1.01, z: 0, w: 0)
        greenTint.bVector = CIVector(x: 0, y: 0, z: 0.99, w: 0)
        greenTint.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        img = greenTint.outputImage ?? img

        // Step 5: Split-toning
        img = applySplitToning(base: img,
                               shadows: CPM35Constants.shadowsColor,
                               highlights: CPM35Constants.highlightsColor,
                               intensity: CPM35Constants.splitToningIntensity)

        // Step 6: Bloom
        let bloom = CIFilter.bloom()
        bloom.inputImage = img
        bloom.intensity = CPM35Constants.bloomIntensity
        bloom.radius = CPM35Constants.bloomRadius
        img = bloom.outputImage ?? img

        // Step 7: Film grain
        let grain = createFilmGrain(for: img, alpha: CPM35Constants.grainAlpha)
        img = blend(grain, over: img, mode: "CISoftLightBlendMode")

        // Step 8: Vignette
        let vignette = CIFilter.vignette()
        vignette.inputImage = img
        vignette.intensity = CPM35Constants.vignetteIntensity
        vignette.radius = CPM35Constants.vignetteRadius
        img = vignette.outputImage ?? img

        // Render final
        guard let cg = Self.sharedContext.createCGImage(img, from: img.extent) else {
            throw ImageProcessingError.renderingFailed
        }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Helper Methods
    
    private func applySplitToning(base: CIImage, shadows: CIColor, highlights: CIColor, intensity: Float) -> CIImage {
        guard let falseColor = CIFilter(name: "CIFalseColor",
                                        parameters: [kCIInputImageKey: base,
                                                     "inputColor0": shadows,
                                                     "inputColor1": highlights])?.outputImage
        else { return base }

        let soft = CIFilter(name: "CISoftLightBlendMode",
                            parameters: [kCIInputImageKey: falseColor, kCIInputBackgroundImageKey: base])?.outputImage ?? base

        return lerp(base: base, overlay: soft, t: intensity)
    }

    private func lerp(base: CIImage, overlay: CIImage, t: Float) -> CIImage {
        let mask = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: CGFloat(t))).cropped(to: base.extent)
        return CIFilter(name: "CIBlendWithAlphaMask",
                        parameters: [
                            kCIInputImageKey: overlay,
                            kCIInputBackgroundImageKey: base,
                            kCIInputMaskImageKey: mask
                        ])?.outputImage ?? overlay
    }

    private func createFilmGrain(for baseImage: CIImage, alpha: Float) -> CIImage {
        guard let noise = CIFilter.randomGenerator().outputImage?.cropped(to: baseImage.extent) else { return baseImage }

        let gray = CIFilter.colorControls()
        gray.inputImage = noise
        gray.saturation = 0.0
        let grayNoise = gray.outputImage ?? noise

        let matrix = CIFilter.colorMatrix()
        matrix.inputImage = grayNoise
        matrix.rVector = CIVector(x: 0.35, y: 0, z: 0, w: 0)
        matrix.gVector = CIVector(x: 0, y: 0.28, z: 0, w: 0)
        matrix.bVector = CIVector(x: 0, y: 0, z: 0.28, w: 0)
        matrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(alpha))
        matrix.biasVector = CIVector(x: 0.32, y: 0.32, z: 0.32, w: 0)
        return matrix.outputImage?.cropped(to: baseImage.extent) ?? baseImage
    }

    private func blend(_ top: CIImage, over bottom: CIImage, mode: String) -> CIImage {
        guard let f = CIFilter(name: mode) else { return bottom }
        f.setValue(top, forKey: kCIInputImageKey)
        f.setValue(bottom, forKey: kCIInputBackgroundImageKey)
        return f.outputImage?.cropped(to: bottom.extent) ?? bottom
    }
}

// MARK: - Errors
enum ImageProcessingError: Error, LocalizedError {
    case invalidInput
    case filterFailed(String)
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input image"
        case .filterFailed(let filterName):
            return "Error applying filter: \(filterName)"
        case .renderingFailed:
            return "Error rendering final image"
        }
    }
}
