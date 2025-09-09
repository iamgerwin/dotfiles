# Ash/Elixir Best Practices

## Official Documentation
- **Elixir Documentation**: https://elixir-lang.org/docs.html
- **Ash Framework**: https://ash-hq.org/docs
- **Phoenix Framework**: https://www.phoenixframework.org/
- **Hex Package Manager**: https://hex.pm

## Project Structure

```
project-root/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   └── test.exs
├── lib/
│   ├── my_app/
│   │   ├── accounts/
│   │   │   ├── resources/
│   │   │   │   ├── user.ex
│   │   │   │   └── token.ex
│   │   │   ├── accounts.ex
│   │   │   └── registry.ex
│   │   ├── blog/
│   │   │   ├── resources/
│   │   │   │   ├── post.ex
│   │   │   │   └── comment.ex
│   │   │   ├── blog.ex
│   │   │   └── registry.ex
│   │   ├── repo.ex
│   │   └── application.ex
│   ├── my_app_web/
│   │   ├── controllers/
│   │   ├── views/
│   │   ├── templates/
│   │   ├── channels/
│   │   ├── live/
│   │   ├── router.ex
│   │   └── endpoint.ex
│   └── my_app.ex
├── priv/
│   ├── repo/
│   │   ├── migrations/
│   │   └── seeds.exs
│   └── static/
├── test/
│   ├── my_app/
│   ├── my_app_web/
│   ├── support/
│   └── test_helper.exs
├── mix.exs
└── mix.lock
```

## Core Best Practices

### 1. Ash Resource Definition

```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo MyApp.Repo
  end

  code_interface do
    define_for MyApp.Accounts
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, args: [:id], action: :by_id
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :by_id do
      argument :id, :uuid, allow_nil?: false
      get? true
      filter expr(id == ^arg(:id))
    end

    create :register do
      accept [:email, :username]
      argument :password, :string, allow_nil?: false, sensitive?: true
      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      validate confirm(:password, :password_confirmation)
      
      change fn changeset, _ ->
        Ash.Changeset.change_attribute(
          changeset,
          :hashed_password,
          Bcrypt.hash_pwd_salt(Ash.Changeset.get_argument(changeset, :password))
        )
      end
    end

    update :update_profile do
      accept [:username, :bio, :avatar_url]
      
      validate fn changeset, _context ->
        username = Ash.Changeset.get_attribute(changeset, :username)
        
        if String.length(username) < 3 do
          {:error, field: :username, message: "must be at least 3 characters"}
        else
          :ok
        end
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      constraints [
        match: ~r/^[^\s]+@[^\s]+$/,
        max_length: 160
      ]
    end

    attribute :username, :string do
      allow_nil? false
      constraints [min_length: 3, max_length: 30]
    end

    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :bio, :string, constraints: [max_length: 500]
    attribute :avatar_url, :string
    attribute :confirmed_at, :utc_datetime_usec
    attribute :role, :atom do
      constraints [one_of: [:user, :moderator, :admin]]
      default :user
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :posts, MyApp.Blog.Post do
      destination_attribute :author_id
    end

    has_many :comments, MyApp.Blog.Comment do
      destination_attribute :user_id
    end

    many_to_many :following, __MODULE__ do
      through MyApp.Accounts.Follow
      source_attribute_on_join_resource :follower_id
      destination_attribute_on_join_resource :followed_id
    end
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+$/), message: "must be a valid email"
  end

  calculations do
    calculate :full_name, :string, expr(first_name <> " " <> last_name)
    
    calculate :post_count, :integer do
      calculation fn records, _opts ->
        Enum.map(records, fn record ->
          MyApp.Blog.Post
          |> Ash.Query.filter(author_id == ^record.id)
          |> MyApp.Blog.count!()
        end)
      end
    end
  end

  aggregates do
    count :total_posts, :posts
    count :total_comments, :comments
  end
end
```

### 2. Ash API Module

```elixir
defmodule MyApp.Accounts do
  use Ash.Api

  resources do
    registry MyApp.Accounts.Registry
  end

  # Custom functions
  def authenticate(email, password) do
    with {:ok, user} <- get_user_by_email(email),
         true <- Bcrypt.verify_pass(password, user.hashed_password) do
      {:ok, user}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  def get_user_by_email(email) do
    User
    |> Ash.Query.filter(email == ^email)
    |> read_one()
  end

  def confirm_user(token) do
    with {:ok, user_id} <- MyApp.Token.verify_email_token(token),
         {:ok, user} <- get(User, user_id) do
      user
      |> Ash.Changeset.for_update(:confirm)
      |> Ash.Changeset.change_attribute(:confirmed_at, DateTime.utc_now())
      |> update()
    end
  end
end
```

