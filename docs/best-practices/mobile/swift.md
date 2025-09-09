# Swift Best Practices

## Official Documentation
- **Swift Documentation**: https://docs.swift.org
- **Swift Language Guide**: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/
- **Apple Developer Documentation**: https://developer.apple.com/documentation/
- **SwiftUI Documentation**: https://developer.apple.com/documentation/swiftui

## Project Structure (iOS App)

```
project-root/
├── MyApp/
│   ├── App/
│   │   ├── MyApp.swift
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Core/
│   │   ├── Constants/
│   │   ├── Extensions/
│   │   ├── Utilities/
│   │   └── Protocols/
│   ├── Data/
│   │   ├── Models/
│   │   ├── DataSources/
│   │   │   ├── Local/
│   │   │   └── Remote/
│   │   ├── Repositories/
│   │   └── Database/
│   ├── Domain/
│   │   ├── Entities/
│   │   ├── UseCases/
│   │   └── Repositories/
│   ├── Presentation/
│   │   ├── Views/
│   │   │   ├── Home/
│   │   │   ├── Profile/
│   │   │   └── Components/
│   │   ├── ViewModels/
│   │   └── Coordinators/
│   ├── Services/
│   │   ├── Network/
│   │   ├── Auth/
│   │   └── Storage/
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localizable.strings
│   │   └── Info.plist
│   └── Supporting Files/
├── MyAppTests/
├── MyAppUITests/
├── Packages/
└── MyApp.xcodeproj/
```

## Core Best Practices

### 1. Protocol-Oriented Programming

```swift
// Define protocols for abstraction
protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
    func fetchAllUsers() async throws -> [User]
}

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload(_ data: Data, to endpoint: Endpoint) async throws -> UploadResponse
}

// Protocol extensions for default implementations
protocol Identifiable {
    var id: String { get }
}

extension Identifiable where Self: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Protocol composition
typealias Persistable = Codable & Identifiable

// Associated types
protocol Repository {
    associatedtype Entity
    
    func create(_ entity: Entity) async throws
    func read(id: String) async throws -> Entity?
    func update(_ entity: Entity) async throws
    func delete(id: String) async throws
    func list() async throws -> [Entity]
}

// Generic implementation
class CoreDataRepository<T: NSManagedObject>: Repository {
    typealias Entity = T
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func create(_ entity: T) async throws {
        context.insert(entity)
        try context.save()
    }
    
    func read(id: String) async throws -> T? {
        let request = T.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first as? T
    }
    
    func update(_ entity: T) async throws {
        try context.save()
    }
    
    func delete(id: String) async throws {
        guard let entity = try await read(id: id) else { return }
        context.delete(entity)
        try context.save()
    }
    
    func list() async throws -> [T] {
        let request = T.fetchRequest()
        return try context.fetch(request) as? [T] ?? []
    }
}
```

### 2. SwiftUI Views and ViewModels

```swift
// MARK: - Domain Model
struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var avatarURL: URL?
    var role: UserRole
    let createdAt: Date
    var updatedAt: Date
}

enum UserRole: String, Codable, CaseIterable {
    case admin, user, moderator
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .user: return "User"
        case .moderator: return "Moderator"
        }
    }
}

// MARK: - ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = ""
    
    private let repository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return users }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init(repository: UserRepositoryProtocol = UserRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await repository.fetchAllUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func deleteUser(_ user: User) async {
        do {
            try await repository.deleteUser(id: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = error
        }
    }
    
    func refreshUser(_ user: User) async {
        do {
            let updatedUser = try await repository.fetchUser(id: user.id)
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                users[index] = updatedUser
            }
        } catch {
            self.error = error
        }
    }
}

// MARK: - SwiftUI View
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var showingAddUser = false
    @State private var selectedUser: User?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.users.isEmpty {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.users.isEmpty {
                    ContentUnavailableView(
                        "No Users",
                        systemImage: "person.3",
                        description: Text("Add your first user to get started")
                    )
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .searchable(text: $viewModel.searchText, prompt: "Search users")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddUser = true
                    } label: {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView { newUser in
                    await viewModel.loadUsers()
                }
            }
            .sheet(item: $selectedUser) { user in
                UserDetailView(user: user)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .refreshable {
                await viewModel.loadUsers()
            }
            .task {
                await viewModel.loadUsers()
            }
        }
    }
    
    private var userList: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                UserRowView(user: user)
                    .onTapGesture {
                        selectedUser = user
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteUser(user)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedUser = user
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Reusable Component
struct UserRowView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: user.avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(user.role.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor(for: user.role))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .admin: return .red
        case .moderator: return .orange
        case .user: return .blue
        }
    }
}
```

