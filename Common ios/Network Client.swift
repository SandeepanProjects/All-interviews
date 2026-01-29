//
//  Network Client.swift
//  
//
//  Created by Apple on 29/01/26.
//

import Foundation

Great one 🔥 — **network client testing** is where people usually slip, especially with **async/await + Swift Testing + SOLID**.

I’ll show you a **production-ready NetworkClient**, then **clean test cases** using:

* `Swift Testing` (`import Testing`)
* `async/await`
* **protocol-based URLSession mocking**
* **error + decoding + request validation**
* SOLID all the way

No XCTest. No URLProtocol hacks (unless you want them later).

---

# 1️⃣ Network Client Design (Testable by default)

### Errors

```swift
enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
}
```

---

### Protocol for URLSession (Dependency Inversion ✅)

```swift
protocol URLSessioning {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
```

Make `URLSession` conform:

```swift
extension URLSession: URLSessioning {}
```

---

### Network Client

```swift
struct NetworkClient {

    private let session: URLSessioning
    private let decoder: JSONDecoder

    init(
        session: URLSessioning = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(-1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
```

✔ Testable
✔ Async/await
✔ No global state
✔ Clean boundaries

---

# 2️⃣ Mock URLSession

This is the **key piece**.

```swift
final class MockURLSession: URLSessioning {

    var data: Data?
    var response: URLResponse?
    var error: Error?

    private(set) var receivedRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequest = request

        if let error {
            throw error
        }

        return (data ?? Data(), response!)
    }
}
```

---

# 3️⃣ Test Model

```swift
struct Todo: Decodable, Equatable {
    let id: Int
    let title: String
}
```

---

# 4️⃣ Swift Testing Setup

```swift
import Testing
@testable import YourAppModule
```

---

# 5️⃣ Test Case: Successful Request ✅

```swift
@Test
func request_successfullyDecodesResponse() async throws {
    let session = MockURLSession()
    let client = NetworkClient(session: session)

    let json = """
    { "id": 1, "title": "Learn Swift" }
    """.data(using: .utf8)!

    session.data = json
    session.response = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )

    let request = URLRequest(url: URL(string: "https://test.com")!)

    let result: Todo = try await client.request(request)

    #expect(result == Todo(id: 1, title: "Learn Swift"))
    #expect(session.receivedRequest?.url?.absoluteString == "https://test.com")
}
```

---

# 6️⃣ Test Case: HTTP Error (404, 500, etc.)

```swift
@Test
func request_httpError_throwsRequestFailed() async {
    let session = MockURLSession()
    let client = NetworkClient(session: session)

    session.data = Data()
    session.response = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 404,
        httpVersion: nil,
        headerFields: nil
    )

    let request = URLRequest(url: URL(string: "https://test.com")!)

    await #expect(throws: NetworkError.requestFailed(404)) {
        let _: Todo = try await client.request(request)
    }
}
```

---

# 7️⃣ Test Case: Decoding Failure

```swift
@Test
func request_invalidJSON_throwsDecodingError() async {
    let session = MockURLSession()
    let client = NetworkClient(session: session)

    session.data = Data("invalid json".utf8)
    session.response = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )

    let request = URLRequest(url: URL(string: "https://test.com")!)

    await #expect(throws: NetworkError.decodingFailed) {
        let _: Todo = try await client.request(request)
    }
}
```

---

# 8️⃣ Test Case: Network Failure (No Internet, Timeout)

```swift
@Test
func request_networkError_isPropagated() async {
    let session = MockURLSession()
    let client = NetworkClient(session: session)

    session.error = URLError(.notConnectedToInternet)

    let request = URLRequest(url: URL(string: "https://test.com")!)

    await #expect(throws: URLError.self) {
        let _: Todo = try await client.request(request)
    }
}
```

---

# 9️⃣ Test Case: Verifying Headers & HTTP Method

```swift
@Test
func request_sendsCorrectHeaders() async throws {
    let session = MockURLSession()
    let client = NetworkClient(session: session)

    session.data = Data("""
    { "id": 1, "title": "Test" }
    """.utf8)

    session.response = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )

    var request = URLRequest(url: URL(string: "https://test.com")!)
    request.httpMethod = "POST"
    request.setValue("Bearer token", forHTTPHeaderField: "Authorization")

    let _: Todo = try await client.request(request)

    #expect(session.receivedRequest?.httpMethod == "POST")
    #expect(
        session.receivedRequest?
            .value(forHTTPHeaderField: "Authorization") == "Bearer token"
    )
}
```

---

# 🔟 What You Just Demonstrated (Senior Signal 🚀)

✔ Async/await networking
✔ Swift Testing (modern)
✔ Dependency inversion
✔ Deterministic tests
✔ No flaky network calls
✔ Clean separation of concerns

---

# 🧠 Interview One-liner

> “I test my network layer by abstracting URLSession behind a protocol and using Swift Testing with async tests to validate decoding, errors, and request construction.”

---

If you want next:

* 🔁 **Retry + exponential backoff tests**
* 🧵 **Actor-based NetworkClient**
* 🔐 **Certificate pinning tests**
* 📦 **Caching layer + tests**

Just say it 😄
