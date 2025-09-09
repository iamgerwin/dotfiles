# .NET MAUI Best Practices

## Official Documentation
- **.NET MAUI Documentation**: https://docs.microsoft.com/dotnet/maui
- **XAML Documentation**: https://docs.microsoft.com/dotnet/maui/xaml
- **.NET MAUI Samples**: https://github.com/dotnet/maui-samples
- **Microsoft Learn**: https://learn.microsoft.com/training/paths/build-apps-with-dotnet-maui

## Project Structure

```
project-root/
├── Platforms/
│   ├── Android/
│   │   ├── MainActivity.cs
│   │   ├── MainApplication.cs
│   │   └── Resources/
│   ├── iOS/
│   │   ├── AppDelegate.cs
│   │   ├── Program.cs
│   │   └── Info.plist
│   ├── MacCatalyst/
│   ├── Tizen/
│   └── Windows/
│       └── Package.appxmanifest
├── Resources/
│   ├── AppIcon/
│   ├── Fonts/
│   ├── Images/
│   ├── Raw/
│   ├── Splash/
│   └── Styles/
│       ├── Colors.xaml
│       └── Styles.xaml
├── Models/
│   ├── User.cs
│   └── Product.cs
├── ViewModels/
│   ├── BaseViewModel.cs
│   ├── MainViewModel.cs
│   └── UserViewModel.cs
├── Views/
│   ├── MainPage.xaml
│   ├── UserPage.xaml
│   └── Components/
├── Services/
│   ├── IDataService.cs
│   ├── DataService.cs
│   └── NavigationService.cs
├── Converters/
├── Controls/
├── Helpers/
├── App.xaml
├── App.xaml.cs
├── AppShell.xaml
├── AppShell.xaml.cs
├── MauiProgram.cs
└── MyApp.csproj
```

## Core Best Practices

### 1. MVVM Pattern Implementation

```csharp
// Base ViewModel
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace MyApp.ViewModels;

public partial class BaseViewModel : ObservableObject
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsNotBusy))]
    private bool isBusy;

    [ObservableProperty]
    private string title = string.Empty;

    public bool IsNotBusy => !IsBusy;

    protected virtual void OnPropertyChanged(string propertyName)
    {
        base.OnPropertyChanged(propertyName);
    }
}

// User ViewModel
public partial class UserViewModel : BaseViewModel
{
    private readonly IUserService _userService;
    private readonly IConnectivity _connectivity;
    private readonly INavigationService _navigationService;

    [ObservableProperty]
    private ObservableCollection<User> users;

    [ObservableProperty]
    private User selectedUser;

    [ObservableProperty]
    private string searchText = string.Empty;

    public UserViewModel(
        IUserService userService, 
        IConnectivity connectivity,
        INavigationService navigationService)
    {
        _userService = userService;
        _connectivity = connectivity;
        _navigationService = navigationService;
        Title = "Users";
        Users = new ObservableCollection<User>();
    }

    [RelayCommand]
    private async Task LoadUsersAsync()
    {
        if (IsBusy) return;

        try
        {
            if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            {
                await Shell.Current.DisplayAlert("No Internet", 
                    "Please check your internet connection", "OK");
                return;
            }

            IsBusy = true;
            var users = await _userService.GetUsersAsync();
            
            if (Users.Count != 0)
                Users.Clear();
                
            foreach (var user in users)
                Users.Add(user);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Unable to load users: {ex.Message}");
            await Shell.Current.DisplayAlert("Error!", 
                $"Unable to load users: {ex.Message}", "OK");
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task NavigateToDetailsAsync(User user)
    {
        if (user == null) return;

        await _navigationService.NavigateToAsync($"{nameof(UserDetailsPage)}",
            new Dictionary<string, object>
            {
                { "User", user }
            });
    }

    [RelayCommand]
    private async Task AddUserAsync()
    {
        await _navigationService.NavigateToAsync(nameof(AddUserPage));
    }

    [RelayCommand]
    private async Task DeleteUserAsync(User user)
    {
        if (user == null) return;

        var result = await Shell.Current.DisplayAlert("Delete", 
            $"Delete {user.Name}?", "Yes", "No");
            
        if (!result) return;

        try
        {
            IsBusy = true;
            await _userService.DeleteUserAsync(user.Id);
            Users.Remove(user);
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlert("Error!", 
                $"Unable to delete user: {ex.Message}", "OK");
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        await LoadUsersAsync();
    }

    partial void OnSearchTextChanged(string value)
    {
        PerformSearch(value);
    }

    private void PerformSearch(string searchText)
    {
        // Implement search logic
    }
}
```

### 2. XAML Views with Data Binding

