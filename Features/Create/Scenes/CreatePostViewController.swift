import UIKit
import Combine // Импортируем Combine

protocol CreatePostViewControllerDelegate: AnyObject {
    // Обновляем делегат для соответствия новым требованиям (ViewModel сам разберется с данными)
    func didFinishCreatingPost(_ controller: CreatePostViewController)
    func didCancelCreatingPost(_ controller: CreatePostViewController)
}

class CreatePostViewController: UIViewController {

    weak var delegate: CreatePostViewControllerDelegate?
    private let viewModel: CreatePostViewModel // Добавляем ViewModel
    private var cancellables = Set<AnyCancellable>() // Для хранения подписок Combine

    // Убираем selectedImage, так как оно теперь в ViewModel
    // private let selectedImage: UIImage

    // MARK: - UI Elements

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill // Используем scaleAspectFill для квадрата
        imageView.clipsToBounds = true
        // imageView.image = selectedImage - Устанавливаем в viewDidLoad
        return imageView
    }()

    private lazy var captionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 5
        textView.text = "Write a caption..."
        textView.textColor = .placeholderText
        textView.delegate = self
        return textView
    }()

    // Добавляем индикатор активности
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    // Обновляем init для приема ViewModel
    init(viewModel: CreatePostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupNavigationBar()
        setupViews()
        setupConstraints()
        setupBindings() // Вызываем настройку биндингов

        // Устанавливаем изображение из ViewModel
        imageView.image = viewModel.selectedImage
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "New Post"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        // Изначально кнопка "Share" может быть доступна, но мы будем управлять ее состоянием через биндинг
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(shareTapped))

        navigationController?.isNavigationBarHidden = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(captionTextView)
        view.addSubview(activityIndicatorView) // Добавляем индикатор
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            captionTextView.topAnchor.constraint(equalTo: imageView.topAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            captionTextView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor), // Выравниваем низ

            // Размещаем индикатор по центру
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Привязка текста из TextView к caption в ViewModel
        captionTextView.textPublisher
            // Пропускаем начальное значение плейсхолдера при первой загрузке
            .dropFirst(captionTextView.textColor == .placeholderText ? 1 : 0)
            // Удаляем начальные/конечные пробелы и новые строки
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .sink { [weak self] text in
                // Не обновляем ViewModel, если это плейсхолдер
                if self?.captionTextView.textColor != .placeholderText {
                    self?.viewModel.caption = text
                }
            }
            .store(in: &cancellables)

        // Наблюдение за состоянием загрузки
        viewModel.$isSharing
            .receive(on: DispatchQueue.main) // Обновляем UI в главном потоке
            .sink { [weak self] isSharing in
                self?.navigationItem.rightBarButtonItem?.isEnabled = !isSharing
                self?.captionTextView.isEditable = !isSharing
                self?.navigationItem.leftBarButtonItem?.isEnabled = !isSharing // Блокируем Cancel тоже
                if isSharing {
                    self?.activityIndicatorView.startAnimating()
                } else {
                    self?.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // Наблюдение за ошибками
        viewModel.$errorMessage
            .compactMap { $0 } // Пропускаем nil
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(message: errorMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelCreatingPost(self)
    }

    @objc private func shareTapped() {
        // Убираем клавиатуру
        view.endEditing(true)

        // Вызываем метод ViewModel
        viewModel.sharePost { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil {
                    // Успех - уведомляем делегата
                    self.delegate?.didFinishCreatingPost(self)
                } // Ошибка обработается через $errorMessage sink
            }
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
            // Поскольку текст изменился, вручную присваиваем пустую строку ViewModel,
            // так как publisher сработает только при следующем вводе символа
            viewModel.caption = ""
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = .placeholderText
            // Если текст пуст, установим caption в ViewModel как пустую строку
            viewModel.caption = ""
        }
    }

    // Опционально: Обновлять ViewModel при каждом изменении текста
    // (textPublisher уже делает это, но можно добавить сюда, если нужно доп. логика)
//    func textViewDidChange(_ textView: UITextView) {
//        if textView.textColor != .placeholderText {
//            viewModel.caption = textView.text ?? ""
//        }
//    }
} 