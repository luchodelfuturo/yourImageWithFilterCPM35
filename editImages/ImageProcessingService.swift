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
        // Temperature adjustment (makes image warmer)
        static let temperatureNeutral = CIVector(x: 6500, y: 0)  // Standard daylight
        static let temperatureTarget = CIVector(x: 5200, y: 0)   // Warmer tone
        
        // Color adjustments for film-like look
        static let saturation: Float = 1.15    // More vivid colors
        static let brightness: Float = 0.02    // Slightly brighter
        static let contrast: Float = 1.08      // More contrast
        
        // Tone curve for lifted blacks and soft highlights (creates film look)
        static let toneCurvePoints = [
            CGPoint(x: 0, y: 0.05),    // Lift blacks (no pure black)
            CGPoint(x: 0.25, y: 0.23), // Shadow adjustment
            CGPoint(x: 0.5, y: 0.5),   // Midtones unchanged
            CGPoint(x: 0.75, y: 0.78), // Highlight adjustment
            CGPoint(x: 1, y: 0.95)     // Soft highlights (no pure white)
        ]
        
        // Film grain simulation
        static let grainAlpha: Float = 0.07    // Grain opacity
        
        // Vignette (darkens edges)
        static let vignetteIntensity: Float = 0.8
        static let vignetteRadius: Float = 1.8
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
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidInput
        }
        
        var currentImage = ciImage
        
        // Step 1: Make image warmer (like film)
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(currentImage, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CPM35Constants.temperatureNeutral, forKey: "inputNeutral")
            temperatureFilter.setValue(CPM35Constants.temperatureTarget, forKey: "inputTargetNeutral")
            
            if let temperatureOutput = temperatureFilter.outputImage {
                currentImage = temperatureOutput
            }
        }
        
        // Step 2: Adjust colors (more vivid, slightly brighter, more contrast)
        let colorControlsFilter = CIFilter.colorControls()
        colorControlsFilter.inputImage = currentImage
        colorControlsFilter.saturation = CPM35Constants.saturation
        colorControlsFilter.brightness = CPM35Constants.brightness
        colorControlsFilter.contrast = CPM35Constants.contrast
        
        guard let colorControlsOutput = colorControlsFilter.outputImage else {
            throw ImageProcessingError.filterFailed("Color Controls")
        }
        currentImage = colorControlsOutput
        
        // Step 3: Apply tone curve (lift blacks, soften highlights - creates film look)
        let toneCurveFilter = CIFilter.toneCurve()
        toneCurveFilter.inputImage = currentImage
        toneCurveFilter.point0 = CPM35Constants.toneCurvePoints[0]
        toneCurveFilter.point1 = CPM35Constants.toneCurvePoints[1]
        toneCurveFilter.point2 = CPM35Constants.toneCurvePoints[2]
        toneCurveFilter.point3 = CPM35Constants.toneCurvePoints[3]
        toneCurveFilter.point4 = CPM35Constants.toneCurvePoints[4]
        
        guard let toneCurveOutput = toneCurveFilter.outputImage else {
            throw ImageProcessingError.filterFailed("Tone Curve")
        }
        currentImage = toneCurveOutput
        
        // Step 4: Add film grain
        let grainImage = createFilmGrain(for: currentImage)
        currentImage = blendGrain(grainImage, over: currentImage, baseExtent: ciImage.extent)
        
        // Step 5: Add vignette (darken edges)
        let vignetteFilter = CIFilter.vignette()
        vignetteFilter.inputImage = currentImage
        vignetteFilter.intensity = CPM35Constants.vignetteIntensity
        vignetteFilter.radius = CPM35Constants.vignetteRadius
        
        guard let vignetteOutput = vignetteFilter.outputImage else {
            throw ImageProcessingError.filterFailed("Vignette")
        }
        currentImage = vignetteOutput
        
        // Final step: Render to UIImage
        guard let cgImage = Self.sharedContext.createCGImage(currentImage, from: currentImage.extent) else {
            throw ImageProcessingError.renderingFailed
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func createFilmGrain(for baseImage: CIImage) -> CIImage {
        // Step 1: Generate random noise
        guard let noise = CIFilter.randomGenerator().outputImage?.cropped(to: baseImage.extent) else { 
            return baseImage 
        }
        
        // Step 2: Make it grayscale (film grain is not colored)
        let gray = CIFilter.colorControls()
        gray.inputImage = noise
        gray.saturation = 0.0
        
        guard let grayNoise = gray.outputImage else { return baseImage }
        
        // Step 3: Adjust grain properties to look like film
        let grainMatrix = CIFilter.colorMatrix()
        grainMatrix.inputImage = grayNoise
        // Make grain subtle and set transparency
        grainMatrix.rVector = CIVector(x: 0.2, y: 0, z: 0, w: 0)
        grainMatrix.gVector = CIVector(x: 0, y: 0.2, z: 0, w: 0)
        grainMatrix.bVector = CIVector(x: 0, y: 0, z: 0.2, w: 0)
        grainMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(CPM35Constants.grainAlpha))
        grainMatrix.biasVector = CIVector(x: 0.4, y: 0.4, z: 0.4, w: 0)  // Center around middle gray
        
        return grainMatrix.outputImage?.cropped(to: baseImage.extent) ?? baseImage
    }
    
    private func blendGrain(_ grainImage: CIImage, over baseImage: CIImage, baseExtent: CGRect) -> CIImage {
        // Blend grain with photo using soft light (more natural than overlay)
        if let softLight = CIFilter(name: "CISoftLightBlendMode") {
            softLight.setValue(grainImage, forKey: kCIInputImageKey)              // grain on top
            softLight.setValue(baseImage, forKey: kCIInputBackgroundImageKey)    // photo below
            if let output = softLight.outputImage?.cropped(to: baseExtent) {
                return output
            }
        }
        return baseImage
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