### 3. Phoenix LiveView with Ash

```elixir
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view
  
  alias MyApp.Accounts
  alias MyApp.Accounts.User

  @impl true
  def mount(_params, session, socket) do
    socket = 
      socket
      |> assign_current_user(session)
      |> assign(:users, list_users())
      |> assign(:filter, %{})
    
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get!(User, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, params) do
    filter = build_filter(params)
    
    socket
    |> assign(:page_title, "Users")
    |> assign(:user, nil)
    |> assign(:filter, filter)
    |> assign(:users, list_users(filter))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get!(User, id)
    {:ok, _} = Accounts.destroy(user)

    {:noreply, assign(socket, :users, list_users())}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filter = build_filter(filter_params)
    
    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:users, list_users(filter))
     |> push_patch(to: Routes.user_index_path(socket, :index, filter))}
  end

  defp list_users(filter \\ %{}) do
    User
    |> maybe_filter_by_role(filter[:role])
    |> maybe_filter_by_search(filter[:search])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Accounts.read!()
  end

  defp maybe_filter_by_role(query, nil), do: query
  defp maybe_filter_by_role(query, role) do
    Ash.Query.filter(query, role == ^role)
  end

  defp maybe_filter_by_search(query, nil), do: query
  defp maybe_filter_by_search(query, search) do
    search_term = "%#{search}%"
    Ash.Query.filter(query, 
      ilike(username, ^search_term) or ilike(email, ^search_term)
    )
  end
end
```

### 4. GraphQL with Ash

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema
  
  @apis [MyApp.Accounts, MyApp.Blog]
  
  use AshGraphql, apis: @apis
  
  query do
    # Ash auto-generates queries
  end
  
  mutation do
    # Ash auto-generates mutations
  end
  
  # Custom queries
  query do
    field :current_user, :user do
      resolve fn _, _, %{context: %{current_user: user}} ->
        {:ok, user}
      end
    end
  end
  
  # Custom mutations
  mutation do
    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      
      resolve fn %{email: email, password: password}, _ ->
        case MyApp.Accounts.authenticate(email, password) do
          {:ok, user} ->
            token = MyApp.Token.generate_user_session_token(user)
            {:ok, %{user: user, token: token}}
          
          {:error, _} ->
            {:error, message: "Invalid credentials"}
        end
      end
    end
  end
end

# In Resource
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  graphql do
    type :post
    
    queries do
      get :get_post, :read
      list :list_posts, :read
    end
    
    mutations do
      create :create_post, :create
      update :update_post, :update
      destroy :delete_post, :destroy
    end
  end
  
  # ... rest of resource definition
end
```

### 5. Testing with Ash

```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase
  
  alias MyApp.Accounts
  alias MyApp.Accounts.User

  describe "users" do
    @valid_attrs %{
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    }
    
    @invalid_attrs %{email: "invalid", username: "ab"}

    test "register/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = 
        User
        |> Ash.Changeset.for_create(:register, @valid_attrs)
        |> Accounts.create()
      
      assert user.email == "test@example.com"
      assert user.username == "testuser"
      assert user.hashed_password != "password123"
    end

    test "register/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:register, @invalid_attrs)
        |> Accounts.create()
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get!(User, user.id) == user
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{username: "updated"}

      assert {:ok, %User{} = user} = 
        user
        |> Ash.Changeset.for_update(:update, update_attrs)
        |> Accounts.update()
      
      assert user.username == "updated"
    end
  end

  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_attrs)
      |> then(&Ash.Changeset.for_create(User, :register, &1))
      |> Accounts.create()

    user
  end
end
```

### 6. Authorization with Ash Policies

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  policies do
    # Anyone can read published posts
    policy action_type(:read) do
      authorize_if expr(published == true)
    end
    
    # Authors can do anything with their own posts
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(author_id == ^actor(:id))
    end
    
    # Admins can do anything
    policy always() do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  field_policies do
    # Only authors and admins can see draft content
    field_policy :draft_content do
      authorize_if expr(author_id == ^actor(:id))
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  # ... rest of resource
end
```

### 7. GenServer Pattern

