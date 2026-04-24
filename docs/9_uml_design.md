# 8. UML・設計図

## 8.1 UML図表

### 8.1.1 インスタンス図

```mermaid
classDiagram
    class User {
        -id: int
        -name: string
        -email: string
        -password: string
        -role: UserRole
        -status: UserStatus
        +getId(): int
        +getName(): string
        +getEmail(): string
        +isActive(): bool
        +hasRole(role: UserRole): bool
    }
    
    class Post {
        -id: int
        -title: string
        -slug: string
        -content: string
        -status: PostStatus
        -publishedAt: DateTime
        -userId: int
        +publish(): void
        +unpublish(): void
        +isPublished(): bool
        +getAuthor(): User
    }
    
    class Category {
        -id: int
        -name: string
        -slug: string
        -description: string
        +getPosts(): Collection
    }
    
    class Comment {
        -id: int
        -content: string
        -postId: int
        -userId: int
        -parentId: int
        +getReplies(): Collection
        +getParent(): Comment|null
    }
    
    class UserService {
        -userRepository: UserRepositoryInterface
        -emailService: EmailService
        +createUser(data: array): User
        +updateUser(id: int, data: array): User
        +deleteUser(id: int): bool
        +sendWelcomeEmail(user: User): void
    }
    
    class PostService {
        -postRepository: PostRepositoryInterface
        -categoryRepository: CategoryRepositoryInterface
        +createPost(data: array): Post
        +publishPost(id: int): Post
        +getPublishedPosts(): Collection
    }
    
    %% Relationships
    User ||--o{ Post : "writes"
    User ||--o{ Comment : "writes"
    Post ||--o{ Comment : "has"
    Category ||--o{ Post : "categorizes"
    Comment ||--o{ Comment : "parent-child"
    
    UserService --> User : "manages"
    PostService --> Post : "manages"
    PostService --> Category : "uses"
```

### 8.1.2 シーケンス図

#### ユーザー登録フロー
```mermaid
sequenceDiagram
    participant Client
    participant AuthController
    participant UserService
    participant UserRepository
    participant EmailService
    participant Database
    
    Client->>AuthController: POST /register
    AuthController->>AuthController: validateRequest()
    
    AuthController->>UserService: createUser(userData)
    UserService->>UserRepository: findByEmail(email)
    UserRepository->>Database: SELECT * FROM users WHERE email = ?
    Database-->>UserRepository: null
    UserRepository-->>UserService: null
    
    UserService->>UserService: hashPassword(password)
    UserService->>UserRepository: save(user)
    UserRepository->>Database: INSERT INTO users
    Database-->>UserRepository: user_id
    UserRepository-->>UserService: User object
    
    UserService->>EmailService: sendWelcomeEmail(user)
    EmailService-->>UserService: success
    
    UserService-->>AuthController: User object
    AuthController-->>Client: 201 Created + UserResource
```

#### 投稿公開フロー
```mermaid
sequenceDiagram
    participant Client
    participant PostController
    participant PostService
    participant PostRepository
    participant NotificationService
    participant Database
    
    Client->>PostController: PUT /posts/{id}/publish
    PostController->>PostController: authorize(user, post)
    
    PostController->>PostService: publishPost(postId)
    PostService->>PostRepository: findById(postId)
    PostRepository->>Database: SELECT * FROM posts WHERE id = ?
    Database-->>PostRepository: post data
    PostRepository-->>PostService: Post object
    
    PostService->>PostService: validateForPublishing(post)
    
    alt Post is valid for publishing
        PostService->>PostRepository: updateStatus(postId, 'published')
        PostRepository->>Database: UPDATE posts SET status = 'published'
        Database-->>PostRepository: success
        PostRepository-->>PostService: Post object
        
        PostService->>NotificationService: notifySubscribers(post)
        NotificationService-->>PostService: success
        
        PostService-->>PostController: Post object
        PostController-->>Client: 200 OK + PostResource
    else Post is not valid
        PostService-->>PostController: ValidationException
        PostController-->>Client: 422 Unprocessable Entity
    end
```

### 8.1.3 クラス図

