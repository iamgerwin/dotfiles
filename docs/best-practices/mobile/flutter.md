# Flutter Best Practices

## Official Documentation
- **Flutter Documentation**: https://docs.flutter.dev
- **Flutter API Reference**: https://api.flutter.dev
- **Flutter Samples**: https://flutter.github.io/samples
- **Dart Documentation**: https://dart.dev/guides

## Project Structure

```
project-root/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_theme.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── network_info.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── extensions.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   └── repositories/
│   │       └── user_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   └── user_repository.dart
│   │   └── usecases/
│   │       ├── get_user.dart
│   │       └── update_user.dart
│   ├── presentation/
│   │   ├── blocs/
│   │   │   └── user/
│   │   │       ├── user_bloc.dart
│   │   │       ├── user_event.dart
│   │   │       └── user_state.dart
│   │   ├── pages/
│   │   │   ├── home/
│   │   │   │   ├── home_page.dart
│   │   │   │   └── widgets/
│   │   │   └── profile/
│   │   │       └── profile_page.dart
│   │   └── widgets/
│   │       ├── common/
│   │       └── custom_button.dart
│   └── main.dart
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── assets/
│   ├── images/
│   ├── fonts/
│   └── icons/
├── android/
├── ios/
├── web/
├── pubspec.yaml
└── analysis_options.yaml
```

## Core Best Practices

### 1. Clean Architecture Pattern

```dart
// Domain Layer - Entity
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}

// Domain Layer - Repository Interface
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, List<User>>> getAllUsers();
  Future<Either<Failure, void>> updateUser(User user);
}

// Domain Layer - Use Case
class GetUser {
  final UserRepository repository;

  GetUser(this.repository);

  Future<Either<Failure, User>> call(String id) async {
    return await repository.getUser(id);
  }
}

// Data Layer - Model
class UserModel extends User {
  const UserModel({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) : super(
          id: id,
          name: name,
          email: email,
          createdAt: createdAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Data Layer - Repository Implementation
class UserRepositoryImpl implements UserRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.getUser(id);
        localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localUser = await localDataSource.getCachedUser(id);
        return Right(localUser);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

### 2. State Management with BLoC

```dart
// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {
  final String userId;

  const LoadUser(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUser extends UserEvent {
  final User user;

  const UpdateUser(this.user);

  @override
  List<Object> get props => [user];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final User user;

  const UserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUser getUser;
  final UpdateUser updateUser;

  UserBloc({
    required this.getUser,
    required this.updateUser,
  }) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    final result = await getUser(event.userId);
    
    result.fold(
      (failure) => emit(UserError(_mapFailureToMessage(failure))),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    final result = await updateUser(event.user);
    
    result.fold(
      (failure) => emit(UserError(_mapFailureToMessage(failure))),
      (_) => emit(UserLoaded(event.user)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error occurred';
    }
  }
}
```

### 3. Widget Best Practices

```dart
// Stateless Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final ButtonStyle? style;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ?? Theme.of(context).elevatedButtonTheme.style,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}

// Stateful Widget with Lifecycle
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    
    // Load initial data
    context.read<UserBloc>().add(LoadUser(widget.userId));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is UserLoaded) {
            return _buildUserProfile(state.user);
          }
          
          if (state is UserError) {
            return Center(child: Text(state.message));
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUserProfile(User user) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(user.name[0]),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
```

### 4. Navigation and Routing

```dart
// Using go_router
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'profile',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserProfilePage(userId: userId);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                child: const DashboardPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    redirect: (context, state) {
      final isLoggedIn = context.read<AuthBloc>().state is Authenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      
      return null;
    },
  );
}

// Navigation usage
context.go('/profile/${user.id}');
context.goNamed('profile', pathParameters: {'id': user.id});
context.push('/settings');
```

### 5. Dependency Injection

```dart
// Using get_it
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  getIt.registerLazySingleton(() => http.Client());
  getIt.registerLazySingleton(() => InternetConnectionChecker());

  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );

  // Data sources
  getIt.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(sharedPreferences: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetUser(getIt()));
  getIt.registerLazySingleton(() => UpdateUser(getIt()));

  // BLoCs
  getIt.registerFactory(
    () => UserBloc(
      getUser: getIt(),
      updateUser: getIt(),
    ),
  );
}

// Usage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const MyApp());
}

// In widgets
final userBloc = getIt<UserBloc>();
```

### 6. Form Handling and Validation

```dart
class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 24),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is Authenticated) {
                context.go('/dashboard');
              }
            },
            builder: (context, state) {
              return CustomButton(
                text: 'Login',
                isLoading: state is AuthLoading,
                onPressed: _handleSubmit,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 7. Testing

```dart
// Unit Test
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUser useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUser(mockRepository);
  });

  test('should get user from repository', () async {
    // Arrange
    const testUser = User(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );
    when(mockRepository.getUser(any))
        .thenAnswer((_) async => Right(testUser));

    // Act
    final result = await useCase('1');

    // Assert
    expect(result, Right(testUser));
    verify(mockRepository.getUser('1'));
    verifyNoMoreInteractions(mockRepository);
  });
}

// Widget Test
void main() {
  testWidgets('CustomButton displays text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Click Me',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
  });

  testWidgets('CustomButton shows loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Click Me',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Click Me'), findsNothing);
  });
}

// Integration Test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login flow test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Find and enter email
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'test@example.com');

    // Find and enter password
    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(passwordField, 'password123');

    // Tap login button
    final loginButton = find.text('Login');
    await tester.tap(loginButton);

    // Wait for navigation
    await tester.pumpAndSettle();

    // Verify we're on dashboard
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

### 8. Performance Optimization

```dart
// Use const constructors
const MyWidget({Key? key}) : super(key: key);

// Use keys for list items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
);

// Lazy loading with pagination
class InfiniteList extends StatefulWidget {
  @override
  _InfiniteListState createState() => _InfiniteListState();
}

class _InfiniteListState extends State<InfiniteList> {
  final _scrollController = ScrollController();
  final _items = <Item>[];
  bool _isLoading = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isBottom && !_isLoading) {
      _loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    
    final newItems = await fetchItems(page: _page);
    
    setState(() {
      _page++;
      _items.addAll(newItems);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return ItemWidget(item: _items[index]);
      },
    );
  }
}
```

### Common Pitfalls to Avoid

1. **Not disposing controllers and animations**
2. **Using setState unnecessarily**
3. **Not using const constructors**
4. **Building expensive widgets in build method**
5. **Not handling null safety properly**
6. **Ignoring platform differences**
7. **Not testing on different screen sizes**
8. **Using too many nested widgets**
9. **Not optimizing images**
10. **Forgetting to handle loading and error states**

### Useful Packages

- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **dio**: HTTP client
- **go_router**: Navigation
- **freezed**: Code generation for models
- **json_serializable**: JSON serialization
- **hive**: Local database
- **shared_preferences**: Key-value storage
- **cached_network_image**: Image caching
- **flutter_svg**: SVG support
- **intl**: Internationalization
- **flutter_test**: Testing framework