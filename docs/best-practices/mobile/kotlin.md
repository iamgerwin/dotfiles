# Kotlin Best Practices

## Official Documentation
- **Kotlin Documentation**: https://kotlinlang.org/docs/home.html
- **Kotlin Coding Conventions**: https://kotlinlang.org/docs/coding-conventions.html
- **Kotlin for Android**: https://developer.android.com/kotlin
- **Ktor Framework**: https://ktor.io/docs/

## Project Structure (Android App)

```
project-root/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/app/
│   │   │   │   ├── data/
│   │   │   │   │   ├── local/
│   │   │   │   │   │   ├── dao/
│   │   │   │   │   │   ├── database/
│   │   │   │   │   │   └── preferences/
│   │   │   │   │   ├── remote/
│   │   │   │   │   │   ├── api/
│   │   │   │   │   │   └── dto/
│   │   │   │   │   ├── repository/
│   │   │   │   │   └── mapper/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── model/
│   │   │   │   │   ├── repository/
│   │   │   │   │   └── usecase/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── ui/
│   │   │   │   │   │   ├── home/
│   │   │   │   │   │   ├── profile/
│   │   │   │   │   │   └── common/
│   │   │   │   │   ├── viewmodel/
│   │   │   │   │   └── theme/
│   │   │   │   ├── di/
│   │   │   │   └── utils/
│   │   │   └── res/
│   │   └── test/
│   └── build.gradle.kts
├── buildSrc/
│   └── src/main/kotlin/
├── gradle/
├── build.gradle.kts
└── settings.gradle.kts
```

## Project Structure (Ktor Backend)

```
project-root/
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   └── com/example/
│   │   │       ├── application/
│   │   │       │   ├── Application.kt
│   │   │       │   └── Server.kt
│   │   │       ├── config/
│   │   │       │   └── DatabaseConfig.kt
│   │   │       ├── domain/
│   │   │       │   ├── model/
│   │   │       │   ├── repository/
│   │   │       │   └── service/
│   │   │       ├── infrastructure/
│   │   │       │   ├── database/
│   │   │       │   └── repository/
│   │   │       ├── presentation/
│   │   │       │   ├── routes/
│   │   │       │   ├── dto/
│   │   │       │   └── validation/
│   │   │       ├── plugins/
│   │   │       │   ├── Authentication.kt
│   │   │       │   ├── Routing.kt
│   │   │       │   └── Serialization.kt
│   │   │       └── utils/
│   │   └── resources/
│   │       ├── application.conf
│   │       └── logback.xml
│   └── test/
├── build.gradle.kts
└── gradle.properties
```

## Core Best Practices

### 1. Data Classes and Sealed Classes

```kotlin
// Domain models using data classes
data class User(
    val id: String,
    val email: String,
    val username: String,
    val role: UserRole,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now()
) {
    init {
        require(email.isNotBlank()) { "Email cannot be blank" }
        require(username.length >= 3) { "Username must be at least 3 characters" }
    }
}

enum class UserRole {
    ADMIN, USER, MODERATOR
}

// Sealed classes for state management
sealed class Resource<T>(
    val data: T? = null,
    val message: String? = null
) {
    class Success<T>(data: T) : Resource<T>(data)
    class Error<T>(message: String, data: T? = null) : Resource<T>(data, message)
    class Loading<T>(data: T? = null) : Resource<T>(data)
}

// Sealed class for navigation events
sealed class NavigationEvent {
    object NavigateBack : NavigationEvent()
    data class NavigateToRoute(val route: String) : NavigationEvent()
    data class NavigateToDeepLink(val deepLink: String) : NavigationEvent()
}

// Result wrapper
sealed class Result<out T> {
    data class Success<T>(val value: T) : Result<T>()
    data class Failure(val exception: Exception) : Result<Nothing>()
    
    inline fun <R> map(transform: (T) -> R): Result<R> = when (this) {
        is Success -> Success(transform(value))
        is Failure -> this
    }
    
    inline fun onSuccess(action: (T) -> Unit): Result<T> {
        if (this is Success) action(value)
        return this
    }
    
    inline fun onFailure(action: (Exception) -> Unit): Result<T> {
        if (this is Failure) action(exception)
        return this
    }
}
```

### 2. Repository Pattern with Coroutines