#### ドメインレイヤー
```mermaid
classDiagram
    %% Domain Entities
    class User {
        <<Entity>>
        +UserId id
        +UserName name
        +Email email
        +Password password
        +UserRole role
        +UserStatus status
        +DateTime createdAt
        +changePassword(newPassword: Password): void
        +activate(): void
        +deactivate(): void
        +hasPermission(permission: string): bool
    }
    
    class Post {
        <<Entity>>
        +PostId id
        +PostTitle title
        +PostSlug slug
        +PostContent content
        +PostStatus status
        +DateTime publishedAt
        +UserId authorId
        +CategoryId categoryId
        +publish(): void
        +unpublish(): void
        +updateContent(content: PostContent): void
        +isPublished(): bool
    }
    
    class Category {
        <<Entity>>
        +CategoryId id
        +CategoryName name
        +CategorySlug slug
        +CategoryDescription description
        +changeName(name: CategoryName): void
    }
    
    %% Value Objects
    class UserId {
        <<ValueObject>>
        +int value
        +equals(other: UserId): bool
    }
    
    class Email {
        <<ValueObject>>
        +string value
        +isValid(): bool
        +getDomain(): string
    }
    
    class Password {
        <<ValueObject>>
        +string hashedValue
        +verify(plainPassword: string): bool
        +isStrong(): bool
    }
    
    class PostTitle {
        <<ValueObject>>
        +string value
        +length(): int
        +isEmpty(): bool
    }
    
    %% Domain Services
    class UserDomainService {
        <<DomainService>>
        +isDuplicateEmail(email: Email, userRepository: UserRepositoryInterface): bool
        +generateStrongPassword(): Password
    }
    
    class PostDomainService {
        <<DomainService>>
        +isDuplicateSlug(slug: PostSlug, postRepository: PostRepositoryInterface): bool
        +canPublish(post: Post, user: User): bool
    }
    
    %% Repository Interfaces
    class UserRepositoryInterface {
        <<Interface>>
        +findById(id: UserId): User|null
        +findByEmail(email: Email): User|null
        +save(user: User): void
        +delete(user: User): void
    }
    
    class PostRepositoryInterface {
        <<Interface>>
        +findById(id: PostId): Post|null
        +findBySlug(slug: PostSlug): Post|null
        +findPublishedPosts(limit: int, offset: int): Collection
        +save(post: Post): void
        +delete(post: Post): void
    }
    
    %% Relationships
    User *-- UserId
    User *-- Email
    User *-- Password
    Post *-- PostTitle
    Post --> User : "author"
    Post --> Category : "category"
    
    UserDomainService ..> UserRepositoryInterface
    PostDomainService ..> PostRepositoryInterface
```

#### アプリケーションレイヤー
```mermaid
classDiagram
    %% Use Cases
    class CreateUserUseCase {
        <<UseCase>>
        -userRepository: UserRepositoryInterface
        -emailService: EmailServiceInterface
        -userDomainService: UserDomainService
        +execute(command: CreateUserCommand): CreateUserResponse
    }
    
    class PublishPostUseCase {
        <<UseCase>>
        -postRepository: PostRepositoryInterface
        -userRepository: UserRepositoryInterface
        -postDomainService: PostDomainService
        -eventDispatcher: EventDispatcherInterface
        +execute(command: PublishPostCommand): PublishPostResponse
    }
    
    %% Commands
    class CreateUserCommand {
        <<Command>>
        +string name
        +string email
        +string password
        +string role
    }
    
    class PublishPostCommand {
        <<Command>>
        +int postId
        +int userId
    }
    
    %% Responses
    class CreateUserResponse {
        <<Response>>
        +User user
        +bool emailSent
    }
    
    class PublishPostResponse {
        <<Response>>
        +Post post
        +DateTime publishedAt
    }
    
    %% Events
    class UserCreatedEvent {
        <<DomainEvent>>
        +User user
        +DateTime occurredAt
    }
    
    class PostPublishedEvent {
        <<DomainEvent>>
        +Post post
        +User author
        +DateTime occurredAt
    }
    
    %% Relationships
    CreateUserUseCase --> CreateUserCommand
    CreateUserUseCase --> CreateUserResponse
    CreateUserUseCase --> UserCreatedEvent
    
    PublishPostUseCase --> PublishPostCommand
    PublishPostUseCase --> PublishPostResponse
    PublishPostUseCase --> PostPublishedEvent
```

