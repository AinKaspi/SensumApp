import UIKit
import Combine

// Делегат для RegisterViewController
protocol RegisterViewControllerDelegate: AnyObject {
    func didTapRegisterButton(email: String?, username: String?, password: String?)
    // Можно добавить метод для возврата на Login, если нужно
    // func didTapBackButton()
}

class RegisterViewController: UIViewController {
    
    weak var delegate: RegisterViewControllerDelegate?
    // Добавляем ViewModel
    var viewModel: RegisterViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements (Аналогично Login, но добавляем Username)
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Register"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        return textField
    }()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Username"
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        return textField
    }()
    
    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Добавляем индикатор и лейбл ошибок (аналогично Login)
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var stackView: UIStackView = {
        // Обновляем subviews
        let stack = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, errorLabel, registerButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        stack.distribution = .fill
        // Добавляем кастомные отступы
        stack.setCustomSpacing(8, after: passwordTextField)
        stack.setCustomSpacing(20, after: errorLabel)
        return stack
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into RegisterViewController")
        view.backgroundColor = .black
        // Показываем Navigation Bar со стандартной кнопкой "Назад"
        navigationController?.isNavigationBarHidden = false
        // Можно настроить цвет бара, если нужно
        // navigationController?.navigationBar.tintColor = .white
        setupViews()
        setupConstraints()
        setupBindings()
        setupTextFieldTargets()
    }

    // MARK: - Setup
    
    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        view.addSubview(activityIndicator) // Добавляем индикатор
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Констрейнты для индикатора
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // Настраиваем таргеты
    private func setupTextFieldTargets() {
        emailTextField.addTarget(self, action: #selector(emailDidChange), for: .editingChanged)
        usernameTextField.addTarget(self, action: #selector(usernameDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Кнопка Register
        viewModel.isRegisterButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: registerButton)
            .store(in: &cancellables)
            
        // Загрузка
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.registerButton.isEnabled = false
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
            
        // Ошибка
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorLabel.text = message
                self?.errorLabel.isHidden = (message == nil || message!.isEmpty)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions & Targets
    @objc private func registerButtonTapped() {
        // Вызываем ViewModel напрямую
        viewModel.attemptRegistration()
    }
    
    @objc private func emailDidChange() {
        viewModel.email = emailTextField.text ?? ""
    }
    
    @objc private func usernameDidChange() {
        viewModel.username = usernameTextField.text ?? ""
    }
    
    @objc private func passwordDidChange() {
        viewModel.password = passwordTextField.text ?? ""
    }
} 