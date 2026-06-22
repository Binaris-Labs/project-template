# Application Flow Visualization

This document visually explains how a request travels through our backend system, and how our automated testing (CI/CD) guarantees everything works.

## 1. The Architecture Flow (High Level)

Here is how the different pieces of our application connect together. Notice how the request moves from the outside world inwards towards the database, and then flows back out.

```mermaid
flowchart TD
    subgraph Client [Outside World]
        User([📱 Mobile App / Web Frontend])
    end

    subgraph App [Our Golang Application]
        Main(🏁 cmd/api/main.go)
        Router{🚪 Router / app.go}
        
        subgraph Module [e.g., Auth Module]
            Handler(🧑‍🍳 Handler)
            Service(🧠 Service)
            Repo(🗄️ Repository)
        end
    end

    subgraph Database [Storage]
        DB[(🐘 PostgreSQL)]
    end

    %% The Request Flow
    User -- "1. HTTP Request" --> Router
    Main -. "Starts" .-> Router
    
    Router -- "2. Routes to" --> Handler
    Handler -- "3. Calls" --> Service
    Service -- "4. Requests Data" --> Repo
    Repo -- "5. SQL Query" --> DB
    
    %% The Response Flow
    DB -. "6. Data" .-> Repo
    Repo -. "7. Structs" .-> Service
    Service -. "8. Result/Error" .-> Handler
    Handler -. "9. JSON Response" .-> User

    %% Styling
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef client fill:#d4edda,stroke:#28a745,stroke-width:2px;
    classDef db fill:#cce5ff,stroke:#007bff,stroke-width:2px;
    classDef logic fill:#fff3cd,stroke:#ffc107,stroke-width:2px;

    class User client;
    class DB db;
    class Handler,Service,Repo logic;
```

---

## 2. GitHub CI/CD Pipeline (Testing Flow)

Every time you `git push` code, a robot tests it. Here is what happens in the background.

```mermaid
sequenceDiagram
    actor Dev as 🧑‍💻 Developer
    participant Git as 🐙 GitHub Repository
    participant Action as ⚙️ GitHub Actions (CI)
    participant DB as 🐘 PostgreSQL Container
    participant Test as 🧪 Go Tests

    Dev->>Git: 1. git push origin main
    Git->>Action: 2. Trigger Pipeline (ci.yml)
    
    rect rgb(240, 248, 255)
    Note over Action,Test: 🚀 CI/CD Environment Spins Up
    Action->>Action: 3. Install Go
    Action->>DB: 4. Start PostgreSQL Service
    Action->>DB: 5. Wait for DB to be "Ready" (pg_isready)
    end
    
    rect rgb(255, 240, 245)
    Note over Action,Test: ⚡ Phase 1: Unit Tests (No DB)
    Action->>Test: 6. Run `make test-unit`
    Test-->>Action: ✅ Unit Tests Pass
    end

    rect rgb(230, 255, 230)
    Note over Action,Test: 🌍 Phase 2: Integration Tests (Real DB)
    Action->>Test: 7. Run `make test-integration`
    Test->>DB: 8. Execute real SQL queries
    DB-->>Test: 9. Return real data
    Test-->>Action: ✅ Integration Tests Pass
    end

    Action-->>Git: 10. Mark Pull Request with Green Checkmark ✅
    Git-->>Dev: 11. Safe to Merge!
```

---

## 3. Detailed Sequence (The "Login" Example)

If you want to see exactly what happens over time when a user logs in, here is the sequence of events:

```mermaid
sequenceDiagram
    actor User as 📱 Client App
    participant Route as 🚪 Router (app.go)
    participant Handler as 🧑‍🍳 Handler
    participant Service as 🧠 Service
    participant Repo as 🗄️ Repository
    participant DB as 🐘 PostgreSQL

    User->>Route: 1. Send HTTP Request (POST /login)
    Route->>Handler: 2. Match URL & Forward
    Handler->>Service: 3. Validate Input, Pass to Service
    Service->>Repo: 4. Apply Business Logic, Request Data
    Repo->>DB: 5. Execute SQL Query
    DB-->>Repo: 6. Return DB Rows
    Repo-->>Service: 7. Return Go Structs
    Service-->>Handler: 8. Return Processed Data/Error
    Handler-->>User: 9. Return JSON Response (200 OK)
```

---

## 🔑 Key Rule to Remember: The "One Way" Street

To keep our code clean and prevent messy bugs, we enforce strict rules about who can talk to whom:

- ❌ **Handlers** CANNOT talk directly to **Repositories**.
- ❌ **Services** CANNOT talk directly to the **Database**.
- ✅ **Handlers** ONLY talk to **Services**.
- ✅ **Services** ONLY talk to **Repositories**.
- ✅ **Repositories** ONLY talk to the **Database**.

If you follow this "One Way" street, your code will always be clean, easy to test, and easy to read!
