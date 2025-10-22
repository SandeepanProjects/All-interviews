//
//  UserListViewModel.swift
//  MVVMApiPagination
//
//  Created by Apple on 18/10/25.
//

// ViewModels/UserListViewModel.swift
import Foundation
// import Observation

@MainActor
final class UserListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let apiService: APIServiceProtocol

    // MARK: - Pagination State
    private(set) var currentPage: Int = 1
    private(set) var canLoadMore: Bool = true
    private let pageLimit: Int = 20

    // MARK: - Init
    init(apiService: APIServiceProtocol = UserService()) {
        self.apiService = apiService
    }

    // MARK: - Public Methods

    func loadInitialUsers() async {
        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        currentPage = 1
        canLoadMore = true

        do {
            let fetchedUsers = try await apiService.fetchUsers(page: currentPage, limit: pageLimit)
            self.users = fetchedUsers
            self.currentPage += 1
            self.canLoadMore = !fetchedUsers.isEmpty
        } catch {
            self.errorMessage = mapError(error)
        }

        isLoading = false
    }

    func loadMoreUsers() async {
        guard !isLoading, !isLoadingMore, canLoadMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let newUsers = try await apiService.fetchUsers(page: currentPage, limit: pageLimit)
            if newUsers.isEmpty {
                canLoadMore = false
            } else {
                users += newUsers
                currentPage += 1
            }
        } catch {
            self.errorMessage = mapError(error)
        }
    }

    // MARK: - Error Mapping
    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        } else {
            return "An unexpected error occurred. Please try again."
        }
    }
}


// Models/User.swift
struct User: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let email: String
}

protocol APIServiceProtocol {
    func fetchUsers(page: Int, limit: Int) async throws -> [User]
}

// Services/UserService.swift
final class UserService: APIServiceProtocol {

    private let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsers(page: Int = 1, limit: Int = 10) async throws -> [User] {
        let url = baseURL.appendingPathComponent("/users")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        let users = try JSONDecoder().decode([User].self, from: data)

        // Simulate pagination manually (as the API does not support it)
        let start = (page - 1) * limit
        let end = min(start + limit, users.count)

        guard start < end else { return [] }

        return Array(users[start..<end])
    }

}

// Models/APIError.swift
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError(URLError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server response was invalid."
        case .decodingError:
            return "Failed to decode the response."
        case .networkError(let error):
            return error.localizedDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

