# Ruby on Rails Best Practices

## Official Documentation
- **Ruby on Rails Guides**: https://guides.rubyonrails.org
- **Rails API Documentation**: https://api.rubyonrails.org
- **Ruby Documentation**: https://ruby-doc.org
- **Rails Security Guide**: https://guides.rubyonrails.org/security.html

## Project Structure

```
rails-app/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb
│   │   │       └── users_controller.rb
│   │   └── users_controller.rb
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── concerns/
│   │   │   ├── authenticatable.rb
│   │   │   └── timestampable.rb
│   │   ├── user.rb
│   │   └── product.rb
│   ├── services/
│   │   ├── application_service.rb
│   │   ├── user_creation_service.rb
│   │   └── payment_processing_service.rb
│   ├── serializers/
│   │   ├── application_serializer.rb
│   │   ├── user_serializer.rb
│   │   └── product_serializer.rb
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── email_notification_job.rb
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   └── user_mailer.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── users/
│   │       ├── index.html.erb
│   │       └── show.html.erb
│   └── validators/
│       ├── email_validator.rb
│       └── phone_validator.rb
├── config/
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   └── environments/
│       ├── development.rb
│       ├── test.rb
│       └── production.rb
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
├── lib/
│   └── tasks/
├── spec/ or test/
│   ├── models/
│   ├── controllers/
│   ├── requests/
│   └── services/
├── Gemfile
└── config.ru
```

## Core Best Practices

### 1. Model Best Practices

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Authenticatable
  include Timestampable

  # Constants
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.freeze
  ROLES = %w[admin user moderator].freeze

  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy
  belongs_to :organization, optional: true

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: VALID_EMAIL_REGEX }
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :role, inclusion: { in: ROLES }
  validates :age, numericality: { greater_than: 0, less_than: 150 }, allow_nil: true

  # Callbacks
  before_save :normalize_email
  after_create :send_welcome_email
  after_destroy :cleanup_associated_data

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_posts, -> { joins(:posts).distinct }

  # Class methods
  def self.find_by_email_case_insensitive(email)
    find_by('LOWER(email) = LOWER(?)', email)
  end

  def self.search(query)
    where('name ILIKE ? OR email ILIKE ?', "%#{query}%", "%#{query}%")
  end

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin?
    role == 'admin'
  end

  def can_edit?(resource)
    admin? || resource.user == self
  end

  def posts_count
    Rails.cache.fetch("user_#{id}_posts_count", expires_in: 1.hour) do
      posts.count
    end
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end

  def cleanup_associated_data
    # Clean up any associated data that doesn't use dependent: :destroy
    UserCleanupJob.perform_later(id)
  end
end

# app/models/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    has_secure_password validations: false
    validates :password, length: { minimum: 8 }, confirmation: true, allow_blank: true
    validate :password_complexity

    before_save :ensure_authentication_token
  end

  class_methods do
    def authenticate_with_token(token)
      find_by(authentication_token: token)
    end
  end

  def generate_password_reset_token
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
  end

  def password_reset_expired?
    password_reset_sent_at < 2.hours.ago
  end

  private

  def ensure_authentication_token
    self.authentication_token ||= generate_token
  end

  def generate_token
    loop do
      token = SecureRandom.base64(32)
      break token unless self.class.exists?(authentication_token: token)
    end
  end

  def password_complexity
    return unless password.present?

    unless password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit'
    end
  end
