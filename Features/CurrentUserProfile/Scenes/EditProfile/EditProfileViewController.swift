import UIKit
import Combine
import PhotosUI
import Kingfisher // Добавляем Kingfisher

// Протокол перенесен в Coordinator.swift
/*
protocol EditProfileViewControllerDelegate: AnyObject {
    func editProfileDidFinish(didSave: Bool) // true если сохранили, false если отменили
}
*/

class EditProfileViewController: UIViewController, PHPickerViewControllerDelegate, UITextViewDelegate {

    // Добавляем свойство delegate обратно
    weak var delegate: EditProfileViewControllerDelegate?
    // Раскомментируем ViewModel
    var viewModel: EditProfileViewModel! 
    private var cancellables = Set<AnyCancellable>() // Добавляем для биндингов

    // MARK: - UI Elements
    // ... (UI элементы без изменений) ...
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60
        imageView.backgroundColor = .darkGray
        imageView.image = UIImage(systemName: "person.circle.fill")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .lightGray
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let changeAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Изменить фото", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(changeAvatarTapped), for: .touchUpInside)
        return button
    }()

    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Имя пользователя"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        return textField
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "О себе:"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private let statusTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .secondarySystemBackground
        textView.textColor = .label
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.isScrollEnabled = true
        return textView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties
    private var selectedAvatarImage: UIImage?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into EditProfileViewController")
        view.backgroundColor = .black
        title = "Редактировать профиль"
        setupNavigationBar()
        setupViews()
        setupConstraints()
        setupAvatarTap()
        // Раскомментируем биндинги и загрузку данных
        setupBindings() 
        viewModel.loadInitialData() 
    }

    // MARK: - Setup
    // ... (setupNavigationBar, setupViews, setupConstraints, setupAvatarTap без изменений) ...
     private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false // Изначально кнопка Save неактивна
    }

    private func setupViews() {
        view.addSubview(avatarImageView)
        view.addSubview(changeAvatarButton)
        view.addSubview(usernameTextField)
        view.addSubview(statusLabel)
        view.addSubview(statusTextView)
        view.addSubview(activityIndicator)
        
        statusTextView.delegate = self 
        setPlaceholderForStatusTextView() // Устанавливаем плейсхолдер перед биндингом
        // Добавляем таргеты для отслеживания изменений
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    private func setupConstraints() {
        let padding: CGFloat = 20
        let avatarSize: CGFloat = 120

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarSize),

            changeAvatarButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            changeAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            usernameTextField.topAnchor.constraint(equalTo: changeAvatarButton.bottomAnchor, constant: padding * 1.5),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            statusLabel.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: padding),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            statusTextView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            statusTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statusTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            statusTextView.heightAnchor.constraint(equalToConstant: 100),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupAvatarTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeAvatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        // delegate?.editProfileDidFinish(didSave: false)
    }

    @objc private func saveTapped() {
        // Вызываем viewModel для сохранения
        viewModel.saveProfile(
            newUsername: usernameTextField.text,
            newStatus: (statusTextView.textColor == .placeholderText) ? nil : statusTextView.text, // Передаем nil, если это плейсхолдер
            newAvatarImage: selectedAvatarImage
        )
    }

    @objc private func changeAvatarTapped() {
        presentImagePicker()
    }
    
    // Вызывается при изменении текста
    @objc private func textFieldDidChange() {
        checkForChanges()
    }

    // MARK: - Image Picker (PHPicker)
    // ... (presentImagePicker, picker без изменений) ...
     private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let selectedImage = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self?.avatarImageView.image = selectedImage
                    self?.selectedAvatarImage = selectedImage
                    self?.checkForChanges() // Проверяем изменения после выбора фото
                }
            }
        }
    }
    
    // MARK: - UITextView Placeholder Logic
    // ... (setPlaceholderForStatusTextView, textViewDidBeginEditing, textViewDidEndEditing без изменений) ...
    private func setPlaceholderForStatusTextView() {
        if statusTextView.text.isEmpty {
            statusTextView.text = "Расскажите о себе..."
            statusTextView.textColor = .placeholderText
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
       setPlaceholderForStatusTextView()
    }
    
    // Добавляем метод делегата для отслеживания изменений
    func textViewDidChange(_ textView: UITextView) {
        checkForChanges()
    }

    // MARK: - Bindings 
    
    private func setupBindings() {
        // Подписка на начальные данные
        viewModel.$initialUsername
            .receive(on: DispatchQueue.main)
            .sink { [weak self] username in
                self?.usernameTextField.text = username
                self?.checkForChanges() // Проверить состояние кнопки Save после загрузки
            }
            .store(in: &cancellables)
            
        viewModel.$initialStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if !status.isEmpty {
                    self?.statusTextView.text = status
                    self?.statusTextView.textColor = .label
                } else {
                    self?.setPlaceholderForStatusTextView()
                }
                 self?.checkForChanges() // Проверить состояние кнопки Save после загрузки
            }
            .store(in: &cancellables)
            
        viewModel.$initialAvatarURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                guard let self = self else { return }
                let placeholder = UIImage(systemName: "person.circle.fill")?.withRenderingMode(.alwaysTemplate)
                if let urlString = urlString, let url = URL(string: urlString) {
                    self.avatarImageView.kf.indicatorType = .activity
                    self.avatarImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2)), .cacheOriginalImage]) { result in
                        if case .failure(_) = result {
                             self.avatarImageView.image = placeholder
                             self.avatarImageView.tintColor = .lightGray
                        }
                    }
                } else {
                    self.avatarImageView.image = placeholder
                    self.avatarImageView.tintColor = .lightGray
                }
            }
            .store(in: &cancellables)

        // Подписка на состояние загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.activityIndicator.isHidden = !isLoading
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.view.isUserInteractionEnabled = false // Блокируем UI во время загрузки
                    self?.navigationItem.rightBarButtonItem?.isEnabled = false // Блокируем Save
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.view.isUserInteractionEnabled = true
                    self?.checkForChanges() // Перепроверяем доступность Save после окончания загрузки
                }
            }
            .store(in: &cancellables)
            
        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                // TODO: Показать Alert с ошибкой
                 print("*** EditProfile Error: \(message) ***")
                 let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
                 alert.addAction(UIAlertAction(title: "OK", style: .default))
                 self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Change Tracking
    
    private func checkForChanges() {
        // Активируем кнопку Save только если есть изменения и не идет загрузка
        let usernameChanged = usernameTextField.text != viewModel.initialUsername
        let status = (statusTextView.textColor == .placeholderText) ? "" : statusTextView.text ?? ""
        let statusChanged = status != viewModel.initialStatus
        let avatarChanged = selectedAvatarImage != nil
        
        let hasChanges = usernameChanged || statusChanged || avatarChanged
        navigationItem.rightBarButtonItem?.isEnabled = hasChanges && !viewModel.isLoading
    }
} 