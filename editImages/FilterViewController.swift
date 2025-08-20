//
//  FilterViewController.swift
//  editImages
//
//  Created by Luciano Castro on 18/08/2025.
//

import UIKit
import Combine

final class FilterViewController: UIViewController {
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Load", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loadButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Filter", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.alpha = 0.6
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var beforeAfterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Before/After", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.alpha = 0.6
        button.addTarget(self, action: #selector(beforeAfterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.alpha = 0.6
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    private let viewModel: FilterViewModel
    private var cancellables = Set<AnyCancellable>()
    
    /// Creates a new FilterViewController with the specified view model.
    /// - Parameter viewModel: The view model that provides the business logic and data
    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Image Editor"
        
        // Add subviews
        view.addSubview(imageView)
        view.addSubview(activityIndicator)
        view.addSubview(buttonStackView)
        
        // Add buttons to stack view
        buttonStackView.addArrangedSubview(loadButton)
        buttonStackView.addArrangedSubview(filterButton)
        buttonStackView.addArrangedSubview(beforeAfterButton)
        buttonStackView.addArrangedSubview(saveButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Image view
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            // Button stack view
            buttonStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Combine Bindings
    private func setupBindings() {
        // Original image binding
        viewModel.$originalImage
            .receive(on: RunLoop.main) 
            .sink { [weak self] image in
                self?.imageView.image = image
                self?.updateButtonStates()
            }
            .store(in: &cancellables)
        
        // Filtered image binding
        viewModel.$filteredImage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateButtonStates()
            }
            .store(in: &cancellables)
        
        // Before/After state binding
        viewModel.$isShowingAfter
            .receive(on: RunLoop.main)// aca explicacion
            .sink { [weak self] isShowingAfter in
                self?.imageView.image = self?.viewModel.currentImage
                self?.beforeAfterButton.setTitle(isShowingAfter ? "After" : "Before", for: .normal)
            }
            .store(in: &cancellables)
        
        // Loading state binding
        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // Error message binding
        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.showAlert(message: errorMessage)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func updateButtonStates() {
        let hasOriginalImage = viewModel.originalImage != nil
        let hasFilteredImage = viewModel.filteredImage != nil
        let hasCurrentImage = viewModel.currentImage != nil
        
        filterButton.isEnabled = hasOriginalImage
        filterButton.alpha = hasOriginalImage ? 1.0 : 0.6
        
        beforeAfterButton.isEnabled = hasFilteredImage
        beforeAfterButton.alpha = hasFilteredImage ? 1.0 : 0.6
        
        saveButton.isEnabled = hasCurrentImage
        saveButton.alpha = hasCurrentImage ? 1.0 : 0.6
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func loadButtonTapped() {
        viewModel.pickImage(from: self)
    }
    
    @objc private func filterButtonTapped() {
        viewModel.applyFilter()
    }
    
    @objc private func beforeAfterButtonTapped() {
        viewModel.toggleBeforeAfter()
    }
    
    @objc private func saveButtonTapped() {
        viewModel.saveCurrent()
    }
}