```kotlin
// Domain repository interface
interface UserRepository {
    suspend fun getUser(id: String): Result<User>
    suspend fun getAllUsers(): Flow<List<User>>
    suspend fun createUser(user: User): Result<User>
    suspend fun updateUser(user: User): Result<User>
    suspend fun deleteUser(id: String): Result<Unit>
    suspend fun searchUsers(query: String): Flow<List<User>>
}

// Implementation
class UserRepositoryImpl(
    private val remoteDataSource: UserRemoteDataSource,
    private val localDataSource: UserLocalDataSource,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) : UserRepository {
    
    override suspend fun getUser(id: String): Result<User> = withContext(dispatcher) {
        try {
            // Try to get from cache first
            localDataSource.getUser(id)?.let {
                return@withContext Result.Success(it.toDomainModel())
            }
            
            // Fetch from remote
            val remoteUser = remoteDataSource.getUser(id)
            
            // Cache the result
            localDataSource.insertUser(remoteUser.toEntity())
            
            Result.Success(remoteUser.toDomainModel())
        } catch (e: Exception) {
            Result.Failure(e)
        }
    }
    
    override suspend fun getAllUsers(): Flow<List<User>> = flow {
        // Emit cached data first
        emit(localDataSource.getAllUsers().map { it.toDomainModel() })
        
        // Fetch fresh data
        try {
            val remoteUsers = remoteDataSource.getAllUsers()
            localDataSource.insertUsers(remoteUsers.map { it.toEntity() })
            emit(remoteUsers.map { it.toDomainModel() })
        } catch (e: Exception) {
            // Handle error but don't crash the flow
            Timber.e(e, "Failed to fetch remote users")
        }
    }.flowOn(dispatcher)
    
    override suspend fun createUser(user: User): Result<User> = withContext(dispatcher) {
        try {
            val createdUser = remoteDataSource.createUser(user.toDto())
            localDataSource.insertUser(createdUser.toEntity())
            Result.Success(createdUser.toDomainModel())
        } catch (e: Exception) {
            Result.Failure(e)
        }
    }
}
```

### 3. Ktor Backend Implementation

```kotlin
// Application setup
fun Application.module() {
    configureSerialization()
    configureAuthentication()
    configureDatabases()
    configureRouting()
    configureMonitoring()
    configureHTTP()
}

// Routing configuration
fun Application.configureRouting() {
    val userService by inject<UserService>()
    
    routing {
        route("/api/v1") {
            authRoutes()
            authenticate("jwt") {
                userRoutes(userService)
                productRoutes()
            }
        }
        
        // Health check
        get("/health") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "healthy"))
        }
    }
}

// User routes
fun Route.userRoutes(userService: UserService) {
    route("/users") {
        get {
            val page = call.request.queryParameters["page"]?.toIntOrNull() ?: 1
            val size = call.request.queryParameters["size"]?.toIntOrNull() ?: 10
            
            val users = userService.getAllUsers(page, size)
            call.respond(users)
        }
        
        get("/{id}") {
            val id = call.parameters["id"] ?: return@get call.respond(
                HttpStatusCode.BadRequest, 
                ErrorResponse("Missing user ID")
            )
            
            userService.getUser(id).fold(
                onSuccess = { user -> call.respond(user) },
                onFailure = { error ->
                    when (error) {
                        is UserNotFoundException -> call.respond(
                            HttpStatusCode.NotFound,
                            ErrorResponse(error.message)
                        )
                        else -> call.respond(
                            HttpStatusCode.InternalServerError,
                            ErrorResponse("Internal server error")
                        )
                    }
                }
            )
        }
        
        post {
            val createUserRequest = call.receive<CreateUserRequest>()
            
            // Validate request
            createUserRequest.validate().onFailure { errors ->
                return@post call.respond(
                    HttpStatusCode.BadRequest,
                    ValidationErrorResponse(errors)
                )
            }
            
            userService.createUser(createUserRequest).fold(
                onSuccess = { user -> 
                    call.respond(HttpStatusCode.Created, user)
                },
                onFailure = { error ->
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse(error.message ?: "Failed to create user")
                    )
                }
            )
        }
        
        put("/{id}") {
            val id = call.parameters["id"] ?: return@put call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse("Missing user ID")
            )
            
            val updateRequest = call.receive<UpdateUserRequest>()
            
            userService.updateUser(id, updateRequest).fold(
                onSuccess = { user -> call.respond(user) },
                onFailure = { error ->
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse(error.message ?: "Failed to update user")
                    )
                }
            )
        }
        
        delete("/{id}") {
            val id = call.parameters["id"] ?: return@delete call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse("Missing user ID")
            )
            
            userService.deleteUser(id).fold(
                onSuccess = { call.respond(HttpStatusCode.NoContent) },
                onFailure = { error ->
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse(error.message ?: "Failed to delete user")
                    )
                }
            )
        }
    }
}

// Authentication
fun Application.configureAuthentication() {
    val jwtService = JwtService(environment.config)
    
    install(Authentication) {
        jwt("jwt") {
            verifier(jwtService.verifier)
            validate { credential ->
                val payload = credential.payload
                val userId = payload.getClaim("userId").asString()
                val role = payload.getClaim("role").asString()
                
                if (userId != null && role != null) {
                    UserPrincipal(userId, UserRole.valueOf(role))
                } else {
                    null
                }
            }
            
            challenge { _, _ ->
                call.respond(
                    HttpStatusCode.Unauthorized,
                    ErrorResponse("Token is not valid or has expired")
                )
            }
        }
    }
}
```