end
```

### 2. Controller Best Practices

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  include AuthenticationConcern
  include ErrorHandling
  include RequestLogging

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email])
  end
end

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]

  # GET /users
  def index
    @users = User.includes(:posts)
                 .active
                 .page(params[:page])
                 .per(20)

    @users = @users.search(params[:search]) if params[:search].present?
    @users = @users.by_role(params[:role]) if params[:role].present?

    respond_to do |format|
      format.html
      format.json { render json: UserSerializer.new(@users) }
    end
  end

  # GET /users/1
  def show
    @posts = @user.posts.includes(:comments).recent.limit(10)

    respond_to do |format|
      format.html
      format.json { render json: UserSerializer.new(@user, include: [:posts]) }
    end
  end

  # POST /users
  def create
    @user = UserCreationService.call(user_params)

    if @user.persisted?
      redirect_to @user, notice: 'User was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  rescue UserCreationService::Error => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User was successfully deleted.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: 'User not found.'
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :active)
  end

  def authorize_user!
    redirect_to users_path, alert: 'Access denied.' unless current_user.can_edit?(@user)
  end
end

# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include ErrorHandling

  before_action :authenticate_api_user!

  private

  def authenticate_api_user!
    authenticate_or_request_with_http_token do |token, options|
      @current_user = User.authenticate_with_token(token)
    end
  end

  def current_user
    @current_user
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_success(data = nil, message = nil, status = :ok)
    response = { success: true }
    response[:data] = data if data
    response[:message] = message if message
    render json: response, status: status
  end
end

# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    users = User.active
                .includes(:posts)
                .page(params[:page])
                .per(params[:per_page] || 20)

    render_success(
      UserSerializer.new(users, include: [:posts]).serialized_json,
      pagination_meta(users)
    )
  end

  def show
    render_success(UserSerializer.new(@user).serialized_json)
  end

  def create
    user = UserCreationService.call(user_params)
    
    if user.persisted?
      render_success(
        UserSerializer.new(user).serialized_json,
        'User created successfully',
        :created
      )
    else
      render_error(user.errors.full_messages.join(', '))
    end
  end

  def update
    if @user.update(user_params)
      render_success(
        UserSerializer.new(@user).serialized_json,
        'User updated successfully'
      )
    else
      render_error(@user.errors.full_messages.join(', '))
    end
  end

  def destroy
    @user.destroy
    render_success(nil, 'User deleted successfully', :no_content)
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('User not found', :not_found)
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :active)
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
```

### 3. Service Objects Pattern

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  class Error < StandardError; end
end

# app/services/user_creation_service.rb
class UserCreationService < ApplicationService
  attr_reader :user_params, :user

  def initialize(user_params)
    @user_params = user_params
  end

  def call
    ActiveRecord::Base.transaction do
      create_user
      create_profile
      send_notifications
    end

    user
  rescue ActiveRecord::RecordInvalid => e
    raise Error, "User creation failed: #{e.message}"
  rescue => e
    Rails.logger.error "UserCreationService failed: #{e.message}"
    raise Error, "An unexpected error occurred"
  end

  private

  def create_user
    @user = User.create!(user_params)
  end

  def create_profile
    @user.create_profile!(
      bio: "Welcome to our platform!",
      preferences: default_preferences
    )
  end

  def send_notifications
    UserMailer.welcome(@user).deliver_later
    AdminNotificationJob.perform_later(@user.id, 'new_user_registered')
  end

  def default_preferences
    {
      email_notifications: true,
      marketing_emails: false,
      theme: 'light'
    }
  end
end

# app/services/payment_processing_service.rb
class PaymentProcessingService < ApplicationService
  attr_reader :order, :payment_method, :amount

  def initialize(order, payment_method, amount)
    @order = order
    @payment_method = payment_method
    @amount = amount
  end

  def call
    validate_payment
    process_payment
    update_order
    send_confirmation
  rescue Stripe::CardError => e
    handle_card_error(e)
  rescue Stripe::StripeError => e
    handle_stripe_error(e)
  end

  private

  def validate_payment
    raise Error, "Invalid amount" if amount <= 0
    raise Error, "Order already paid" if order.paid?
  end

  def process_payment
    @payment_intent = Stripe::PaymentIntent.create(
      amount: (amount * 100).to_i, # Convert to cents
      currency: 'usd',
      payment_method: payment_method,
      confirmation_method: 'manual',
      confirm: true
    )
  end

  def update_order
    order.update!(
      status: 'paid',
      payment_intent_id: @payment_intent.id,
      paid_at: Time.current
    )
  end

  def send_confirmation
    OrderMailer.payment_confirmation(order).deliver_later
  end

  def handle_card_error(error)
    order.update(status: 'payment_failed', error_message: error.message)
    raise Error, error.user_message
  end

  def handle_stripe_error(error)
    Rails.logger.error "Stripe error: #{error.message}"
    raise Error, "Payment processing failed. Please try again."
  end