```elixir
defmodule MyApp.Cache do
  use GenServer
  
  @cleanup_interval :timer.minutes(5)

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value, ttl \\ :timer.minutes(10)) do
    GenServer.cast(__MODULE__, {:put, key, value, ttl})
  end

  def delete(key) do
    GenServer.cast(__MODULE__, {:delete, key})
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    :ets.new(:cache_table, [:set, :protected, :named_table])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    reply = 
      case :ets.lookup(:cache_table, key) do
        [{^key, value, expiry}] ->
          if DateTime.compare(expiry, DateTime.utc_now()) == :gt do
            {:ok, value}
          else
            :ets.delete(:cache_table, key)
            {:error, :not_found}
          end
        [] ->
          {:error, :not_found}
      end
    
    {:reply, reply, state}
  end

  @impl true
  def handle_cast({:put, key, value, ttl}, state) do
    expiry = DateTime.add(DateTime.utc_now(), ttl, :millisecond)
    :ets.insert(:cache_table, {key, value, expiry})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete, key}, state) do
    :ets.delete(:cache_table, key)
    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  defp cleanup_expired do
    now = DateTime.utc_now()
    
    :ets.select_delete(:cache_table, [
      {
        {:"$1", :"$2", :"$3"},
        [{:<, :"$3", now}],
        [true]
      }
    ])
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
```

### 8. Error Handling

```elixir
defmodule MyApp.ErrorHandler do
  @moduledoc """
  Centralized error handling
  """

  def handle_error({:error, %Ash.Error.Invalid{} = error}) do
    errors = 
      error
      |> Ash.Error.to_error_class()
      |> Map.get(:errors, [])
      |> Enum.map(&format_error/1)
    
    {:error, errors}
  end

  def handle_error({:error, :not_found}) do
    {:error, "Resource not found"}
  end

  def handle_error({:error, reason}) when is_binary(reason) do
    {:error, reason}
  end

  def handle_error(_), do: {:error, "An unexpected error occurred"}

  defp format_error(%{field: field, message: message}) do
    %{field: field, message: message}
  end

  defp format_error(%{message: message}) do
    %{message: message}
  end

  defp format_error(_), do: %{message: "Unknown error"}
end

# Usage with pattern matching
def create_user(params) do
  with {:ok, user} <- 
         User
         |> Ash.Changeset.for_create(:register, params)
         |> MyApp.Accounts.create() do
    {:ok, user}
  else
    error -> MyApp.ErrorHandler.handle_error(error)
  end
end
```

### 9. Configuration Management

```elixir
# config/config.exs
import Config

config :my_app,
  ecto_repos: [MyApp.Repo],
  generators: [binary_id: true]

config :my_app, MyApp.Repo,
  migration_primary_key: [type: :binary_id],
  migration_foreign_key: [type: :binary_id]

config :ash,
  include_embedded_source_by_default?: false,
  default_page_size: 20,
  max_page_size: 100

# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      """

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    ssl_opts: [verify: :verify_none]

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  config :my_app, MyAppWeb.Endpoint,
    http: [port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: secret_key_base
end
```

### Common Pitfalls to Avoid

1. **Not leveraging OTP patterns properly**
2. **Ignoring supervision trees**
3. **Not using pattern matching effectively**
4. **Creating bottlenecks with GenServers**
5. **Not handling errors with proper patterns**
6. **Ignoring Ash's built-in features**
7. **Not using Ecto changesets properly**
8. **Forgetting to handle nil cases**
9. **Not testing concurrent scenarios**
10. **Improper use of processes**

### Performance Optimization

```elixir
# Use Task for concurrent operations
def fetch_user_data(user_ids) do
  user_ids
  |> Task.async_stream(&fetch_user/1, max_concurrency: 10)
  |> Enum.map(fn {:ok, user} -> user end)
end

# Use Ecto.Multi for transactions
def transfer_funds(from_account, to_account, amount) do
  Multi.new()
  |> Multi.run(:validate, fn _repo, _changes ->
    validate_sufficient_funds(from_account, amount)
  end)
  |> Multi.update(:debit, debit_changeset(from_account, amount))
  |> Multi.update(:credit, credit_changeset(to_account, amount))
  |> Multi.insert(:transaction, transaction_changeset(from_account, to_account, amount))
  |> Repo.transaction()
end

# Use streaming for large datasets
def export_users do
  User
  |> Ash.Query.sort(inserted_at: :asc)
  |> MyApp.Accounts.stream!()
  |> Stream.map(&format_user/1)
  |> CSV.encode()
  |> Enum.into(File.stream!("users.csv"))
end
```

### Useful Libraries

- **ash**: Resource framework
- **ash_postgres**: PostgreSQL data layer
- **ash_graphql**: GraphQL API
- **ash_json_api**: JSON:API
- **phoenix**: Web framework
- **phoenix_live_view**: LiveView
- **ecto**: Database wrapper
- **oban**: Job processing
- **broadway**: Data processing pipelines
- **telemetry**: Instrumentation
- **ex_machina**: Test factories
- **credo**: Code analysis