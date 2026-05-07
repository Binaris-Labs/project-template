# Backend Template (Golang)

Welcome to the Backend Template! This project is designed as a starting point for your new applications. It is built using **Golang** and the **Echo Framework**.

This documentation is written specifically to help **junior developers** understand how the project is structured, how the flow of data works, and how to start the application easily.

---

## 1. How to run it

Follow these simple steps to run the backend application on your local machine:

### Step 1: Set up your Environment Variables
Before running the app, it needs to know your configuration (like database passwords, port numbers, etc.).
1. Find the `.env.example` file in the root directory.
2. Copy it and rename the copy to `.env`.
   ```bash
   cp .env.example .env
   ```
3. Open `.env` and fill in your actual database credentials (e.g., PostgreSQL username, password, database name).

### Step 2: Install Dependencies
Download all the required third-party libraries (like Echo, Zap Logger, Postgres driver).
```bash
go mod tidy
```

### Step 3: Run Database Migrations
Since we are using PostgreSQL, make sure your database is running. If you have any `.sql` files in the `db/migrations` folder, run them in your database tool (like DBeaver, TablePlus, or pgAdmin) to create the necessary tables.

### Step 4: Start the Server
Now you can start the application!
```bash
go run cmd/api/main.go
```
*Tip: If you have `make` installed, you can also just type `make run` in your terminal!*

If everything is successful, you will see a log message saying: `🚀 Starting backend Server on port :8080`.

---

## 2. How to read the flow (The Request Journey)

> **💡 Want a visual step-by-step diagram?**  
> Check out the [FLOW.md](./FLOW.md) file for a complete visual breakdown and sequence diagram!

When a user (from a mobile app or frontend website) sends a request to our API, the request travels through several files. Think of it like a customer ordering food at a restaurant:

1. **`cmd/api/main.go` (The Front Door)**
   - This is where the application starts. It simply calls the `app` package to boot up everything.
2. **`internal/app/app.go` (The Manager)**
   - This file sets up the server, connects to the database, turns on logging, and registers all the available routes (URLs).
3. **`Handler` (The Waiter)** e.g., `internal/modules/auth/handler.go`
   - The Handler receives the HTTP request from the user. It checks if the input is correct (e.g., did they send an email and password?). Then, it passes the data to the Service.
4. **`Service` (The Chef)** e.g., `internal/modules/auth/service.go`
   - The Service contains the **Business Logic**. It decides what to do with the data (e.g., hash the password, check if the user exists). It asks the Repository for data.
5. **`Repository` (The Pantry/Database)** e.g., `internal/modules/auth/repository.go`
   - The Repository is the ONLY place that talks directly to the Database (PostgreSQL). It runs SQL queries to insert or fetch data and returns it to the Service.

**The Flow Summary:**
`main.go` ➔ `app.go` ➔ **Handler** ➔ **Service** ➔ **Repository** ➔ **Database**

---

## 3. Folder & File Purposes

Understanding what each folder does will make it much easier to find your way around the code!

### `/cmd`
- **Purpose:** The main entry point of the application.
- **Inside:** `api/main.go`. This file is extremely small. Its only job is to trigger `NewApp().Run()`.

### `/internal`
- **Purpose:** This is the heart of the application. All your private business logic lives here.
- **`/app/app.go`**: The central wiring file. It loads config, starts the database, and registers your modules.
- **`/config`**: Reads the `.env` file and makes variables available throughout the app.
- **`/middleware`**: Code that runs *before* a request reaches the Handler (e.g., checking if a user has a valid JWT token).
- **`/modules`**: This is where your features live. For example, `auth` is a module. If you build a "Cart" feature, you will create a new folder here called `cart`.

### `/pkg`
- **Purpose:** Public tools and utilities that can be shared across the application.
- **`/database`**: Contains the code to connect to PostgreSQL.
- **`/logger`**: Contains the setup for our logging tool (Uber Zap) so we can print beautiful error messages in the terminal.
- **`/respond`**: A helper tool to send standardized JSON responses back to the frontend (e.g., `respond.Success` or `respond.Error`).

### `/db`
- **Purpose:** Database related files.
- **`/migrations`**: Stores `.sql` files that create or alter tables in your PostgreSQL database.

---

## 4. Important Functions & What They Mean

Here are some common functions you will see and what they actually do:

- **`NewApp()`** *(inside `app.go`)*
  - **Meaning:** "Create a new instance of our server." It prepares the database, router, and logger before we actually start listening for user requests.
- **`Run()`** *(inside `app.go`)*
  - **Meaning:** "Turn on the server." This function blocks the terminal and listens for incoming internet traffic on the specified port.
- **`RegisterRoutes(router)`** *(inside handler files)*
  - **Meaning:** "Tell the server which URLs go to which function." For example, it tells the server: *If someone goes to `POST /login`, send them to the `Login()` function in this handler.*
- **`NewService(repo)`** or **`NewHandler(service)`**
  - **Meaning:** This is called **Dependency Injection**. It means a Handler cannot work without a Service, and a Service cannot work without a Repository. This function links them together so they can talk to each other.

---
*Happy Coding! Take it one step at a time, read the errors in the terminal, and you'll do great.* 🚀