### 3. Networking with Async/Await

```swift
// MARK: - Network Layer
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// Endpoint configuration
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?
    let queryItems: [URLQueryItem]?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}

// Network service
actor NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = buildURL(from: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add auth token if available
        if let token = await AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingError
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    private func buildURL(from endpoint: Endpoint) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems
        return components?.url
    }
}

// API Client
class APIClient {
    static let shared = APIClient()
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService(baseURL: URL(string: "https://api.example.com")!)) {
        self.networkService = networkService
    }
    
    func fetchUsers() async throws -> [User] {
        let endpoint = Endpoint(
            path: "/users",
            method: .get,
            headers: nil,
            body: nil,
            queryItems: nil
        )
        
        let response: UsersResponse = try await networkService.request(endpoint)
        return response.users
    }
    
    func createUser(_ user: User) async throws -> User {
        let body = try JSONEncoder().encode(user)
        
        let endpoint = Endpoint(
            path: "/users",
            method: .post,
            headers: nil,
            body: body,
            queryItems: nil
        )
        
        return try await networkService.request(endpoint)
    }
}
```

### 4. Core Data Integration

```swift
import CoreData

// MARK: - Core Data Stack
class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}

// MARK: - Core Data Repository
class UserCoreDataRepository: UserRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    func fetchUser(id: String) async throws -> User {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            return self.mapToUser(entity)
        }
    }
    
    func saveUser(_ user: User) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id)
            
            let entity = try context.fetch(request).first ?? UserEntity(context: context)
            
            entity.id = user.id
            entity.name = user.name
            entity.email = user.email
            entity.avatarURL = user.avatarURL
            entity.role = user.role.rawValue
            entity.createdAt = user.createdAt
            entity.updatedAt = Date()
            
            try context.save()
        }
    }
    
    func deleteUser(id: String) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
            }
        }
    }
    
    func fetchAllUsers() async throws -> [User] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let request = UserEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.map { self.mapToUser($0) }
        }
    }
    
    private func mapToUser(_ entity: UserEntity) -> User {
        User(
            id: entity.id ?? "",
            name: entity.name ?? "",
            email: entity.email ?? "",
            avatarURL: entity.avatarURL,
            role: UserRole(rawValue: entity.role ?? "") ?? .user,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}
```

### 5. Combine Framework for Reactive Programming

```swift
import Combine

// MARK: - Reactive ViewModel
class ReactiveUserViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let repository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var filteredUsersPublisher: AnyPublisher<[User], Never> {
        Publishers.CombineLatest($users, $searchText)
            .map { users, searchText in
                guard !searchText.isEmpty else { return users }
                return users.filter { user in
                    user.name.localizedCaseInsensitiveContains(searchText) ||
                    user.email.localizedCaseInsensitiveContains(searchText)
                }
            }
            .eraseToAnyPublisher()
    }
    
    init(repository: UserRepositoryProtocol = UserRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-search with debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard !searchText.isEmpty else { return }
                self?.searchUsers(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    func loadUsers() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let fetchedUsers = try await repository.fetchAllUsers()
                await MainActor.run {
                    self.users = fetchedUsers
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func searchUsers(query: String) {
        // Implement search logic
    }
}

// MARK: - Combine Network Publisher
extension NetworkService {
    func requestPublisher<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, NetworkError> {
        Future<T, NetworkError> { promise in
            Task {
                do {
                    let result: T = try await self.request(endpoint)
                    promise(.success(result))
                } catch let error as NetworkError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
```