```xml
<!-- MainPage.xaml -->
<?xml version="1.0" encoding="utf-8" ?>
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             xmlns:vm="clr-namespace:MyApp.ViewModels"
             xmlns:model="clr-namespace:MyApp.Models"
             x:Class="MyApp.Views.MainPage"
             x:DataType="vm:UserViewModel"
             Title="{Binding Title}">

    <ContentPage.ToolbarItems>
        <ToolbarItem Text="Add" 
                     Command="{Binding AddUserCommand}"
                     IconImageSource="add.png"/>
    </ContentPage.ToolbarItems>

    <Grid RowDefinitions="Auto,*">
        <!-- Search Bar -->
        <SearchBar Grid.Row="0"
                   Text="{Binding SearchText}"
                   Placeholder="Search users..."
                   SearchCommand="{Binding RefreshCommand}"/>

        <!-- Users List -->
        <RefreshView Grid.Row="1"
                     Command="{Binding RefreshCommand}"
                     IsRefreshing="{Binding IsBusy}">
            
            <CollectionView ItemsSource="{Binding Users}"
                           SelectionMode="None"
                           EmptyView="No users found">
                
                <CollectionView.ItemTemplate>
                    <DataTemplate x:DataType="model:User">
                        <SwipeView>
                            <SwipeView.RightItems>
                                <SwipeItems>
                                    <SwipeItem Text="Delete"
                                              BackgroundColor="Red"
                                              Command="{Binding Source={RelativeSource AncestorType={x:Type vm:UserViewModel}}, 
                                                       Path=DeleteUserCommand}"
                                              CommandParameter="{Binding .}"/>
                                </SwipeItems>
                            </SwipeView.RightItems>

                            <Frame Padding="10" Margin="5">
                                <Frame.GestureRecognizers>
                                    <TapGestureRecognizer 
                                        Command="{Binding Source={RelativeSource AncestorType={x:Type vm:UserViewModel}}, 
                                                 Path=NavigateToDetailsCommand}"
                                        CommandParameter="{Binding .}"/>
                                </Frame.GestureRecognizers>

                                <Grid ColumnDefinitions="Auto,*,Auto">
                                    <Image Grid.Column="0"
                                           Source="{Binding AvatarUrl}"
                                           HeightRequest="60"
                                           WidthRequest="60"
                                           Aspect="AspectFill">
                                        <Image.Clip>
                                            <EllipseGeometry RadiusX="30" 
                                                           RadiusY="30" 
                                                           Center="30,30"/>
                                        </Image.Clip>
                                    </Image>

                                    <VerticalStackLayout Grid.Column="1" 
                                                        Padding="10,0">
                                        <Label Text="{Binding Name}"
                                               FontAttributes="Bold"
                                               FontSize="16"/>
                                        <Label Text="{Binding Email}"
                                               FontSize="14"
                                               TextColor="Gray"/>
                                        <Label Text="{Binding Role}"
                                               FontSize="12"
                                               TextColor="Blue"/>
                                    </VerticalStackLayout>

                                    <Image Grid.Column="2"
                                           Source="arrow_right.png"
                                           HeightRequest="20"
                                           VerticalOptions="Center"/>
                                </Grid>
                            </Frame>
                        </SwipeView>
                    </DataTemplate>
                </CollectionView.ItemTemplate>
            </CollectionView>
        </RefreshView>

        <!-- Loading Indicator -->
        <ActivityIndicator Grid.Row="1"
                          IsVisible="{Binding IsBusy}"
                          IsRunning="{Binding IsBusy}"
                          HorizontalOptions="Center"
                          VerticalOptions="Center"/>
    </Grid>
</ContentPage>
```

### 3. Services Implementation

