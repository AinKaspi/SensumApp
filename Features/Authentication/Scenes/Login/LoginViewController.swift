import UIKit
import Combine // Убедимся, что Combine импортирован

// Делегат для LoginViewController, чтобы сообщать координатору о действиях
protocol LoginViewControllerDelegate: AnyObject {
    func didTapRegisterButton()
    func didTapLoginButton(email: String?, password: String?)
    func didTapGoogleSignInButton()
}

class LoginViewController: UIViewController {
    
    weak var delegate: LoginViewControllerDelegate?
    // Добавляем ссылку на ViewModel
    var viewModel: LoginViewModel! // Теперь не опционально
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Sensum Login"
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
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Don't have an account? Register", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.systemGray, for: .normal)
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Добавляем индикатор загрузки
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Добавляем лейбл для ошибок
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true // Скрыт по умолчанию
        return label
    }()
    
    // Добавляем кнопку Google Sign In
    private lazy var googleSignInButton: UIButton = { // TODO: Использовать стандартную GIDSignInButton?
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(" Sign in with Google", for: .normal)
        button.setImage(UIImage(named: "google_logo"), for: .normal) // Предполагается, что есть картинка google_logo в Assets
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        // Добавляем кнопку Google
        let stack = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, errorLabel, loginButton, googleSignInButton, registerButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        stack.distribution = .fill
        stack.setCustomSpacing(8, after: passwordTextField)
        stack.setCustomSpacing(20, after: errorLabel)
        stack.setCustomSpacing(20, after: loginButton) // Отступ после Login
        stack.setCustomSpacing(20, after: googleSignInButton) // Отступ после Google
        return stack
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into LoginViewController") // Проверяем инъекцию
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupBindings() // Настраиваем биндинги
        setupTextFieldTargets() // Настраиваем таргеты для текстфилдов
        navigationController?.isNavigationBarHidden = true 
        // TODO: Убедиться, что картинка google_logo добавлена в Assets.xcassets
    }

    // MARK: - Setup
    
    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        view.addSubview(activityIndicator) // Добавляем индикатор
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Констрейнты для индикатора (поверх всего)
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Констрейнт высоты для кнопки Google
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // Настройка таргетов для обновления ViewModel при вводе текста
    private func setupTextFieldTargets() {
        emailTextField.addTarget(self, action: #selector(emailDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Связываем состояние кнопки Login
        viewModel.isLoginButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: loginButton)
            .store(in: &cancellables)
            
        // Связываем состояние загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.loginButton.isEnabled = false // Блокируем кнопку во время загрузки
                } else {
                    self?.activityIndicator.stopAnimating()
                    // Состояние isEnabled для loginButton восстановится из isLoginButtonEnabled паблишера
                }
            }
            .store(in: &cancellables)
            
        // Связываем сообщение об ошибке
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorLabel.text = message
                self?.errorLabel.isHidden = (message == nil || message!.isEmpty)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions & Targets
    @objc private func loginButtonTapped() {
        // Убираем вызов делегата, вызываем метод ViewModel напрямую
        // delegate?.didTapLoginButton(email: emailTextField.text, password: passwordTextField.text)
        viewModel.attemptLogin()
    }
    
    @objc private func registerButtonTapped() {
        delegate?.didTapRegisterButton() // Оставляем вызов делегата для навигации
    }
    
    @objc private func emailDidChange() {
        viewModel.email = emailTextField.text ?? ""
    }
    
    @objc private func passwordDidChange() {
        viewModel.password = passwordTextField.text ?? ""
    }
    
    @objc private func googleSignInButtonTapped() {
        delegate?.didTapGoogleSignInButton()
    }
    
    // TODO: Добавить action для Google Sign In
} 