### 6. Testing

```swift
import XCTest
@testable import MyApp

// MARK: - Unit Tests
class UserViewModelTests: XCTestCase {
    var sut: UserViewModel!
    var mockRepository: MockUserRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testLoadUsersSuccess() async {
        // Given
        let expectedUsers = [
            User(id: "1", name: "John", email: "john@example.com", role: .user, createdAt: Date(), updatedAt: Date()),
            User(id: "2", name: "Jane", email: "jane@example.com", role: .admin, createdAt: Date(), updatedAt: Date())
        ]
        mockRepository.usersToReturn = expectedUsers
        
        // When
        await sut.loadUsers()
        
        // Then
        XCTAssertEqual(sut.users.count, 2)
        XCTAssertEqual(sut.users, expectedUsers)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadUsersFailure() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await sut.loadUsers()
        
        // Then
        XCTAssertTrue(sut.users.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFilteredUsers() {
        // Given
        sut.users = [
            User(id: "1", name: "John Doe", email: "john@example.com", role: .user, createdAt: Date(), updatedAt: Date()),
            User(id: "2", name: "Jane Smith", email: "jane@example.com", role: .admin, createdAt: Date(), updatedAt: Date())
        ]
        
        // When
        sut.searchText = "John"
        
        // Then
        XCTAssertEqual(sut.filteredUsers.count, 1)
        XCTAssertEqual(sut.filteredUsers.first?.name, "John Doe")
    }
}

// MARK: - Mock Repository
class MockUserRepository: UserRepositoryProtocol {
    var usersToReturn: [User] = []
    var shouldThrowError = false
    var deleteCallCount = 0
    
    func fetchUser(id: String) async throws -> User {
        if shouldThrowError {
            throw RepositoryError.notFound
        }
        return usersToReturn.first { $0.id == id } ?? User(id: id, name: "Test", email: "test@example.com", role: .user, createdAt: Date(), updatedAt: Date())
    }
    
    func saveUser(_ user: User) async throws {
        if shouldThrowError {
            throw RepositoryError.saveFailed
        }
        usersToReturn.append(user)
    }
    
    func deleteUser(id: String) async throws {
        deleteCallCount += 1
        if shouldThrowError {
            throw RepositoryError.deleteFailed
        }
        usersToReturn.removeAll { $0.id == id }
    }
    
    func fetchAllUsers() async throws -> [User] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return usersToReturn
    }
}

// MARK: - UI Tests
class UserListViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testAddUserFlow() {
        // Navigate to add user
        app.navigationBars["Users"].buttons["Add User"].tap()
        
        // Fill in user details
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Test User")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Save user
        app.buttons["Save"].tap()
        
        // Verify user appears in list
        XCTAssertTrue(app.staticTexts["Test User"].exists)
    }
}
```

### Common Pitfalls to Avoid

1. **Force unwrapping optionals**
2. **Retain cycles in closures**
3. **Not using value types appropriately**
4. **Blocking the main thread**
5. **Not handling errors properly**
6. **Ignoring memory management**
7. **Not using Swift's type safety**
8. **Creating massive view controllers**
9. **Not following Swift naming conventions**
10. **Forgetting to weak/unowned self in closures**

### Useful Frameworks and Libraries

- **SwiftUI**: Modern UI framework
- **UIKit**: Traditional UI framework
- **Combine**: Reactive programming
- **Core Data**: Local database
- **CloudKit**: Cloud storage
- **Alamofire**: Networking
- **Kingfisher**: Image loading
- **SwiftLint**: Code style enforcement
- **Quick/Nimble**: BDD testing
- **Swinject**: Dependency injection
- **RxSwift**: Reactive extensions
- **SnapKit**: Auto Layout DSL