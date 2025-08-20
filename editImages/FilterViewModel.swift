//
//  FilterViewModel.swift
//  editImages
//
//  Created by Luciano Castro on 18/08/2025.
//

import UIKit
import Combine
import Photos
import PhotosUI

// MARK: - UIImage Extension for Optimization
extension UIImage {
    func renderedOpaque() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

final class FilterViewModel: NSObject {
    
    /// Creates a new FilterViewModel with the specified services.
    /// - Parameters:
    ///   - picker: Service for photo selection functionality
    ///   - imageProcessor: Service for image processing and filter application
    init(picker: PhotoPickerServiceType, imageProcessor: ImageProcessingServiceType) {
        self.picker = picker
        self.imageProcessor = imageProcessor
    }
    // MARK: - Published Properties
    @Published var originalImage: UIImage?
    @Published var filteredImage: UIImage?
    @Published var isShowingAfter: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let picker: PhotoPickerServiceType
    private let imageProcessor: ImageProcessingServiceType
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentImage: UIImage? {
        isShowingAfter ? (filteredImage ?? originalImage) : originalImage
    }
    

    
    // MARK: - Public Methods
    func pickImage(from vc: UIViewController) {
        picker.pickImage(from: vc) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.originalImage = image
                    self?.filteredImage = nil
                    self?.isShowingAfter = false
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "Error loading image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func applyFilter() {
        guard let originalImage = originalImage else { 
            errorMessage = "No image to filter"
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        Task { 
            do {
                let filtered = try await imageProcessor.applyCPM35Like(to: originalImage)
                await MainActor.run {
                    self.filteredImage = filtered
                    self.isShowingAfter = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error applying filter: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleBeforeAfter() {
        isShowingAfter.toggle()
    }
    
    func saveCurrent() {
        guard let currentImage = currentImage else { 
            errorMessage = "No image to save"
            return 
        }
        
        // Optimize image for saving (remove alpha channel to avoid warnings)
        let optimizedImage = currentImage.renderedOpaque()
        
        // Check permissions before saving
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            UIImageWriteToSavedPhotosAlbum(optimizedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        case .denied, .restricted:
            errorMessage = "Permission denied to save images"
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        guard let self = self else { return }
                        UIImageWriteToSavedPhotosAlbum(optimizedImage, self, #selector(FilterViewModel.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    } else {
                        self?.errorMessage = "Permission denied to save images"
                    }
                }
            }
        @unknown default:
            errorMessage = "Unknown permission status"
        }
    }
    
    // MARK: - Private Methods
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "Error saving: \(error.localizedDescription)"
            } else {
                self.errorMessage = "Image saved successfully"
            }
        }
    }
}