## 8.2 設計ドキュメント

### 8.2.1 アーキテクチャ図

#### 全体アーキテクチャ
```mermaid
C4Context
    title System Context diagram for Blog Platform
    
    Person(user, "Blog User", "A user who reads and writes blog posts")
    Person(admin, "Administrator", "Manages users and content")
    
    System(blogSystem, "Blog Platform", "Allows users to create, publish and read blog posts")
    
    System_Ext(emailSystem, "Email Service", "Sends notification emails")
    System_Ext(storageSystem, "File Storage", "Stores uploaded images and files")
    System_Ext(analyticsSystem, "Analytics", "Collects usage analytics")
    
    Rel(user, blogSystem, "Uses")
    Rel(admin, blogSystem, "Manages")
    Rel(blogSystem, emailSystem, "Sends emails using")
    Rel(blogSystem, storageSystem, "Stores files using")
    Rel(blogSystem, analyticsSystem, "Sends data to")
```

#### コンテナ図
```mermaid
C4Container
    title Container diagram for Blog Platform
    
    Person(user, "Blog User")
    Person(admin, "Administrator")
    
    Container_Boundary(c1, "Blog Platform") {
        Container(spa, "SPA", "Vue.js", "Provides blog functionality to users via their web browser")
        Container(api, "API Application", "Laravel", "Provides blog functionality via JSON/REST API")
        Container(database, "Database", "MariaDB", "Stores user accounts, blog posts, comments, etc.")
        Container(fileStorage, "File Storage", "Local/S3", "Stores uploaded files and images")
    }
    
    System_Ext(emailSystem, "Email Service")
    System_Ext(analyticsSystem, "Analytics")
    
    Rel(user, spa, "Uses", "HTTPS")
    Rel(admin, spa, "Uses", "HTTPS")
    Rel(spa, api, "Makes API calls to", "JSON/HTTPS")
    Rel(api, database, "Reads from and writes to", "SQL")
    Rel(api, fileStorage, "Stores files in")
    Rel(api, emailSystem, "Sends emails using")
    Rel(api, analyticsSystem, "Sends data to")
```

#### コンポーネント図（APIアプリケーション）
```mermaid
C4Component
    title Component diagram for API Application
    
    Container(spa, "SPA", "Vue.js")
    Container(database, "Database", "MariaDB")
    
    Container_Boundary(api, "API Application") {
        Component(authController, "Authentication Controller", "Laravel Controller", "Handles user authentication")
        Component(postController, "Post Controller", "Laravel Controller", "Handles blog post operations")
        Component(userController, "User Controller", "Laravel Controller", "Handles user management")
        
        Component(userService, "User Service", "PHP Class", "Business logic for user operations")
        Component(postService, "Post Service", "PHP Class", "Business logic for post operations")
        
        Component(userRepo, "User Repository", "Eloquent", "Data access for users")
        Component(postRepo, "Post Repository", "Eloquent", "Data access for posts")
        
        Component(emailService, "Email Service", "PHP Class", "Handles email sending")
        Component(fileService, "File Service", "PHP Class", "Handles file operations")
        
        Component(authMiddleware, "Auth Middleware", "Laravel Middleware", "Handles authentication")
        Component(corsMiddleware, "CORS Middleware", "Laravel Middleware", "Handles CORS")
    }
    
    Rel(spa, authController, "Makes API calls to")
    Rel(spa, postController, "Makes API calls to")
    Rel(spa, userController, "Makes API calls to")
    
    Rel(authController, userService, "Uses")
    Rel(postController, postService, "Uses")
    Rel(userController, userService, "Uses")
    
    Rel(userService, userRepo, "Uses")
    Rel(postService, postRepo, "Uses")
    Rel(userService, emailService, "Uses")
    Rel(postService, fileService, "Uses")
    
    Rel(userRepo, database, "Reads from and writes to")
    Rel(postRepo, database, "Reads from and writes to")
```

