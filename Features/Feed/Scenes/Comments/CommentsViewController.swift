import UIKit
import Combine
import Kingfisher

@MainActor
final class CommentsViewController: UIViewController {
    
    // MARK: - Dependencies
    
    // Раскомментируем ViewModel
    private let viewModel: CommentsViewModel
    private let postId: String
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var textViewHeightConstraint: NSLayoutConstraint!
    private let textViewMinHeight: CGFloat = 36
    private let textViewMaxHeight: CGFloat = 100
    
    // MARK: - UI Elements
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        // Раскомментируем регистрацию ячейки
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        return view
    }()
    
    // Добавляем индикатор режима ответа
    private lazy var replyIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        view.isHidden = true
        return view
    }()
    
    private lazy var replyToUsernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private lazy var cancelReplyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(cancelReply), for: .touchUpInside)
        return button
    }()
    
    private lazy var commentTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
        textView.textColor = .white
        textView.layer.cornerRadius = textViewMinHeight / 2
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.delegate = self
        return textView
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.setPreferredSymbolConfiguration(.init(pointSize: 26), forImageIn: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Добавляем Refresh Control
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .lightGray // Цвет индикатора
        control.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    // Возвращаем корректный init
    init(postId: String, viewModel: CommentsViewModel) {
        self.postId = postId
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        // Раскомментируем биндинги
        setupBindings()
        setupKeyboardHandling()
        // Раскомментируем вызов ViewModel - БОЛЬШЕ НЕ НУЖЕН, listener стартует в init ViewModel
        // viewModel.fetchComments()
    }
    
    deinit {
        print("CommentsViewController deinit")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "Комментарии"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        // Добавляем refresh control к таблице
        tableView.refreshControl = refreshControl
        
        // Настраиваем UI для режима ответа
        inputContainerView.addSubview(replyIndicatorView)
        replyIndicatorView.addSubview(replyToUsernameLabel)
        replyIndicatorView.addSubview(cancelReplyButton)
        
        inputContainerView.addSubview(commentTextView)
        inputContainerView.addSubview(sendButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        textViewHeightConstraint = commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: textViewMinHeight)
        textViewHeightConstraint.priority = .required
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            
            // Reply indicator view
            replyIndicatorView.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            replyIndicatorView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            replyIndicatorView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            replyIndicatorView.heightAnchor.constraint(equalToConstant: 30),
            
            replyToUsernameLabel.leadingAnchor.constraint(equalTo: replyIndicatorView.leadingAnchor, constant: 12),
            replyToUsernameLabel.centerYAnchor.constraint(equalTo: replyIndicatorView.centerYAnchor),
            replyToUsernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: cancelReplyButton.leadingAnchor, constant: -8),
            
            cancelReplyButton.trailingAnchor.constraint(equalTo: replyIndicatorView.trailingAnchor, constant: -12),
            cancelReplyButton.centerYAnchor.constraint(equalTo: replyIndicatorView.centerYAnchor),
            cancelReplyButton.widthAnchor.constraint(equalToConstant: 24),
            cancelReplyButton.heightAnchor.constraint(equalToConstant: 24),
            
            commentTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            commentTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            commentTextView.topAnchor.constraint(equalTo: replyIndicatorView.bottomAnchor, constant: 8),
            commentTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            textViewHeightConstraint,
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: commentTextView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupBindings() {
        // Раскомментируем биндинги
        viewModel.$comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                if let viewModel = self?.viewModel, !viewModel.comments.isEmpty {
                    self?.scrollToBottom(animated: true)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    // Останавливаем refresh control, если он был активен
                    if self?.refreshControl.isRefreshing ?? false {
                        self?.refreshControl.endRefreshing()
                    }
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showErrorAlert(message: message)
            }
            .store(in: &cancellables)
        
        viewModel.$isSending
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSending in
                let hasText = !(self?.commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                self?.sendButton.isEnabled = !isSending && hasText
                self?.commentTextView.isEditable = !isSending
            }
            .store(in: &cancellables)
            
        // Добавляем биндинг для состояния ответа на комментарий
        viewModel.$isInReplyMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInReplyMode in
                self?.replyIndicatorView.isHidden = !isInReplyMode
            }
            .store(in: &cancellables)
            
        viewModel.$replyingToComment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comment in
                guard let self = self, let comment = comment else { return }
                if let username = comment.user?.username {
                    self.replyToUsernameLabel.text = "Ответ \(username)"
                } else {
                    self.replyToUsernameLabel.text = "Ответ на комментарий"
                }
            }
            .store(in: &cancellables)
    }
    
    // Обработчик для Refresh Control
    @objc private func handleRefreshControl() {
        // viewModel.fetchComments() // TODO: Переосмыслить pull-to-refresh при real-time обновлениях. Пока просто убираем вызов.
        // Можно просто завершить анимацию, если пользователь потянул
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in // Небольшая задержка для визуального эффекта
             self?.refreshControl.endRefreshing()
         }
    }
    
    private func setupKeyboardHandling() {
        // keyboardLayoutGuide используется в констрейнтах
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        // Раскомментируем вызов ViewModel
        guard let text = commentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        viewModel.addComment(text: text)
        
        commentTextView.text = ""
        adjustTextViewHeight(textView: commentTextView)
        sendButton.isEnabled = false
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func cancelReply() {
        viewModel.cancelReply()
    }
    
    // MARK: - Helpers
    
    private func showErrorAlert(message: String) {
        guard presentedViewController == nil else { return }
        
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func scrollToBottom(animated: Bool) {
        // Раскомментируем использование ViewModel
        guard viewModel.comments.count > 0 else { return }
        let lastIndexPath = IndexPath(row: viewModel.comments.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }
    
    private func adjustTextViewHeight(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        var newHeight = newSize.height
        
        if newHeight >= textViewMaxHeight {
            newHeight = textViewMaxHeight
            textView.isScrollEnabled = true
        } else {
            textView.isScrollEnabled = false
        }
        
        if textViewHeightConstraint.constant != newHeight {
            textViewHeightConstraint.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Раскомментируем
        return viewModel.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Раскомментируем
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else {
            fatalError("Cannot dequeue CommentCell")
        }
        
        let comment = viewModel.comments[indexPath.row]
        cell.configure(with: comment)
        cell.delegate = self // Устанавливаем ViewController как делегат
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CommentsViewController: UITableViewDelegate {
    // При необходимости можно добавить методы делегата
}

// MARK: - UITextViewDelegate
extension CommentsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Раскомментируем использование isSending
        sendButton.isEnabled = hasText && !viewModel.isSending
        
        adjustTextViewHeight(textView: textView)
    }
}

// MARK: - CommentCellDelegate
extension CommentsViewController: CommentCellDelegate {
    func didTapReplyButton(for comment: Comment) {
        viewModel.startReplyTo(comment: comment)
        commentTextView.becomeFirstResponder() // Фокус на поле ввода
    }
}

// Удаляем или оставляем закомментированным некорректный extension
/*
// Namespacing для разрешения конфликтов имен
extension CommentsViewController {
    enum Views {
        typealias CommentCell = Features.Feed.Scenes.Comments.Views.CommentCell
    }
}
*/
