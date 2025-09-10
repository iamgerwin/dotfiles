# Vaadin Best Practices

## Overview
Vaadin is a Java framework for building modern web applications entirely in Java, without writing HTML, CSS, or JavaScript. It provides a component-based programming model with automatic client-server communication.

## Documentation
- [Official Documentation](https://vaadin.com/docs/latest)
- [Component Gallery](https://vaadin.com/components)
- [Vaadin Start](https://start.vaadin.com)
- [API Documentation](https://vaadin.com/api)

## Project Structure

```
project-root/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── views/
│   │   │           │   ├── main/
│   │   │           │   ├── dashboard/
│   │   │           │   └── users/
│   │   │           ├── components/
│   │   │           ├── data/
│   │   │           │   ├── entity/
│   │   │           │   ├── service/
│   │   │           │   └── repository/
│   │   │           ├── security/
│   │   │           └── Application.java
│   │   └── resources/
│   │       ├── META-INF/
│   │       ├── application.properties
│   │       └── vaadin/
│   └── test/
├── frontend/
│   ├── themes/
│   │   └── my-theme/
│   │       ├── styles.css
│   │       └── theme.json
│   └── index.html
├── package.json
├── pom.xml
└── README.md
```

## Core Best Practices

### 1. View Creation

```java
@Route(value = "", layout = MainLayout.class)
@PageTitle("Dashboard")
@PermitAll
public class DashboardView extends VerticalLayout {
    
    private final UserService userService;
    private Grid<User> grid = new Grid<>(User.class);
    private TextField filterText = new TextField();
    
    public DashboardView(UserService userService) {
        this.userService = userService;
        
        addClassName("dashboard-view");
        setSizeFull();
        
        configureGrid();
        add(getToolbar(), grid);
        updateList();
    }
    
    private void configureGrid() {
        grid.addClassName("user-grid");
        grid.setSizeFull();
        
        grid.setColumns("firstName", "lastName", "email");
        grid.addColumn(user -> user.getStatus().name()).setHeader("Status");
        grid.addColumn(new LocalDateTimeRenderer<>(
            User::getCreatedAt,
            "yyyy-MM-dd HH:mm"
        )).setHeader("Created");
        
        grid.getColumns().forEach(col -> col.setAutoWidth(true));
        
        grid.asSingleSelect().addValueChangeListener(event ->
            editUser(event.getValue())
        );
    }
    
    private HorizontalLayout getToolbar() {
        filterText.setPlaceholder("Filter by name...");
        filterText.setClearButtonVisible(true);
        filterText.setValueChangeMode(ValueChangeMode.LAZY);
        filterText.addValueChangeListener(e -> updateList());
        
        Button addUserBtn = new Button("Add user");
        addUserBtn.addClickListener(click -> addUser());
        
        HorizontalLayout toolbar = new HorizontalLayout(filterText, addUserBtn);
        toolbar.addClassName("toolbar");
        return toolbar;
    }
    
    private void updateList() {
        grid.setItems(userService.findAll(filterText.getValue()));
    }
}
```

### 2. Layout Management

```java
@PWA(name = "My Application", shortName = "MyApp")
@Theme(value = "my-theme")
public class MainLayout extends AppLayout {
    
    private final SecurityService securityService;
    
    public MainLayout(SecurityService securityService) {
        this.securityService = securityService;
        
        createHeader();
        createDrawer();
    }
    
    private void createHeader() {
        H1 logo = new H1("My Application");
        logo.addClassNames("text-l", "m-m");
        
        Button logout = new Button("Log out", e -> 
            securityService.logout()
        );
        
        HorizontalLayout header = new HorizontalLayout(
            new DrawerToggle(),
            logo,
            logout
        );
        
        header.setDefaultVerticalComponentAlignment(
            FlexComponent.Alignment.CENTER
        );
        header.expand(logo);
        header.setWidthFull();
        header.addClassNames("py-0", "px-m");
        
        addToNavbar(header);
    }
    
    private void createDrawer() {
        RouterLink dashboardLink = new RouterLink("Dashboard", DashboardView.class);
        dashboardLink.setHighlightCondition(HighlightConditions.sameLocation());
        
        RouterLink usersLink = new RouterLink("Users", UsersView.class);
        RouterLink reportsLink = new RouterLink("Reports", ReportsView.class);
        
        addToDrawer(new VerticalLayout(
            dashboardLink,
            usersLink,
            reportsLink
        ));
    }
}
```

### 3. Forms and Data Binding

```java
public class UserForm extends FormLayout {
    
    private TextField firstName = new TextField("First name");
    private TextField lastName = new TextField("Last name");
    private EmailField email = new EmailField("Email");
    private ComboBox<Department> department = new ComboBox<>("Department");
    private DatePicker birthDate = new DatePicker("Birth date");
    private Checkbox active = new Checkbox("Active");
    
    private Button save = new Button("Save");
    private Button delete = new Button("Delete");
    private Button cancel = new Button("Cancel");
    
    private Binder<User> binder = new BeanValidationBinder<>(User.class);
    
    public UserForm(List<Department> departments) {
        addClassName("user-form");
        
        configureBinder();
        
        department.setItems(departments);
        department.setItemLabelGenerator(Department::getName);
        
        add(
            firstName,
            lastName,
            email,
            department,
            birthDate,
            active,
            createButtonsLayout()
        );
    }
    
    private void configureBinder() {
        binder.bindInstanceFields(this);
        
        // Custom validation
        binder.forField(email)
            .withValidator(new EmailValidator("Invalid email address"))
            .bind(User::getEmail, User::setEmail);
            
        binder.forField(birthDate)
            .withValidator(
                date -> date == null || date.isBefore(LocalDate.now()),
                "Birth date cannot be in the future"
            )
            .bind(User::getBirthDate, User::setBirthDate);
    }
    
    private Component createButtonsLayout() {
        save.addThemeVariants(ButtonVariant.LUMO_PRIMARY);
        delete.addThemeVariants(ButtonVariant.LUMO_ERROR);
        cancel.addThemeVariants(ButtonVariant.LUMO_TERTIARY);
        
        save.addClickShortcut(Key.ENTER);
        cancel.addClickShortcut(Key.ESCAPE);
        
        save.addClickListener(event -> validateAndSave());
        delete.addClickListener(event -> fireEvent(new DeleteEvent(this, binder.getBean())));
        cancel.addClickListener(event -> fireEvent(new CloseEvent(this)));
        
        binder.addStatusChangeListener(e -> save.setEnabled(binder.isValid()));
        
        return new HorizontalLayout(save, delete, cancel);
    }
    
    private void validateAndSave() {
        if (binder.isValid()) {
            fireEvent(new SaveEvent(this, binder.getBean()));
        }
    }
    
    public void setUser(User user) {
        binder.setBean(user);
    }
    
    // Events
    public static abstract class UserFormEvent extends ComponentEvent<UserForm> {
        private User user;
        
        protected UserFormEvent(UserForm source, User user) {
            super(source, false);
            this.user = user;
        }
        
        public User getUser() {
            return user;
        }
    }
    
    public static class SaveEvent extends UserFormEvent {
        SaveEvent(UserForm source, User user) {
            super(source, user);
        }
    }
    
    public static class DeleteEvent extends UserFormEvent {
        DeleteEvent(UserForm source, User user) {
            super(source, user);
        }
    }
    
    public static class CloseEvent extends UserFormEvent {
        CloseEvent(UserForm source) {
            super(source, null);
        }
    }
    
    public Registration addSaveListener(ComponentEventListener<SaveEvent> listener) {
        return addListener(SaveEvent.class, listener);
    }
    
    public Registration addDeleteListener(ComponentEventListener<DeleteEvent> listener) {
        return addListener(DeleteEvent.class, listener);
    }
    
    public Registration addCloseListener(ComponentEventListener<CloseEvent> listener) {
        return addListener(CloseEvent.class, listener);
    }
}
```

### 4. Custom Components

```java
@JsModule("./components/chart-widget.js")
@NpmPackage(value = "chart.js", version = "3.9.1")
public class ChartWidget extends Component implements HasSize {
    
    public ChartWidget() {
        setId("chart-widget-" + UUID.randomUUID());
    }
    
    public void setChartData(ChartData data) {
        getElement().setPropertyJson("chartData", 
            JsonSerializer.toJson(data));
    }
    
    @ClientCallable
    public void onChartClick(String dataPoint) {
        Notification.show("Clicked: " + dataPoint);
    }
}
```

### 5. Data Providers and Lazy Loading

```java
public class UserDataProvider extends AbstractBackEndDataProvider<User, UserFilter> {
    
    private final UserService userService;
    
    public UserDataProvider(UserService userService) {
        this.userService = userService;
    }
    
    @Override
    protected Stream<User> fetchFromBackEnd(Query<User, UserFilter> query) {
        return userService.fetch(
            query.getOffset(),
            query.getLimit(),
            query.getFilter().orElse(null),
            query.getSortOrders()
        ).stream();
    }
    
    @Override
    protected int sizeInBackEnd(Query<User, UserFilter> query) {
        return userService.count(query.getFilter().orElse(null));
    }
}

// Usage in Grid
Grid<User> grid = new Grid<>();
UserDataProvider dataProvider = new UserDataProvider(userService);
grid.setDataProvider(dataProvider);

// With filtering
ConfigurableFilterDataProvider<User, Void, UserFilter> filterDataProvider = 
    dataProvider.withConfigurableFilter();
    
filterDataProvider.setFilter(new UserFilter(searchText, selectedDepartment));
```

### 6. Navigation and Routing

```java
@Route(value = "user/:userID?/:action?(edit)")
@PageTitle("User Details")
public class UserView extends Div implements BeforeEnterObserver {
    
    private final String USER_ID = "userID";
    private final String USER_EDIT_ROUTE_TEMPLATE = "user/%s/edit";
    
    private final UserService userService;
    private User user;
    
    @Override
    public void beforeEnter(BeforeEnterEvent event) {
        Optional<Long> userId = event.getRouteParameters()
            .get(USER_ID)
            .map(Long::parseLong);
            
        if (userId.isPresent()) {
            Optional<User> userFromBackend = userService.findById(userId.get());
            
            if (userFromBackend.isPresent()) {
                populateForm(userFromBackend.get());
            } else {
                Notification.show(
                    String.format("User not found, ID = %s", userId.get()),
                    3000,
                    Notification.Position.BOTTOM_START
                );
                event.forwardTo(UsersView.class);
            }
        }
    }
    
    private void navigateToEdit(User user) {
        getUI().ifPresent(ui -> 
            ui.navigate(String.format(USER_EDIT_ROUTE_TEMPLATE, user.getId()))
        );
    }
}
```

### 7. Security Configuration

```java
@EnableWebSecurity
@Configuration
public class SecurityConfiguration extends VaadinWebSecurityConfigurerAdapter {
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        super.configure(http);
        
        setLoginView(http, LoginView.class);
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    public UserDetailsService userDetailsService() {
        return new CustomUserDetailsService();
    }
}

@Route("login")
@PageTitle("Login")
@AnonymousAllowed
public class LoginView extends VerticalLayout implements BeforeEnterObserver {
    
    private final LoginForm login = new LoginForm();
    
    public LoginView() {
        addClassName("login-view");
        setSizeFull();
        setAlignItems(Alignment.CENTER);
        setJustifyContentMode(JustifyContentMode.CENTER);
        
        login.setAction("login");
        
        add(new H1("My Application"), login);
    }
    
    @Override
    public void beforeEnter(BeforeEnterEvent event) {
        if (event.getLocation()
            .getQueryParameters()
            .getParameters()
            .containsKey("error")) {
            login.setError(true);
        }
    }
}
```

### 8. Notifications and Dialogs

```java
public class NotificationUtils {
    
    public static void showSuccess(String message) {
        Notification notification = Notification.show(
            message,
            3000,
            Notification.Position.TOP_CENTER
        );
        notification.addThemeVariants(NotificationVariant.LUMO_SUCCESS);
    }
    
    public static void showError(String message) {
        Notification notification = Notification.show(
            message,
            5000,
            Notification.Position.TOP_CENTER
        );
        notification.addThemeVariants(NotificationVariant.LUMO_ERROR);
    }
    
    public static void showWarning(String message) {
        Notification notification = new Notification();
        notification.addThemeVariants(NotificationVariant.LUMO_CONTRAST);
        notification.setPosition(Notification.Position.MIDDLE);
        
        Div text = new Div(new Text(message));
        
        Button closeButton = new Button(new Icon("lumo", "cross"));
        closeButton.addThemeVariants(ButtonVariant.LUMO_TERTIARY_INLINE);
        closeButton.addClickListener(event -> notification.close());
        
        HorizontalLayout layout = new HorizontalLayout(text, closeButton);
        layout.setAlignItems(FlexComponent.Alignment.CENTER);
        
        notification.add(layout);
        notification.open();
    }
}

// Confirmation Dialog
public class ConfirmDialog extends Dialog {
    
    public ConfirmDialog(String title, String message, 
                        Runnable onConfirm, Runnable onCancel) {
        setHeaderTitle(title);
        
        add(new Paragraph(message));
        
        Button confirmButton = new Button("Confirm", e -> {
            onConfirm.run();
            close();
        });
        confirmButton.addThemeVariants(ButtonVariant.LUMO_PRIMARY);
        
        Button cancelButton = new Button("Cancel", e -> {
            if (onCancel != null) onCancel.run();
            close();
        });
        
        getFooter().add(cancelButton, confirmButton);
    }
}
```

## Theming and Styling

### 1. Custom Theme
```css
/* frontend/themes/my-theme/styles.css */
@import url('./main-layout.css');
@import url('lumo-css-framework/all-classes.css');

:root {
    --lumo-primary-color: #2196F3;
    --lumo-primary-text-color: #1976D2;
}

.dashboard-view {
    display: flex;
    flex-direction: column;
    height: 100%;
}

.user-grid {
    flex: 1;
}

.toolbar {
    padding: var(--lumo-space-m);
    gap: var(--lumo-space-m);
}
```

### 2. Theme Configuration
```json
{
  "lumoImports": ["typography", "color", "spacing", "badge", "utility"],
  "assets": {
    "@fortawesome/fontawesome-free": {
      "svgs/solid/*.svg": "fortawesome/solid"
    }
  }
}
```

## Testing

```java
@SpringBootTest
public class DashboardViewTest extends KaribuTest {
    
    @Autowired
    private UserService userService;
    
    @BeforeEach
    public void setup() {
        final Routes routes = new Routes().autoDiscoverViews("com.example");
        RouteRegistry.getInstance().setRoutes(routes);
    }
    
    @Test
    public void shouldDisplayUsers() {
        // Navigate to view
        UI.getCurrent().navigate(DashboardView.class);
        
        // Get the view
        DashboardView view = $(DashboardView.class).first();
        assertNotNull(view);
        
        // Check grid
        Grid<User> grid = $(Grid.class).first();
        assertNotNull(grid);
        
        // Verify data
        assertEquals(10, grid.getDataProvider().size(new Query<>()));
    }
    
    @Test
    public void shouldFilterUsers() {
        UI.getCurrent().navigate(DashboardView.class);
        
        TextField filterField = $(TextField.class).first();
        filterField.setValue("John");
        
        Grid<User> grid = $(Grid.class).first();
        assertTrue(grid.getDataProvider().size(new Query<>()) < 10);
    }
}
```

## Performance Optimization

1. **Lazy Loading**: Use data providers for large datasets
2. **Virtual Scrolling**: Enable for grids with many rows
3. **Component Pooling**: Reuse components when possible
4. **Push Configuration**: Use appropriate push mode
5. **Session Management**: Configure session timeout properly
6. **Production Mode**: Always build for production
7. **Bundle Optimization**: Minimize JavaScript bundle size

## Production Build

```xml
<!-- pom.xml -->
<profiles>
    <profile>
        <id>production</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>com.vaadin</groupId>
                    <artifactId>vaadin-maven-plugin</artifactId>
                    <executions>
                        <execution>
                            <id>frontend</id>
                            <phase>compile</phase>
                            <goals>
                                <goal>prepare-frontend</goal>
                                <goal>build-frontend</goal>
                            </goals>
                            <configuration>
                                <productionMode>true</productionMode>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

## Common Pitfalls

1. **UI Access**: Always use `UI.getCurrent().access()` for background threads
2. **Memory Leaks**: Properly detach listeners and observers
3. **Session Size**: Don't store large objects in session
4. **Push Issues**: Configure WebSocket/long-polling properly
5. **Browser Compatibility**: Test on target browsers
6. **State Management**: Be careful with component state

## Useful Add-ons

- **Vaadin Charts**: Advanced charting components
- **Vaadin Grid Pro**: Inline editing for Grid
- **Vaadin Board**: Responsive dashboard layouts
- **Vaadin Designer**: Visual UI designer
- **Vaadin TestBench**: Browser automation testing
- **Collaboration Engine**: Real-time collaboration features
- **Crud UI Add-on**: CRUD operations UI