end
```

### 4. Background Jobs

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  around_perform do |job, block|
    Rails.logger.info "Starting job: #{job.class.name} with args: #{job.arguments}"
    start_time = Time.current
    
    block.call
    
    duration = Time.current - start_time
    Rails.logger.info "Completed job: #{job.class.name} in #{duration}s"
  end

  private

  def log_error(error)
    Rails.logger.error "Job failed: #{self.class.name}"
    Rails.logger.error "Error: #{error.message}"
    Rails.logger.error "Backtrace: #{error.backtrace.join("\n")}"
  end
end

# app/jobs/email_notification_job.rb
class EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, notification_type, data = {})
    user = User.find(user_id)
    
    case notification_type
    when 'welcome'
      UserMailer.welcome(user).deliver_now
    when 'password_reset'
      UserMailer.password_reset(user, data[:token]).deliver_now
    when 'order_confirmation'
      OrderMailer.confirmation(user, data[:order_id]).deliver_now
    else
      raise ArgumentError, "Unknown notification type: #{notification_type}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "User not found for email notification: #{user_id}"
  rescue => e
    log_error(e)
    raise
  end
end

# app/jobs/data_export_job.rb
class DataExportJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id, export_type)
    user = User.find(user_id)
    
    case export_type
    when 'users'
      export_users(user)
    when 'orders'
      export_orders(user)
    else
      raise ArgumentError, "Unknown export type: #{export_type}"
    end
  end

  private

  def export_users(requesting_user)
    return unless requesting_user.admin?

    csv_data = generate_users_csv
    upload_to_s3(csv_data, "users_export_#{Date.current}.csv")
    
    UserMailer.export_ready(requesting_user, 'users').deliver_now
  end

  def export_orders(requesting_user)
    orders = requesting_user.admin? ? Order.all : requesting_user.orders
    csv_data = generate_orders_csv(orders)
    
    upload_to_s3(csv_data, "orders_export_#{requesting_user.id}_#{Date.current}.csv")
    UserMailer.export_ready(requesting_user, 'orders').deliver_now
  end

  def generate_users_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Email', 'Created At', 'Active']
      
      User.find_each do |user|
        csv << [user.id, user.name, user.email, user.created_at, user.active?]
      end
    end
  end

  def upload_to_s3(data, filename)
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(Rails.application.credentials.aws[:s3_bucket])
    
    bucket.object("exports/#{filename}").put(body: data)
  end
end
```

### 5. Database Migrations

```ruby
# db/migrate/20240101000001_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: 'user', null: false
      t.boolean :active, default: true, null: false
      t.string :authentication_token
      t.string :password_reset_token
      t.datetime :password_reset_sent_at
      t.datetime :last_login_at
      t.inet :last_login_ip
      t.json :preferences, default: {}

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :authentication_token, unique: true
    add_index :users, :password_reset_token, unique: true
    add_index :users, :role
    add_index :users, :active
    add_index :users, :created_at
  end
end

# db/migrate/20240101000002_add_full_text_search_to_users.rb
class AddFullTextSearchToUsers < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TABLE users ADD COLUMN searchable_text tsvector;
      
      UPDATE users SET searchable_text = 
        to_tsvector('english', coalesce(name, '') || ' ' || coalesce(email, ''));
      
      CREATE INDEX idx_users_searchable_text ON users USING gin(searchable_text);
      
      CREATE TRIGGER users_searchable_text_update 
        BEFORE INSERT OR UPDATE ON users 
        FOR EACH ROW EXECUTE FUNCTION
        tsvector_update_trigger(searchable_text, 'pg_catalog.english', name, email);
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS users_searchable_text_update ON users;
      DROP INDEX IF EXISTS idx_users_searchable_text;
      ALTER TABLE users DROP COLUMN IF EXISTS searchable_text;
    SQL
  end
end
```

