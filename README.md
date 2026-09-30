# TokenRefreshDemo

A SwiftUI demo project that demonstrates access-token expiration, refresh-token handling, concurrent API requests, and **single-flight token refresh using Swift Concurrency and actors**.

The project uses [DummyJSON](https://dummyjson.com/) as the backend, so no custom backend is required.

---

## 🎯 Problem We Are Solving

Modern mobile applications commonly use:

- **Access Token** — a short-lived token used to access protected APIs.
- **Refresh Token** — used to obtain a new access token when the access token expires.

The normal flow is:

```text
Login
  ↓
Access Token + Refresh Token
  ↓
Call protected API
  ↓
200 OK
```

The problem appears when the access token expires while **multiple API requests are running concurrently**.

For example:

```text
Dashboard
   ↓
7 API requests start concurrently
   ↓
Access token has expired
   ↓
7 requests receive 401
```

A naive implementation can produce:

```text
Request 1 → 401 → Refresh
Request 2 → 401 → Refresh
Request 3 → 401 → Refresh
Request 4 → 401 → Refresh
Request 5 → 401 → Refresh
Request 6 → 401 → Refresh
Request 7 → 401 → Refresh
```

Only one refresh is actually required.

This project reproduces that problem first and then solves it.

---

# 🧠 Core Concept

When multiple requests receive `401` because the access token has expired:

> **Only one request should refresh the token. All other requests should wait for that same refresh operation and then retry using the new access token.**

We solve this using two Swift Concurrency concepts.

### 1. `actor`

`TokenManager` is an actor:

```swift
actor TokenManager {
    ...
}
```

It protects shared authentication state from concurrent access.

### 2. Shared `refreshTask`

`TokenManager` maintains:

```swift
private var refreshTask: Task<String, Error>?
```

The first request starts the refresh.

Other requests see that a refresh is already running and wait for the same task:

```swift
if let refreshTask {
    return try await refreshTask.value
}
```

Therefore:

```text
7 × 401
   ↓
TokenManager actor
   ↓
ONE refreshTask
   ↓
ONE /auth/refresh request
   ↓
New access token
   ↓
All 7 requests retry
```

---

# 🏗 Architecture

The project intentionally uses a simple architecture:

```text
View
  ↓
ViewModel
  ↓
NetworkClient
  ↓
TokenManager (actor)
  ↓
TokenStorage
```

For an authenticated request:

```text
DashboardView
      ↓
DashboardViewModel
      ↓
NetworkClient
      ↓
GET /auth/me
      ↓
    401?
      ↓
TokenManager
      ↓
POST /auth/refresh
      ↓
Save new tokens
      ↓
Retry original request
      ↓
   200 OK
```

The ViewModel does not know how token refresh works.

---

# 📁 Project Structure

```text
TokenRefreshDemo
│
├── Authentication
│   ├── LoginView.swift
│   ├── LoginViewModel.swift
│   ├── LoginRequest.swift
│   └── LoginResponse.swift
│
├── Dashboard
│   ├── DashboardView.swift
│   ├── DashboardViewModel.swift
│   ├── DashboardResult.swift
│   └── CurrentUserResponse.swift
│
├── Networking
│   ├── NetworkClient.swift
│   └── NetworkError.swift
│
└── Token
    ├── TokenStorage.swift
    ├── TokenManager.swift
    ├── RefreshTokenRequest.swift
    └── RefreshTokenResponse.swift
```

---

# 🔐 Authentication

The demo uses DummyJSON.

### Login

```http
POST https://dummyjson.com/auth/login
```

Credentials:

```text
Username: emilys
Password: emilyspass
```

The login request uses:

```text
expiresInMins = 1
```

This gives us a short-lived access token, making expiration easy to reproduce.

The response contains:

```text
accessToken
refreshToken
```

These are stored in `TokenStorage`.

---

# 🔒 Protected API

The protected endpoint used by this demo is:

```http
GET https://dummyjson.com/auth/me
```

with:

```http
Authorization: Bearer <accessToken>
```

Valid token:

```text
/auth/me
   ↓
200 OK
```

Expired/invalid token:

```text
/auth/me
   ↓
401 Unauthorized
```

---

# 🔄 Refresh Token Flow

When `NetworkClient` receives a `401`, it asks `TokenManager` to refresh the token.

```text
GET /auth/me
      ↓
    401
      ↓
TokenManager.refreshAccessToken()
      ↓
POST /auth/refresh
      ↓
New accessToken + refreshToken
      ↓
Save tokens
      ↓
Retry /auth/me
```

The ViewModel only calls:

```swift
let user: CurrentUserResponse =
    try await networkClient.authenticatedGet(
        url: "https://dummyjson.com/auth/me"
    )
```

It does not contain refresh logic.

---

# 🧵 Why Do We Need an Actor?

Suppose seven requests run concurrently:

```text
Request 1 ─┐
Request 2 ─┤
Request 3 ─┤
Request 4 ─┼──→ /auth/me
Request 5 ─┤
Request 6 ─┤
Request 7 ─┘
```

The access token expires.

All seven receive:

```text
401
```

Without coordination:

```text
Request 1 → Refresh
Request 2 → Refresh
Request 3 → Refresh
Request 4 → Refresh
Request 5 → Refresh
Request 6 → Refresh
Request 7 → Refresh
```

The application unnecessarily performs seven refresh requests.

The actor gives us one shared, isolated place to coordinate this state.

---

# 🛡 Actor + `refreshTask`

`TokenManager` contains:

```swift
private var refreshTask: Task<String, Error>?
```

The first request enters the actor and sees:

```text
refreshTask == nil
```

It creates the refresh task.

The next requests enter the actor and see:

```text
refreshTask != nil
```

They wait:

```swift
try await refreshTask.value
```

So the result becomes:

```text
Request 1 ─┐
Request 2 ─┤
Request 3 ─┤
Request 4 ─┤
Request 5 ─┤
Request 6 ─┤
Request 7 ─┘
      ↓
TokenManager actor
      ↓
ONE refreshTask
      ↓
ONE /auth/refresh
      ↓
New access token
      ↓
All 7 requests retry
```

---

# ⭐ Actor vs `refreshTask`

This distinction is important for interviews.

### Actor

The actor protects shared mutable state:

```swift
actor TokenManager
```

It safely coordinates access to:

```swift
refreshTask
```

### `refreshTask`

The shared task implements the **single-flight** behavior.

It ensures:

```text
7 requests
   ↓
ONE refresh operation
```

instead of:

```text
7 requests
   ↓
7 refresh operations
```

Therefore:

> **The actor provides safe isolation of shared state, while the shared refresh task ensures only one refresh operation is in flight.**

---

# 🔁 Retry Protection

Another important problem is an infinite retry loop.

Without protection:

```text
/auth/me
   ↓
401
   ↓
refresh
   ↓
retry
   ↓
401
   ↓
refresh
   ↓
retry
   ↓
...
```

The implementation therefore tracks whether the request is already a retry:

```swift
func authenticatedGet<T: Decodable>(
    url: String,
    isRetry: Bool = false
)
```

If the retry also receives `401`:

```text
401
 ↓
Already retried?
 ↓
YES
 ↓
Stop
```

This prevents an infinite refresh/retry loop.

---

# 🧪 Testing the Demo

The project contains a temporary button:

```text
Invalidate Access Token
```

It deliberately replaces the access token with an invalid value.

This allows the concurrency scenario to be reproduced immediately without waiting for the real one-minute expiration.

---

## Test 1 — Normal Request

1. Launch the application.
2. Login using:
   ```text
   Username: emilys
   Password: emilyspass
   ```
3. Dashboard loads.
4. `/auth/me` returns `200`.

Expected:

```text
✅ Dashboard loaded
```

---

## Test 2 — Automatic Refresh

1. Login.
2. Wait approximately one minute.
3. Tap:
   ```text
   Refresh Dashboard
   ```
4. `/auth/me` returns `401`.
5. `TokenManager` refreshes the token.
6. The request is retried.
7. The request succeeds.

Expected console:

```text
⚠️ Access token expired
🔄 Starting token refresh
✅ Token refresh successful
🔄 Retrying request with new access token
```

---

# 🧪 Test 3 — Reproduce the Problem

The project first demonstrated the naive implementation.

Seven concurrent requests were executed:

```text
7 × /auth/me
```

After the access token was invalidated:

```text
7 × 401
```

The naive implementation produced:

```text
7 × /auth/refresh
```

This proved that concurrent requests can cause multiple refresh operations.

---

# 🧪 Test 4 — Verify the Actor Solution

The current implementation uses:

```text
TokenManager actor
        +
shared refreshTask
```

### Steps

1. Login.
2. Tap:
   ```text
   Invalidate Access Token
   ```
3. Tap:
   ```text
   Test 7 Concurrent Requests
   ```

The requests are created using `async let`:

```swift
async let user1 = fetchUser()
async let user2 = fetchUser()
async let user3 = fetchUser()
async let user4 = fetchUser()
async let user5 = fetchUser()
async let user6 = fetchUser()
async let user7 = fetchUser()
```

Expected console:

```text
🚀 Starting 7 concurrent requests

⚠️ Access token expired

🔄 Starting token refresh

⚠️ Access token expired
⏳ Waiting for existing token refresh

⚠️ Access token expired
⏳ Waiting for existing token refresh

...

✅ Token refresh successful

🔄 Retrying request with new access token
🔄 Retrying request with new access token
...

✅ All 7 requests completed
```

### Most important verification

This should appear **only once**:

```text
🔄 Starting token refresh
```

These messages should appear for the other concurrent requests:

```text
⏳ Waiting for existing token refresh
```

That proves the single-flight refresh mechanism is working.

---

# 📊 Before vs After

## ❌ Naive Implementation

```text
7 concurrent requests
        ↓
7 × 401
        ↓
7 × /auth/refresh
        ↓
7 retries
```

Problems:

- Unnecessary network traffic
- Multiple refresh operations
- Concurrent authentication-state updates
- Increased backend load
- More complicated authentication behavior

---

## ✅ Actor + Single-Flight

```text
7 concurrent requests
        ↓
7 × 401
        ↓
TokenManager actor
        ↓
ONE refreshTask
        ↓
ONE /auth/refresh
        ↓
New access token
        ↓
7 retries
        ↓
7 × 200
```

---

# 🧩 Why NetworkClient Owns the Retry Logic

Authentication behavior belongs in the networking layer rather than individual ViewModels.

The ViewModel simply does:

```swift
do {
    let user = try await networkClient.authenticatedGet(...)
} catch {
    // Handle final failure
}
```

The networking layer handles:

```text
401
 ↓
refresh
 ↓
retry
```

This means multiple ViewModels can share the same authentication behavior:

```text
ProfileViewModel
TransactionsViewModel
CardsViewModel
DashboardViewModel
        ↓
   NetworkClient
        ↓
   TokenManager
```

---

# 🎤 Interview Explanation

A concise senior-level answer:

> "For authenticated API calls, I handle 401 responses inside the networking layer. When the access token expires, the NetworkClient asks a TokenManager actor to refresh it. The TokenManager maintains a shared refresh Task, so if multiple concurrent requests receive 401, the first request starts the refresh while the others await the same Task. Once the new token is available, all failed requests retry with it. I also prevent infinite retry loops by allowing only one refresh-and-retry cycle per request."

---

# 🔑 Swift Concurrency Concepts Demonstrated

### `async/await`

Asynchronous networking:

```swift
try await networkClient.get(...)
```

### `async let`

Concurrent independent operations:

```swift
async let user1 = fetchUser()
async let user2 = fetchUser()
```

### `actor`

Isolated shared state:

```swift
actor TokenManager
```

### `Task`

Represents the shared refresh operation:

```swift
Task<String, Error>
```

### Task sharing / single-flight

Multiple callers await:

```swift
refreshTask.value
```

instead of creating multiple refresh operations.

---

# 🚀 Learning Progression

The project follows this progression intentionally:

```text
1. Basic Login
       ↓
2. Access Token
       ↓
3. Protected API
       ↓
4. Token Expiration
       ↓
5. 401 Handling
       ↓
6. Refresh Token
       ↓
7. Retry Request
       ↓
8. Concurrent Requests
       ↓
9. Multiple Refresh Problem
       ↓
10. Actor
       ↓
11. Shared refreshTask
       ↓
12. Single Refresh + Multiple Retries
```

The important learning strategy is:

> **First reproduce the race condition. Then solve it.**

That makes the reason for using an actor much easier to understand than simply adding an actor because "Swift Concurrency recommends it."

---

# ⚠️ Production Considerations

This project is intentionally simplified for learning.

A production application would additionally consider:

- Secure token storage using Keychain
- Refresh-token expiration
- Logout when refresh fails
- Handling 401 responses for all authenticated HTTP methods
- Request cancellation
- Network connectivity failures
- Backoff/retry policies
- Token rotation
- Never logging authentication tokens
- Synchronizing logout with in-flight requests
- App background/foreground transitions
- Centralized authentication state

The demo currently stores tokens in memory using `TokenStorage` and prints tokens during development. **Do not print tokens in production.**

---

# 🛠 Technologies

- Swift
- SwiftUI
- Swift Concurrency
- `async/await`
- `async let`
- `Task`
- `actor`
- URLSession
- REST APIs
- DummyJSON

---

# 📚 DummyJSON APIs

### Login

```text
POST https://dummyjson.com/auth/login
```

### Protected user API

```text
GET https://dummyjson.com/auth/me
```

### Refresh token

```text
POST https://dummyjson.com/auth/refresh
```

Documentation:

https://dummyjson.com/docs/auth

---

# 🏁 Final Mental Model

Remember this:

```text
Access Token
     │
     ├── Valid ───────────────→ API → 200
     │
     └── Expired
           ↓
          401
           ↓
    TokenManager Actor
           ↓
      Is refresh running?
         ↙       ↘
       No         Yes
       ↓           ↓
 Start refresh   Wait for
     Task        same Task
       ↓           ↓
       └─────┬─────┘
             ↓
       New Access Token
             ↓
       Retry Request
             ↓
            200
```

## The One Sentence to Remember

> **The actor protects shared authentication state; the shared refresh Task ensures that concurrent 401 responses result in one refresh operation, and all requests wait for and reuse its result.**