### 4. Android ViewModel with StateFlow

```kotlin
@HiltViewModel
class UserViewModel @Inject constructor(
    private val getUserUseCase: GetUserUseCase,
    private val updateUserUseCase: UpdateUserUseCase,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    
    private val userId: String = savedStateHandle.get<String>("userId")
        ?: throw IllegalArgumentException("User ID is required")
    
    private val _uiState = MutableStateFlow(UserUiState())
    val uiState: StateFlow<UserUiState> = _uiState.asStateFlow()
    
    private val _events = MutableSharedFlow<UserEvent>()
    val events: SharedFlow<UserEvent> = _events.asSharedFlow()
    
    init {
        loadUser()
    }
    
    private fun loadUser() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            getUserUseCase(userId)
                .onSuccess { user ->
                    _uiState.update { 
                        it.copy(
                            user = user,
                            isLoading = false,
                            error = null
                        )
                    }
                }
                .onFailure { exception ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = exception.message
                        )
                    }
                    _events.emit(UserEvent.ShowError(exception.message ?: "Unknown error"))
                }
        }
    }
    
    fun updateUser(name: String, email: String) {
        val currentUser = _uiState.value.user ?: return
        
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            updateUserUseCase(
                currentUser.copy(name = name, email = email)
            )
                .onSuccess { updatedUser ->
                    _uiState.update {
                        it.copy(
                            user = updatedUser,
                            isLoading = false
                        )
                    }
                    _events.emit(UserEvent.UserUpdated)
                }
                .onFailure { exception ->
                    _uiState.update { it.copy(isLoading = false) }
                    _events.emit(UserEvent.ShowError(exception.message ?: "Update failed"))
                }
        }
    }
}

data class UserUiState(
    val user: User? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

sealed class UserEvent {
    object UserUpdated : UserEvent()
    data class ShowError(val message: String) : UserEvent()
}
```

### 5. Compose UI Implementation

```kotlin
@Composable
fun UserScreen(
    viewModel: UserViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    
    LaunchedEffect(viewModel) {
        viewModel.events.collect { event ->
            when (event) {
                is UserEvent.UserUpdated -> {
                    Toast.makeText(context, "User updated successfully", Toast.LENGTH_SHORT).show()
                }
                is UserEvent.ShowError -> {
                    Toast.makeText(context, event.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }
    
    UserContent(
        uiState = uiState,
        onUpdateUser = viewModel::updateUser,
        onNavigateBack = onNavigateBack
    )
}

@Composable
private fun UserContent(
    uiState: UserUiState,
    onUpdateUser: (String, String) -> Unit,
    onNavigateBack: () -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    
    LaunchedEffect(uiState.user) {
        uiState.user?.let {
            name = it.name
            email = it.email
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("User Profile") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorMessage(
                        message = uiState.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.user != null -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            label = { Text("Name") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true
                        )
                        
                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            label = { Text("Email") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Email
                            )
                        )
                        
                        Button(
                            onClick = { onUpdateUser(name, email) },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = name.isNotBlank() && email.isNotBlank()
                        ) {
                            Text("Update Profile")
                        }
                    }
                }
            }
        }
    }
}
```

### 6. Dependency Injection with Hilt/Koin