### 8.2.2 フローチャート

#### ユーザー認証フロー
```mermaid
flowchart TD
    A[ログイン画面] --> B{メール・パスワード入力}
    B --> C[バリデーション実行]
    C --> D{バリデーション結果}
    D -->|エラー| E[エラーメッセージ表示]
    E --> B
    D -->|成功| F[認証処理実行]
    F --> G{認証結果}
    G -->|失敗| H[認証エラー表示]
    H --> B
    G -->|成功| I{メール認証済み？}
    I -->|未認証| J[メール認証画面]
    J --> K[認証メール再送]
    K --> L[認証完了待ち]
    L --> I
    I -->|認証済み| M{アカウント状態}
    M -->|無効| N[アカウント無効エラー]
    N --> O[お問い合わせ案内]
    M -->|有効| P[JWTトークン生成]
    P --> Q[ユーザー情報取得]
    Q --> R[ダッシュボード表示]
    R --> S[ログイン完了]
```

#### 投稿公開フロー
```mermaid
flowchart TD
    A[投稿編集画面] --> B[公開ボタンクリック]
    B --> C[公開前バリデーション]
    C --> D{バリデーション結果}
    D -->|エラー| E[エラーメッセージ表示]
    E --> A
    D -->|成功| F{権限チェック}
    F -->|権限なし| G[権限エラー表示]
    G --> A
    F -->|権限あり| H[投稿ステータス更新]
    H --> I[公開日時設定]
    I --> J[検索インデックス更新]
    J --> K{通知設定確認}
    K -->|通知有効| L[購読者へ通知送信]
    K -->|通知無効| M[公開完了]
    L --> N{通知送信結果}
    N -->|失敗| O[通知送信失敗ログ]
    N -->|成功| M
    O --> M
    M --> P[成功メッセージ表示]
    P --> Q[投稿詳細ページへリダイレクト]
```

#### データバックアップフロー
```mermaid
flowchart TD
    A[定期実行スケジュール] --> B[バックアップ開始]
    B --> C[データベース接続確認]
    C --> D{接続状態}
    D -->|失敗| E[接続エラーログ]
    E --> F[管理者へアラート]
    F --> Z[処理終了]
    D -->|成功| G[バックアップファイル名生成]
    G --> H[データベースダンプ実行]
    H --> I{ダンプ結果}
    I -->|失敗| J[ダンプエラーログ]
    J --> F
    I -->|成功| K[ファイル圧縮]
    K --> L{圧縮結果}
    L -->|失敗| M[圧縮エラーログ]
    M --> F
    L -->|成功| N[外部ストレージアップロード]
    N --> O{アップロード結果}
    O -->|失敗| P[アップロードエラーログ]
    P --> Q[ローカルファイル保持]
    Q --> F
    O -->|成功| R[古いバックアップ削除]
    R --> S[バックアップ完了ログ]
    S --> T[管理者へ成功通知]
    T --> Z
```

#### エラーハンドリングフロー
```mermaid
flowchart TD
    A[エラー発生] --> B{エラーレベル}
    B -->|CRITICAL| C[システム停止]
    B -->|ERROR| D[エラーログ記録]
    B -->|WARNING| E[警告ログ記録]
    B -->|INFO| F[情報ログ記録]
    
    C --> G[管理者緊急通知]
    G --> H[メンテナンスページ表示]
    H --> I[復旧作業]
    
    D --> J{ユーザー影響}
    J -->|あり| K[ユーザーエラー画面]
    J -->|なし| L[バックグラウンド処理]
    
    K --> M[エラーメッセージ表示]
    M --> N[代替操作案内]
    N --> O[サポート連絡先案内]
    
    L --> P[自動復旧試行]
    P --> Q{復旧結果}
    Q -->|成功| R[復旧ログ記録]
    Q -->|失敗| S[管理者通知]
    
    E --> T[監視システム記録]
    F --> U[統計情報更新]
    
    R --> V[処理完了]
    S --> V
    T --> V
    U --> V
    O --> V
    I --> V
```