```csharp
// Data Service Interface
public interface IDataService
{
    Task<IEnumerable<T>> GetItemsAsync<T>(string endpoint) where T : class;
    Task<T> GetItemAsync<T>(string endpoint, string id) where T : class;
    Task<T> AddItemAsync<T>(string endpoint, T item) where T : class;
    Task<bool> UpdateItemAsync<T>(string endpoint, string id, T item) where T : class;
    Task<bool> DeleteItemAsync(string endpoint, string id);
}

// HTTP Data Service Implementation
public class HttpDataService : IDataService
{
    private readonly HttpClient _httpClient;
    private readonly IConnectivity _connectivity;
    private readonly JsonSerializerOptions _serializerOptions;

    public HttpDataService(HttpClient httpClient, IConnectivity connectivity)
    {
        _httpClient = httpClient;
        _connectivity = connectivity;
        _serializerOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true
        };
    }

    public async Task<IEnumerable<T>> GetItemsAsync<T>(string endpoint) where T : class
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            throw new Exception("No internet connection");

        try
        {
            var response = await _httpClient.GetAsync(endpoint);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            return JsonSerializer.Deserialize<IEnumerable<T>>(content, _serializerOptions);
        }
        catch (HttpRequestException ex)
        {
            Debug.WriteLine($"HTTP Request Error: {ex.Message}");
            throw;
        }
        catch (TaskCanceledException ex)
        {
            Debug.WriteLine($"Request Timeout: {ex.Message}");
            throw new Exception("Request timeout");
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"General Error: {ex.Message}");
            throw;
        }
    }

    public async Task<T> GetItemAsync<T>(string endpoint, string id) where T : class
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            throw new Exception("No internet connection");

        var response = await _httpClient.GetAsync($"{endpoint}/{id}");
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(content, _serializerOptions);
    }

    public async Task<T> AddItemAsync<T>(string endpoint, T item) where T : class
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            throw new Exception("No internet connection");

        var json = JsonSerializer.Serialize(item, _serializerOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PostAsync(endpoint, content);
        response.EnsureSuccessStatusCode();
        
        var responseContent = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(responseContent, _serializerOptions);
    }

    public async Task<bool> UpdateItemAsync<T>(string endpoint, string id, T item) where T : class
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            throw new Exception("No internet connection");

        var json = JsonSerializer.Serialize(item, _serializerOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PutAsync($"{endpoint}/{id}", content);
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> DeleteItemAsync(string endpoint, string id)
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
            throw new Exception("No internet connection");

        var response = await _httpClient.DeleteAsync($"{endpoint}/{id}");
        return response.IsSuccessStatusCode;
    }
}

// Local Database Service
public class LocalDatabaseService : ILocalDatabaseService
{
    private SQLiteAsyncConnection _database;
    private readonly string _dbPath;

    public LocalDatabaseService()
    {
        _dbPath = Path.Combine(FileSystem.AppDataDirectory, "myapp.db3");
    }

    private async Task Init()
    {
        if (_database != null)
            return;

        _database = new SQLiteAsyncConnection(_dbPath, 
            SQLiteOpenFlags.Create | 
            SQLiteOpenFlags.ReadWrite | 
            SQLiteOpenFlags.SharedCache);

        await _database.CreateTableAsync<User>();
        await _database.CreateTableAsync<Product>();
    }

    public async Task<IEnumerable<T>> GetItemsAsync<T>() where T : class, new()
    {
        await Init();
        return await _database.Table<T>().ToListAsync();
    }

    public async Task<T> GetItemAsync<T>(int id) where T : class, new()
    {
        await Init();
        return await _database.GetAsync<T>(id);
    }

    public async Task<int> SaveItemAsync<T>(T item) where T : class, new()
    {
        await Init();
        
        var hasId = item.GetType().GetProperty("Id");
        if (hasId != null)
        {
            var id = (int)hasId.GetValue(item);
            if (id != 0)
                return await _database.UpdateAsync(item);
        }
        
        return await _database.InsertAsync(item);
    }

    public async Task<int> DeleteItemAsync<T>(T item) where T : class, new()
    {
        await Init();
        return await _database.DeleteAsync(item);
    }
}
```

### 4. Platform-Specific Code

```csharp
// Platform Service Interface
public interface IPlatformService
{
    string GetPlatformName();
    Task<bool> RequestPermissionAsync(string permission);
    void ShowToast(string message);
}

// Android Implementation
#if ANDROID
using Android.Widget;
using AndroidX.Core.App;
using AndroidX.Core.Content;

namespace MyApp.Platforms.Android;

public class PlatformService : IPlatformService
{
    public string GetPlatformName() => "Android";

    public async Task<bool> RequestPermissionAsync(string permission)
    {
        var status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
        
        if (status != PermissionStatus.Granted)
        {
            status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
        }
        
        return status == PermissionStatus.Granted;
    }

    public void ShowToast(string message)
    {
        Platform.CurrentActivity?.RunOnUiThread(() =>
        {
            Toast.MakeText(Platform.CurrentActivity, message, ToastLength.Short)?.Show();
        });
    }
}
#endif

// iOS Implementation
#if IOS
using UIKit;

namespace MyApp.Platforms.iOS;

public class PlatformService : IPlatformService
{
    public string GetPlatformName() => "iOS";

    public async Task<bool> RequestPermissionAsync(string permission)
    {
        var status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
        
        if (status != PermissionStatus.Granted)
        {
            status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
        }
        
        return status == PermissionStatus.Granted;
    }

    public void ShowToast(string message)
    {
        var window = UIApplication.SharedApplication.KeyWindow;
        if (window != null)
        {
            var toast = new UIAlertController(null, message, UIAlertControllerStyle.Alert);
            window.RootViewController?.PresentViewController(toast, true, null);
            
            Task.Delay(2000).ContinueWith(_ =>
            {
                Device.BeginInvokeOnMainThread(() =>
                {
                    toast.DismissViewController(true, null);
                });
            });
        }
    }
}
#endif
```

