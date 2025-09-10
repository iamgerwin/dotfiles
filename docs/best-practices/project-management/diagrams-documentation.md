# Diagrams and Documentation Best Practices

## Overview
Documentation diagrams are essential for communicating system architecture, data flows, and project structures. This guide covers ERD, UML, Mermaid, and other diagramming techniques.

## Documentation Tools
- [Mermaid Documentation](https://mermaid.js.org)
- [PlantUML Documentation](https://plantuml.com)
- [Draw.io](https://app.diagrams.net)
- [Lucidchart](https://www.lucidchart.com)
- [dbdiagram.io](https://dbdiagram.io)

## Mermaid Diagrams

### Flowchart

```mermaid
flowchart TD
    Start([User visits website]) --> Auth{Authenticated?}
    Auth -->|No| Login[Show login page]
    Auth -->|Yes| Dashboard[Show dashboard]
    
    Login --> Credentials[Enter credentials]
    Credentials --> Validate{Valid?}
    Validate -->|No| Error[Show error]
    Validate -->|Yes| Dashboard
    
    Error --> Login
    Dashboard --> Actions[User actions]
    Actions --> Logout[Logout]
    Logout --> Start
    
    style Start fill:#e1f5e1
    style Dashboard fill:#e3f2fd
    style Error fill:#ffebee
```

### Sequence Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant A as API Gateway
    participant S as Auth Service
    participant D as Database
    participant Cache as Redis Cache
    
    C->>A: POST /login {email, password}
    A->>S: Validate credentials
    S->>D: Query user
    D-->>S: User data
    
    alt Valid credentials
        S->>S: Generate JWT token
        S->>Cache: Store session
        Cache-->>S: Confirmation
        S-->>A: {token, user}
        A-->>C: 200 OK {token, user}
    else Invalid credentials
        S-->>A: Authentication failed
        A-->>C: 401 Unauthorized
    end
    
    Note over C,Cache: Subsequent requests include JWT
    
    C->>A: GET /profile (with JWT)
    A->>S: Validate token
    S->>Cache: Check session
    Cache-->>S: Session valid
    S-->>A: Token valid
    A->>D: Get profile data
    D-->>A: Profile data
    A-->>C: 200 OK {profile}
```

### Class Diagram

```mermaid
classDiagram
    class User {
        -UUID id
        -String email
        -String hashedPassword
        -DateTime createdAt
        -DateTime updatedAt
        +login(email, password)
        +logout()
        +updateProfile(data)
        +changePassword(old, new)
    }
    
    class Post {
        -UUID id
        -String title
        -String content
        -PostStatus status
        -DateTime publishedAt
        +publish()
        +unpublish()
        +update(data)
        +delete()
    }
    
    class Comment {
        -UUID id
        -String content
        -DateTime createdAt
        +edit(content)
        +delete()
        +approve()
        +reject()
    }
    
    class Category {
        -UUID id
        -String name
        -String slug
        +rename(name)
        +updateSlug()
    }
    
    class Tag {
        -UUID id
        -String name
        +rename(name)
    }
    
    User "1" --> "*" Post : creates
    User "1" --> "*" Comment : writes
    Post "1" --> "*" Comment : has
    Post "*" --> "1" Category : belongs to
    Post "*" --> "*" Tag : has
    User "*" --> "*" User : follows
    
    class PostStatus {
        <<enumeration>>
        DRAFT
        PUBLISHED
        ARCHIVED
        DELETED
    }
    
    Post --> PostStatus : uses
```

### State Diagram

```mermaid
stateDiagram-v2
    [*] --> Draft: Create post
    
    Draft --> UnderReview: Submit for review
    UnderReview --> Draft: Request changes
    UnderReview --> Approved: Approve
    
    Approved --> Scheduled: Schedule publication
    Approved --> Published: Publish immediately
    Scheduled --> Published: Publish date reached
    
    Published --> Updated: Edit post
    Updated --> Published: Save changes
    
    Published --> Archived: Archive
    Archived --> Published: Restore
    
    Draft --> Deleted: Delete
    Published --> Deleted: Delete
    Archived --> Deleted: Delete
    
    Deleted --> [*]
    
    note right of UnderReview
        Editor reviews content
        Checks for quality
        Verifies guidelines
    end note
    
    note right of Scheduled
        Cron job publishes
        at scheduled time
    end note
```

### Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    USERS ||--o{ POSTS : creates
    USERS ||--o{ COMMENTS : writes
    USERS ||--o{ LIKES : gives
    USERS }o--o{ USERS : follows
    
    POSTS ||--o{ COMMENTS : has
    POSTS ||--o{ LIKES : receives
    POSTS }o--|| CATEGORIES : "belongs to"
    POSTS }o--o{ TAGS : has
    
    USERS {
        uuid id PK
        string email UK
        string username UK
        string password_hash
        string first_name
        string last_name
        string avatar_url
        boolean is_verified
        datetime email_verified_at
        datetime created_at
        datetime updated_at
    }
    
    POSTS {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        string title
        string slug UK
        text content
        text excerpt
        string featured_image
        enum status
        integer view_count
        datetime published_at
        datetime created_at
        datetime updated_at
        datetime deleted_at
    }
    
    COMMENTS {
        uuid id PK
        uuid post_id FK
        uuid user_id FK
        uuid parent_id FK
        text content
        boolean is_approved
        datetime created_at
        datetime updated_at
    }
    
    CATEGORIES {
        uuid id PK
        string name
        string slug UK
        text description
        integer sort_order
        datetime created_at
        datetime updated_at
    }
    
    TAGS {
        uuid id PK
        string name UK
        string slug UK
        datetime created_at
    }
    
    POST_TAGS {
        uuid post_id FK
        uuid tag_id FK
        datetime attached_at
    }
    
    LIKES {
        uuid user_id FK
        uuid post_id FK
        datetime created_at
    }
    
    FOLLOWS {
        uuid follower_id FK
        uuid following_id FK
        datetime created_at
    }
```

### Gantt Chart

```mermaid
gantt
    title Project Development Timeline
    dateFormat YYYY-MM-DD
    
    section Planning
    Requirements Analysis       :done,    plan1, 2024-01-01, 14d
    System Design              :done,    plan2, after plan1, 10d
    Database Design            :done,    plan3, after plan1, 7d
    
    section Backend Development
    API Structure              :active,  back1, after plan2, 7d
    Authentication             :         back2, after back1, 5d
    Core Features              :         back3, after back2, 14d
    Payment Integration        :         back4, after back3, 7d
    
    section Frontend Development
    UI/UX Design               :active,  front1, after plan2, 10d
    Component Development      :         front2, after front1, 14d
    Integration                :         front3, after front2, 7d
    
    section Testing
    Unit Testing               :         test1, after back3, 5d
    Integration Testing        :         test2, after front3, 5d
    UAT                       :         test3, after test2, 7d
    
    section Deployment
    Staging Deployment         :         deploy1, after test2, 2d
    Production Deployment      :         deploy2, after test3, 1d
    
    section Milestones
    Alpha Release              :milestone, after back3
    Beta Release               :milestone, after test2
    Production Launch          :milestone, after deploy2
```

### Pie Chart

```mermaid
pie title Project Time Allocation
    "Backend Development" : 35
    "Frontend Development" : 30
    "Testing" : 15
    "Documentation" : 10
    "DevOps" : 5
    "Project Management" : 5
```

### Git Graph

```mermaid
gitGraph
    commit id: "Initial commit"
    commit id: "Setup project structure"
    
    branch develop
    checkout develop
    commit id: "Add authentication"
    commit id: "Add user model"
    
    branch feature/posts
    checkout feature/posts
    commit id: "Create post model"
    commit id: "Add post CRUD"
    commit id: "Add post validation"
    
    checkout develop
    merge feature/posts
    
    branch feature/comments
    checkout feature/comments
    commit id: "Add comment model"
    commit id: "Add nested comments"
    
    checkout develop
    merge feature/comments
    
    checkout main
    merge develop tag: "v1.0.0"
    
    branch hotfix/security
    checkout hotfix/security
    commit id: "Fix XSS vulnerability"
    
    checkout main
    merge hotfix/security tag: "v1.0.1"
    
    checkout develop
    merge hotfix/security
```

### Journey Map

```mermaid
journey
    title User Shopping Journey
    
    section Discovery
      Visit Homepage: 5: User
      Browse Categories: 4: User
      Search Products: 5: User
      View Product Details: 5: User
    
    section Consideration
      Read Reviews: 4: User
      Compare Products: 3: User
      Add to Wishlist: 4: User
      Check Specifications: 4: User
    
    section Purchase
      Add to Cart: 5: User
      Apply Coupon: 5: User
      Checkout: 3: User
      Payment: 2: User
      Order Confirmation: 5: User
    
    section Post-Purchase
      Track Order: 4: User
      Receive Product: 5: User
      Write Review: 3: User
      Contact Support: 2: User
```

## PlantUML Diagrams

### Component Diagram

```plantuml
@startuml
!define RECTANGLE class

package "Frontend" {
    [React App] as app
    [Redux Store] as store
    [API Client] as client
}

package "Backend" {
    [API Gateway] as gateway
    [Auth Service] as auth
    [User Service] as user
    [Post Service] as post
    [Notification Service] as notif
}

package "Data Layer" {
    database "PostgreSQL" as postgres
    database "Redis" as redis
    database "ElasticSearch" as elastic
}

package "External Services" {
    [Stripe API] as stripe
    [SendGrid] as sendgrid
    [AWS S3] as s3
}

app --> store : manages state
store --> client : dispatches actions
client --> gateway : HTTP/WebSocket

gateway --> auth : authenticate
gateway --> user : user operations
gateway --> post : content management
gateway --> notif : notifications

auth --> redis : sessions
user --> postgres : user data
post --> postgres : content data
post --> elastic : search index
notif --> sendgrid : emails

post --> s3 : media storage
user --> stripe : payments

@enduml
```

### Use Case Diagram

```plantuml
@startuml
left to right direction

actor "Guest" as guest
actor "Registered User" as user
actor "Author" as author
actor "Editor" as editor
actor "Admin" as admin

rectangle "Blog System" {
    usecase "View Posts" as UC1
    usecase "Search Posts" as UC2
    usecase "Register" as UC3
    usecase "Login" as UC4
    usecase "Comment" as UC5
    usecase "Like Post" as UC6
    usecase "Create Post" as UC7
    usecase "Edit Own Post" as UC8
    usecase "Delete Own Post" as UC9
    usecase "Review Posts" as UC10
    usecase "Publish Post" as UC11
    usecase "Manage Users" as UC12
    usecase "Manage Categories" as UC13
    usecase "View Analytics" as UC14
}

guest --> UC1
guest --> UC2
guest --> UC3
guest --> UC4

user --> UC1
user --> UC2
user --> UC5
user --> UC6

author --> UC7
author --> UC8
author --> UC9
author --|> user

editor --> UC10
editor --> UC11
editor --> UC14
editor --|> author

admin --> UC12
admin --> UC13
admin --|> editor

@enduml
```

### Activity Diagram

```plantuml
@startuml
start

:User opens application;

if (Logged in?) then (no)
    :Display login screen;
    :Enter credentials;
    
    if (Valid credentials?) then (yes)
        :Generate JWT token;
        :Store in localStorage;
    else (no)
        :Show error message;
        stop
    endif
else (yes)
    :Validate existing token;
    
    if (Token valid?) then (no)
        :Clear localStorage;
        :Redirect to login;
        stop
    endif
endif

:Load user dashboard;
:Fetch user data;

fork
    :Load recent posts;
fork again
    :Load notifications;
fork again
    :Load statistics;
end fork

:Display dashboard;

repeat
    :Wait for user action;
    
    switch (Action type?)
    case (Create post)
        :Open editor;
        :Write content;
        :Save draft;
        
        if (Publish?) then (yes)
            :Validate content;
            :Publish post;
            :Send notifications;
        endif
        
    case (Edit profile)
        :Open profile form;
        :Update information;
        :Save changes;
        
    case (Logout)
        :Clear session;
        :Redirect to home;
        stop
        
    endswitch
    
repeat while (Continue?) is (yes)

stop

@enduml
```

## Database Diagrams

### SQL Schema Definition

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url VARCHAR(500),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_created_at (created_at)
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_id UUID,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    featured_image VARCHAR(500),
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    view_count INTEGER DEFAULT 0,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_slug (slug),
    INDEX idx_status_published (status, published_at),
    FULLTEXT INDEX idx_search (title, content)
);

-- Comments table with self-referencing for nested comments
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL,
    user_id UUID NOT NULL,
    parent_id UUID,
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
    
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_parent_id (parent_id)
);

-- Many-to-many relationship tables
CREATE TABLE post_tags (
    post_id UUID NOT NULL,
    tag_id UUID NOT NULL,
    attached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE TABLE user_follows (
    follower_id UUID NOT NULL,
    following_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    
    CHECK (follower_id != following_id)
);
```

### dbdiagram.io Syntax

```dbml
Project BlogDatabase {
  database_type: 'PostgreSQL'
  Note: 'Blog application database schema'
}

Table users {
  id uuid [pk, default: `gen_random_uuid()`]
  email varchar(255) [unique, not null]
  username varchar(50) [unique, not null]
  password_hash varchar(255) [not null]
  first_name varchar(100)
  last_name varchar(100)
  avatar_url varchar(500)
  bio text
  is_verified boolean [default: false]
  email_verified_at timestamp
  created_at timestamp [default: `now()`]
  updated_at timestamp [default: `now()`]
  
  Indexes {
    email [unique]
    username [unique]
    created_at
  }
}

Table posts {
  id uuid [pk, default: `gen_random_uuid()`]
  user_id uuid [not null, ref: > users.id]
  category_id uuid [ref: > categories.id]
  title varchar(255) [not null]
  slug varchar(255) [unique, not null]
  content text [not null]
  excerpt text
  featured_image varchar(500)
  status post_status [default: 'draft']
  view_count integer [default: 0]
  published_at timestamp
  created_at timestamp [default: `now()`]
  updated_at timestamp [default: `now()`]
  deleted_at timestamp
  
  Indexes {
    user_id
    category_id
    slug [unique]
    (status, published_at)
    (title, content) [type: fulltext]
  }
}

Table comments {
  id uuid [pk, default: `gen_random_uuid()`]
  post_id uuid [not null, ref: > posts.id]
  user_id uuid [not null, ref: > users.id]
  parent_id uuid [ref: > comments.id]
  content text [not null]
  is_approved boolean [default: false]
  created_at timestamp [default: `now()`]
  updated_at timestamp [default: `now()`]
  
  Indexes {
    post_id
    user_id
    parent_id
  }
}

Table categories {
  id uuid [pk, default: `gen_random_uuid()`]
  name varchar(100) [not null]
  slug varchar(100) [unique, not null]
  description text
  parent_id uuid [ref: > categories.id]
  sort_order integer [default: 0]
  created_at timestamp [default: `now()`]
  updated_at timestamp [default: `now()`]
  
  Indexes {
    slug [unique]
    parent_id
  }
}

Table tags {
  id uuid [pk, default: `gen_random_uuid()`]
  name varchar(50) [unique, not null]
  slug varchar(50) [unique, not null]
  created_at timestamp [default: `now()`]
  
  Indexes {
    name [unique]
    slug [unique]
  }
}

Table post_tags {
  post_id uuid [ref: > posts.id]
  tag_id uuid [ref: > tags.id]
  attached_at timestamp [default: `now()`]
  
  Indexes {
    (post_id, tag_id) [pk]
  }
}

Table likes {
  user_id uuid [ref: > users.id]
  post_id uuid [ref: > posts.id]
  created_at timestamp [default: `now()`]
  
  Indexes {
    (user_id, post_id) [pk]
  }
}

Table user_follows {
  follower_id uuid [ref: > users.id]
  following_id uuid [ref: > users.id]
  created_at timestamp [default: `now()`]
  
  Indexes {
    (follower_id, following_id) [pk]
  }
  
  Note: 'Self-referencing many-to-many relationship'
}

Enum post_status {
  draft
  published
  archived
}
```

## Timing Diagrams

### System Timing Diagram

```mermaid
%%{init: {'theme':'dark'}}%%
timeline
    title System Development Timeline
    
    section Phase 1 - Foundation
        Jan 2024    : Project Kickoff
                    : Requirements Gathering
        Feb 2024    : System Architecture Design
                    : Technology Stack Selection
        Mar 2024    : Database Design
                    : API Specification
    
    section Phase 2 - Core Development
        Apr 2024    : Authentication System
                    : User Management
        May 2024    : Content Management
                    : Media Handling
        Jun 2024    : Search Implementation
                    : Notification System
    
    section Phase 3 - Features
        Jul 2024    : Payment Integration
                    : Analytics Dashboard
        Aug 2024    : Mobile App Development
                    : API Optimization
    
    section Phase 4 - Testing & Deployment
        Sep 2024    : Integration Testing
                    : Performance Testing
        Oct 2024    : Security Audit
                    : Beta Release
        Nov 2024    : User Acceptance Testing
                    : Bug Fixes
        Dec 2024    : Production Deployment
                    : Documentation Complete
```

### Request/Response Timing

```
Client          API Gateway      Auth Service     Database        Cache
  |                 |                 |              |              |
  |--Request------->|                 |              |              |
  |                 |--Check Token--->|              |              |
  |                 |                 |--Validate--->|              |
  |                 |                 |<---User------|              |
  |                 |                 |--Store-------|------------->|
  |                 |<----Valid-------|              |              |
  |                 |--Get Data------|-------------->|              |
  |                 |                 |              |              |
  |                 |<----------------|--Data--------|              |
  |<---Response-----|                 |              |              |
  |                 |                 |              |              |

Time: 0ms         10ms              20ms           30ms          40ms
```

## Architecture Diagrams

### C4 Model - Context Diagram

```mermaid
graph TB
    User[User<br/>Web/Mobile]
    Admin[Administrator<br/>Dashboard]
    
    System[Blog System<br/>Main Application]
    
    Email[Email Service<br/>SendGrid]
    Payment[Payment Gateway<br/>Stripe]
    Storage[File Storage<br/>AWS S3]
    Search[Search Engine<br/>ElasticSearch]
    Analytics[Analytics<br/>Google Analytics]
    
    User -->|Uses| System
    Admin -->|Manages| System
    
    System -->|Sends emails| Email
    System -->|Processes payments| Payment
    System -->|Stores files| Storage
    System -->|Indexes content| Search
    System -->|Tracks usage| Analytics
    
    style System fill:#1168bd,color:#fff
    style User fill:#08427b,color:#fff
    style Admin fill:#08427b,color:#fff
```

### Microservices Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Web[Web App]
        Mobile[Mobile App]
        Admin[Admin Panel]
    end
    
    subgraph "API Gateway"
        Gateway[Kong/Nginx]
        Auth[Auth Middleware]
    end
    
    subgraph "Service Layer"
        UserSvc[User Service]
        PostSvc[Post Service]
        CommentSvc[Comment Service]
        NotifSvc[Notification Service]
        SearchSvc[Search Service]
        MediaSvc[Media Service]
    end
    
    subgraph "Data Layer"
        UserDB[(User DB)]
        PostDB[(Post DB)]
        CommentDB[(Comment DB)]
        MediaStore[(S3)]
        SearchIdx[(ElasticSearch)]
        Cache[(Redis)]
    end
    
    subgraph "Message Queue"
        Queue[RabbitMQ/Kafka]
    end
    
    Web --> Gateway
    Mobile --> Gateway
    Admin --> Gateway
    
    Gateway --> Auth
    Auth --> UserSvc
    Auth --> PostSvc
    Auth --> CommentSvc
    Auth --> NotifSvc
    Auth --> SearchSvc
    Auth --> MediaSvc
    
    UserSvc --> UserDB
    UserSvc --> Cache
    
    PostSvc --> PostDB
    PostSvc --> Queue
    
    CommentSvc --> CommentDB
    CommentSvc --> Queue
    
    NotifSvc --> Queue
    
    SearchSvc --> SearchIdx
    SearchSvc --> Queue
    
    MediaSvc --> MediaStore
    
    Queue --> NotifSvc
    Queue --> SearchSvc
```

## Network Diagrams

### Infrastructure Diagram

```mermaid
graph TB
    subgraph "Internet"
        Users[Users]
        CDN[CloudFlare CDN]
    end
    
    subgraph "AWS Region"
        subgraph "Public Subnet"
            ALB[Application Load Balancer]
            NAT[NAT Gateway]
        end
        
        subgraph "Private Subnet A"
            EC2A[EC2 Instances]
            ECS[ECS Cluster]
        end
        
        subgraph "Private Subnet B"
            RDS[(RDS Multi-AZ)]
            ElastiCache[(ElastiCache)]
        end
        
        subgraph "Storage"
            S3[S3 Buckets]
            EFS[EFS]
        end
    end
    
    Users --> CDN
    CDN --> ALB
    ALB --> EC2A
    ALB --> ECS
    EC2A --> NAT
    ECS --> NAT
    EC2A --> RDS
    EC2A --> ElastiCache
    ECS --> RDS
    ECS --> ElastiCache
    EC2A --> S3
    EC2A --> EFS
    NAT --> Internet
```

## Best Practices

### Diagram Guidelines

1. **Keep it Simple**: Start with high-level overviews
2. **Use Consistent Notation**: Stick to standard symbols
3. **Add Legends**: Explain symbols and colors
4. **Version Control**: Store diagrams as code
5. **Update Regularly**: Keep diagrams current
6. **Use Appropriate Tools**: Choose the right diagram type
7. **Consider Audience**: Technical vs non-technical
8. **Add Context**: Include notes and descriptions
9. **Maintain Hierarchy**: Show relationships clearly
10. **Review and Iterate**: Get feedback and improve

### Tool Selection

| Diagram Type | Best Tools | Use Case |
|-------------|------------|----------|
| ERD | dbdiagram.io, MySQL Workbench | Database design |
| UML | PlantUML, StarUML | Object-oriented design |
| Flowchart | Mermaid, Draw.io | Process flows |
| Sequence | Mermaid, PlantUML | API interactions |
| Architecture | C4 Model, Draw.io | System overview |
| Network | Draw.io, Visio | Infrastructure |
| Gantt | Mermaid, MS Project | Project timeline |
| State | Mermaid, PlantUML | State machines |

### Documentation Integration

```markdown
# System Documentation

## Architecture Overview
```mermaid
graph TB
    A[Client] --> B[Server]
    B --> C[Database]
```

## API Flow
See [Sequence Diagram](#sequence-diagram) for detailed flow.

## Database Schema
Refer to [ERD](#entity-relationship-diagram) for relationships.
```

## Collaboration Tips

1. **Use Version Control**: Store diagram source files
2. **Automate Generation**: CI/CD pipeline for diagrams
3. **Embed in Documentation**: Keep diagrams with docs
4. **Share Links**: Use online tools for collaboration
5. **Export Formats**: Provide SVG/PNG for presentations
6. **Comment Code**: Reference diagrams in code
7. **Wiki Integration**: Link diagrams in project wiki
8. **Regular Reviews**: Schedule diagram updates
9. **Template Library**: Maintain reusable templates
10. **Training**: Ensure team knows tools