```kotlin
// Hilt modules
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG) {
                    HttpLoggingInterceptor.Level.BODY
                } else {
                    HttpLoggingInterceptor.Level.NONE
                }
            })
            .addInterceptor(AuthInterceptor())
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
    
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }
    
    @Provides
    fun provideUserDao(database: AppDatabase): UserDao = database.userDao()
}

// Koin modules
val networkModule = module {
    single<OkHttpClient> {
        OkHttpClient.Builder()
            .addInterceptor(get<HttpLoggingInterceptor>())
            .build()
    }
    
    single<Retrofit> {
        Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(get())
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
    
    single<ApiService> { get<Retrofit>().create(ApiService::class.java) }
}

val repositoryModule = module {
    single<UserRepository> {
        UserRepositoryImpl(
            remoteDataSource = get(),
            localDataSource = get()
        )
    }
}

val viewModelModule = module {
    viewModel { (userId: String) ->
        UserViewModel(
            getUserUseCase = get(),
            updateUserUseCase = get(),
            userId = userId
        )
    }
}
```

### 7. Testing

```kotlin
// Unit tests
class UserRepositoryTest {
    
    @get:Rule
    val coroutineRule = MainCoroutineRule()
    
    private val mockRemoteDataSource = mockk<UserRemoteDataSource>()
    private val mockLocalDataSource = mockk<UserLocalDataSource>()
    
    private lateinit var repository: UserRepository
    
    @Before
    fun setup() {
        repository = UserRepositoryImpl(
            remoteDataSource = mockRemoteDataSource,
            localDataSource = mockLocalDataSource,
            dispatcher = coroutineRule.testDispatcher
        )
    }
    
    @Test
    fun `getUser returns cached user when available`() = runTest {
        // Given
        val userId = "123"
        val cachedUser = UserEntity(
            id = userId,
            name = "John Doe",
            email = "john@example.com"
        )
        
        coEvery { mockLocalDataSource.getUser(userId) } returns cachedUser
        
        // When
        val result = repository.getUser(userId)
        
        // Then
        assertTrue(result is Result.Success)
        assertEquals("John Doe", (result as Result.Success).value.name)
        
        coVerify(exactly = 0) { mockRemoteDataSource.getUser(any()) }
    }
    
    @Test
    fun `getUser fetches from remote when cache miss`() = runTest {
        // Given
        val userId = "123"
        val remoteUser = UserDto(
            id = userId,
            name = "Jane Doe",
            email = "jane@example.com"
        )
        
        coEvery { mockLocalDataSource.getUser(userId) } returns null
        coEvery { mockRemoteDataSource.getUser(userId) } returns remoteUser
        coEvery { mockLocalDataSource.insertUser(any()) } just Runs
        
        // When
        val result = repository.getUser(userId)
        
        // Then
        assertTrue(result is Result.Success)
        assertEquals("Jane Doe", (result as Result.Success).value.name)
        
        coVerify { mockRemoteDataSource.getUser(userId) }
        coVerify { mockLocalDataSource.insertUser(any()) }
    }
}

// UI tests with Compose
@RunWith(AndroidJUnit4::class)
class UserScreenTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun userScreen_displaysUserData() {
        val user = User(
            id = "123",
            name = "John Doe",
            email = "john@example.com"
        )
        
        composeTestRule.setContent {
            UserContent(
                uiState = UserUiState(user = user),
                onUpdateUser = { _, _ -> },
                onNavigateBack = { }
            )
        }
        
        composeTestRule.onNodeWithText("John Doe").assertIsDisplayed()
        composeTestRule.onNodeWithText("john@example.com").assertIsDisplayed()
    }
}
```

### Common Pitfalls to Avoid

1. **Not using null safety properly**
2. **Blocking the main thread with I/O operations**
3. **Not handling coroutine cancellation**
4. **Overusing companion objects**
5. **Not leveraging Kotlin's standard library**
6. **Creating memory leaks with coroutines**
7. **Not using data classes for DTOs**
8. **Ignoring Kotlin conventions**
9. **Not using scope functions appropriately**
10. **Forgetting to handle configuration changes**

### Useful Libraries

- **Ktor**: Backend framework
- **Exposed**: SQL framework
- **Koin/Hilt**: Dependency injection
- **Coroutines**: Asynchronous programming
- **Flow**: Reactive streams
- **Compose**: Modern UI toolkit
- **Retrofit**: HTTP client
- **Room**: Database abstraction
- **Coil**: Image loading
- **MockK**: Testing framework
- **Turbine**: Flow testing
- **Detekt**: Static code analysis