### 5. Custom Controls

```csharp
// Custom Entry Control
public class BorderlessEntry : Entry
{
    public static readonly BindableProperty BorderColorProperty =
        BindableProperty.Create(nameof(BorderColor), typeof(Color), typeof(BorderlessEntry), Colors.Gray);

    public Color BorderColor
    {
        get => (Color)GetValue(BorderColorProperty);
        set => SetValue(BorderColorProperty, value);
    }

    public static readonly BindableProperty BorderWidthProperty =
        BindableProperty.Create(nameof(BorderWidth), typeof(int), typeof(BorderlessEntry), 1);

    public int BorderWidth
    {
        get => (int)GetValue(BorderWidthProperty);
        set => SetValue(BorderWidthProperty, value);
    }
}

// Custom Renderer for Android
#if ANDROID
using Android.Content;
using Android.Graphics.Drawables;
using Microsoft.Maui.Controls.Compatibility.Platform.Android;

namespace MyApp.Platforms.Android.Renderers;

public class BorderlessEntryRenderer : EntryRenderer
{
    public BorderlessEntryRenderer(Context context) : base(context) { }

    protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
    {
        base.OnElementChanged(e);
        
        if (Control != null)
        {
            Control.Background = new ColorDrawable(Android.Graphics.Color.Transparent);
        }
    }
}
#endif
```

### 6. Navigation

```csharp
// Navigation Service
public interface INavigationService
{
    Task NavigateToAsync(string route);
    Task NavigateToAsync(string route, IDictionary<string, object> parameters);
    Task GoBackAsync();
    Task GoToRootAsync();
}

public class NavigationService : INavigationService
{
    public async Task NavigateToAsync(string route)
    {
        await Shell.Current.GoToAsync(route);
    }

    public async Task NavigateToAsync(string route, IDictionary<string, object> parameters)
    {
        await Shell.Current.GoToAsync(route, parameters);
    }

    public async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    public async Task GoToRootAsync()
    {
        await Shell.Current.GoToAsync("//MainPage");
    }
}

// Shell Configuration
public partial class AppShell : Shell
{
    public AppShell()
    {
        InitializeComponent();
        RegisterRoutes();
    }

    private void RegisterRoutes()
    {
        Routing.RegisterRoute(nameof(UserDetailsPage), typeof(UserDetailsPage));
        Routing.RegisterRoute(nameof(AddUserPage), typeof(AddUserPage));
        Routing.RegisterRoute(nameof(SettingsPage), typeof(SettingsPage));
    }
}
```

### 7. Dependency Injection

```csharp
// MauiProgram.cs
public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

        // Register Services
        builder.Services.AddSingleton<IConnectivity>(Connectivity.Current);
        builder.Services.AddSingleton<IGeolocation>(Geolocation.Default);
        builder.Services.AddSingleton<IMap>(Map.Default);
        
        // HTTP Client
        builder.Services.AddHttpClient<IDataService, HttpDataService>(client =>
        {
            client.BaseAddress = new Uri(AppSettings.ApiBaseUrl);
            client.DefaultRequestHeaders.Add("Accept", "application/json");
        });

        // Services
        builder.Services.AddSingleton<ILocalDatabaseService, LocalDatabaseService>();
        builder.Services.AddSingleton<INavigationService, NavigationService>();
        builder.Services.AddTransient<IUserService, UserService>();
        
        // ViewModels
        builder.Services.AddTransient<MainViewModel>();
        builder.Services.AddTransient<UserViewModel>();
        builder.Services.AddTransient<UserDetailsViewModel>();
        
        // Pages
        builder.Services.AddTransient<MainPage>();
        builder.Services.AddTransient<UserPage>();
        builder.Services.AddTransient<UserDetailsPage>();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
```

### Common Pitfalls to Avoid

1. **Not handling platform differences**
2. **Ignoring performance on mobile devices**
3. **Not implementing proper data caching**
4. **Using synchronous I/O operations**
5. **Not handling connectivity changes**
6. **Creating memory leaks with event handlers**
7. **Not optimizing images and resources**
8. **Ignoring platform-specific UI guidelines**
9. **Not testing on physical devices**
10. **Not implementing proper error handling**

### Useful NuGet Packages

- **CommunityToolkit.Maui**: MAUI Community Toolkit
- **CommunityToolkit.Mvvm**: MVVM Toolkit
- **sqlite-net-pcl**: SQLite database
- **Newtonsoft.Json**: JSON serialization
- **SkiaSharp**: 2D graphics
- **Microsoft.Extensions.Http**: HTTP client factory
- **Refit**: REST library
- **Akavache**: Asynchronous key-value store
- **Plugin.InAppBilling**: In-app purchases
- **Plugin.Fingerprint**: Biometric authentication