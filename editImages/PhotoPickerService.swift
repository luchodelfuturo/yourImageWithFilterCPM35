//
//  PhotoPickerService.swift
//  editImages
//
//  Created by Luciano Castro on 18/08/2025.
//

import UIKit
import PhotosUI

// MARK: - Photo Picker Protocol
/// Protocol defining the interface for photo selection functionality.
/// This protocol allows for easy testing and dependency injection.
protocol PhotoPickerServiceType {
    /// Presents a photo picker and returns the selected image via completion handler.
    /// - Parameters:
    ///   - viewController: The view controller that will present the photo picker
    ///   - completion: Completion handler that returns either a UIImage or an error
    ///     - Success case: Returns the selected UIImage
    ///     - Failure case: Returns PhotoPickerError with specific error details
    func pickImage(from viewController: UIViewController, completion: @escaping (Result<UIImage, Error>) -> Void)
}

// MARK: - Implementation
class PhotoPickerService: NSObject, PhotoPickerServiceType {
    
    // MARK: - Properties
    /// Completion handler to return the selected image or error
    private var completion: ((Result<UIImage, Error>) -> Void)?
    
    // MARK: - Initialization
    /// Creates a new PhotoPickerService instance.
    /// No parameters required as this is a stateless service.
    override init() {
        super.init()
    }
    
    // MARK: - Photo Picker Protocol Implementation
    /// Presents a photo picker using PHPickerViewController (iOS 14+).
    /// Automatically handles permissions and provides a modern photo selection experience.
    /// - Parameters:
    ///   - viewController: The view controller that will present the photo picker
    ///   - completion: Completion handler called when user selects an image or cancels
    func pickImage(from viewController: UIViewController, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotoPickerService: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            completion?(.failure(PhotoPickerError.noImageSelected))
            return
        }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.completion?(.failure(error))
                    return
                }
                
                guard let image = object as? UIImage else {
                    self?.completion?(.failure(PhotoPickerError.invalidImage))
                    return
                }
                
                self?.completion?(.success(image))
            }
        }
    }
}

// MARK: - Errors
enum PhotoPickerError: Error, LocalizedError {
    /// User cancelled the photo selection without choosing an image
    case noImageSelected
    /// Selected image could not be loaded or is corrupted
    case invalidImage
    
    /// Localized error description for user-facing error messages
    var errorDescription: String? {
        switch self {
        case .noImageSelected:
            return "No image selected"
        case .invalidImage:
            return "Selected image is not valid"
        }
    }
}