### 6. Testing Best Practices

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_one(:profile).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:active_user) { create(:user, active: true) }
    let!(:inactive_user) { create(:user, active: false) }
    let!(:admin_user) { create(:user, role: 'admin') }

    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end

    describe '.by_role' do
      it 'returns users with specified role' do
        expect(User.by_role('admin')).to include(admin_user)
        expect(User.by_role('admin')).not_to include(active_user)
      end
    end
  end

  describe 'class methods' do
    describe '.find_by_email_case_insensitive' do
      let!(:user) { create(:user, email: 'Test@Example.com') }

      it 'finds user regardless of email case' do
        expect(User.find_by_email_case_insensitive('test@example.com')).to eq(user)
        expect(User.find_by_email_case_insensitive('TEST@EXAMPLE.COM')).to eq(user)
      end
    end

    describe '.search' do
      let!(:john) { create(:user, name: 'John Doe', email: 'john@example.com') }
      let!(:jane) { create(:user, name: 'Jane Smith', email: 'jane@example.com') }

      it 'searches by name' do
        expect(User.search('John')).to include(john)
        expect(User.search('John')).not_to include(jane)
      end

      it 'searches by email' do
        expect(User.search('jane@example.com')).to include(jane)
        expect(User.search('jane@example.com')).not_to include(john)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe', role: 'admin') }

    describe '#full_name' do
      it 'returns the full name' do
        expect(user.full_name).to eq('John Doe')
      end
    end

    describe '#admin?' do
      it 'returns true for admin users' do
        expect(user.admin?).to be true
      end

      it 'returns false for non-admin users' do
        user.role = 'user'
        expect(user.admin?).to be false
      end
    end
  end

  describe 'callbacks' do
    let(:user) { build(:user, email: 'Test@Example.COM') }

    it 'normalizes email before save' do
      user.save
      expect(user.email).to eq('test@example.com')
    end

    it 'sends welcome email after create' do
      expect { user.save }.to have_enqueued_job(EmailNotificationJob)
        .with(user.id, 'welcome')
        .on_queue('default')
    end
  end
end

# spec/services/user_creation_service_spec.rb
require 'rails_helper'

RSpec.describe UserCreationService do
  describe '#call' do
    let(:user_params) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123',
        role: 'user'
      }
    end

    context 'with valid parameters' do
      it 'creates a user' do
        expect { described_class.call(user_params) }.to change(User, :count).by(1)
      end

      it 'creates a profile for the user' do
        user = described_class.call(user_params)
        expect(user.profile).to be_present
      end

      it 'sends welcome email' do
        expect { described_class.call(user_params) }
          .to have_enqueued_job(EmailNotificationJob)
      end

      it 'returns the created user' do
        user = described_class.call(user_params)
        expect(user).to be_a(User)
        expect(user.persisted?).to be true
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { user_params.merge(email: 'invalid-email') }

      it 'raises an error' do
        expect { described_class.call(invalid_params) }
          .to raise_error(UserCreationService::Error)
      end

      it 'does not create a user' do
        expect { described_class.call(invalid_params) rescue nil }
          .not_to change(User, :count)
      end
    end
  end
end

# spec/requests/api/v1/users_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { create(:user) }
  let(:auth_token) { user.authentication_token }
  let(:headers) { { 'Authorization' => "Token token=#{auth_token}" } }

  describe 'GET /api/v1/users' do
    before do
      create_list(:user, 3)
    end

    it 'returns list of users' do
      get '/api/v1/users', headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']).to be_present
    end

    it 'paginates results' do
      get '/api/v1/users?page=1&per_page=2', headers: headers

      body = JSON.parse(response.body)
      expect(body['data'].length).to eq(2)
    end
  end

  describe 'POST /api/v1/users' do
    let(:user_params) do
      {
        user: {
          name: 'New User',
          email: 'newuser@example.com',
          role: 'user'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect { post '/api/v1/users', params: user_params, headers: headers }
          .to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { user: { name: '' } } }

      it 'returns error' do
        post '/api/v1/users', params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end
  end
end
```

### Common Pitfalls to Avoid

1. **N+1 query problems - use includes/joins**
2. **Not using strong parameters**
3. **Fat controllers - move logic to services/models**
4. **Not handling errors properly**
5. **Ignoring database indexes**
6. **Not using database constraints**
7. **Poor secret management**
8. **Not implementing proper logging**
9. **Ignoring performance optimization**
10. **Not writing tests**

### Performance Tips

1. **Use database indexes strategically**
2. **Implement eager loading with includes**
3. **Use counter caches for counts**
4. **Implement caching with Redis**
5. **Use background jobs for heavy tasks**
6. **Optimize database queries**
7. **Use pagination for large datasets**
8. **Implement proper logging**
9. **Monitor performance with APM tools**
10. **Use CDN for static assets**

### Useful Gems

- **puma**: Web server
- **pg**: PostgreSQL adapter
- **redis**: In-memory data store
- **sidekiq**: Background job processing
- **devise**: Authentication
- **cancancan**: Authorization
- **kaminari**: Pagination
- **fast_jsonapi**: JSON serialization
- **rspec-rails**: Testing framework
- **factory_bot_rails**: Test data generation
- **rubocop**: Code style enforcement
- **brakeman**: Security scanning