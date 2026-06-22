# Backend Template (Golang)

Welcome to the Backend Template! This project is designed as a starting point for your new applications. It is built using **Golang** and the **Echo Framework**.

This documentation is written specifically to help **junior developers** understand how the project is structured, how the flow of data works, and how to start the application easily.

---

## 1. How to run it

Follow these simple steps to run the backend application on your local machine:

### Step 1: Set up your Environment Variables
1. Find the `.env.example` file in the root directory.
2. Copy it and rename the copy to `.env`.
   ```bash
   cp .env.example .env
   ```
3. Open `.env` and fill in your actual database credentials.

### Step 2: Install Dependencies
Download all the required third-party libraries (like Echo, Zap Logger, Postgres driver).
```bash
go mod tidy
```

### Step 3: Run Database Migrations
Since we are using PostgreSQL, make sure your database is running. If you have any `.sql` files in the `db/migrations` folder, run them in your database tool or via the Makefile `make migrate-up`.

### Step 4: Start the Server
Now you can start the application!
```bash
go run cmd/api/main.go
```
*Tip: If you have `make` installed, you can also just type `make run` in your terminal!*

If everything is successful, you will see a log message saying: `🚀 Starting backend Server on port :8080`.

---

## 2. Testing Explained (Caveman Style)

Testing is how we prove our code works *before* it breaks in production. We have two main types of tests here.

### A. Unit Tests (`make test-unit`)
- **What it is:** Testing a tiny piece of code completely in isolation (like testing a single function).
- **The Caveman Explanation:** "Does the chef cook the egg correctly when I give him an egg?"
- **Rules:** NO database. NO real internet. We use "mocks" (fake data) to pretend the database exists. Because there is no database, these run **lightning fast**.
- **Where they live:** Next to the file they are testing (e.g., `internal/modules/health/service_test.go`).

### B. Integration Tests (`make test-integration`)
- **What it is:** Testing the entire flow from start to finish, just like a real user.
- **The Caveman Explanation:** "I walk in the door, talk to the waiter, the waiter tells the chef, the chef gets food from the pantry, and brings it back. Was it delicious?"
- **Rules:** YES database. YES real network requests (HTTP). We spin up the whole server and make real `curl`/`GET`/`POST` requests. Because they touch a real database, they are **slower**.
- **Where they live:** Inside the `tests/` folder at the root.

---

## 3. GitHub CI/CD Pipeline Explained

**CI/CD** stands for *Continuous Integration / Continuous Deployment*.

### How it works (The Flow):
1. You finish writing code and do a `git push` or open a Pull Request (PR).
2. GitHub detects the push and instantly starts a hidden server (a "Runner") in the cloud.
3. The Runner looks at `.github/workflows/ci.yml` and follows the instructions:
   - "Install Go"
   - "Start a PostgreSQL database inside a Docker container"
   - "Run `make test-unit`"
   - "Run `make test-integration`"
4. If **any test fails**, GitHub marks your code with a big red ❌. You cannot merge it!
5. If **all tests pass**, GitHub gives you a green ✅. Your code is safe to merge.

**Why is this amazing?** You never have to guess if you broke something. The robot (GitHub Actions) tests your entire app automatically every single time you push code.

---

## 4. How to read the flow (The Request Journey)

> **💡 Want a visual step-by-step diagram?**  
> Check out the [FLOW.md](./FLOW.md) file for a complete visual breakdown, including the CI/CD flow!

When a user sends a request to our API, it travels through several files. Think of it like a customer ordering food at a restaurant:

1. **`cmd/api/main.go` (The Front Door)**
   - Where the application starts. Calls the `app` package.
2. **`internal/app/app.go` (The Manager)**
   - Sets up the server, database, logging, and registers URLs.
3. **`Handler` (The Waiter)** 
   - Receives the HTTP request. Checks input. Passes to Service.
4. **`Service` (The Chef)** 
   - The **Business Logic**. Hashes passwords, checks rules. Asks Repo for data.
5. **`Repository` (The Pantry/Database)** 
   - The ONLY place that talks directly to PostgreSQL. Runs SQL queries.

**The Flow Summary:**
`main.go` ➔ `app.go` ➔ **Handler** ➔ **Service** ➔ **Repository** ➔ **Database**

---

*Happy Coding! Take it one step at a time, read the errors in the terminal, and you'll do great.* 🚀
