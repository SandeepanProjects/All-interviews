//
//  UserListView.swift
//  MVVMApiPagination
//
//  Created by Apple on 18/10/25.
//

// Views/UserListView.swift
import SwiftUI

// DI/AppContainer.swift
enum AppContainer {
    @MainActor static func makeUserListView() -> some View {
        let service = UserService()
        let viewModel = UserListViewModel(apiService: service)
        return UserListView(viewModel: viewModel)
    }
}

// Views/UserListView.swift
struct UserListView: View {
    @StateObject private var viewModel: UserListViewModel
    @State private var navigationPath = NavigationPath()

    init(viewModel: UserListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Users")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                }
        }
        .task {
            await viewModel.loadInitialUsers()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.users.isEmpty {
            ProgressView("Loading users...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
            errorView(message: errorMessage)
        } else {
            userList
        }
    }

    private var userList: some View {
        List {
            ForEach(viewModel.users.indices, id: \.self) { index in
                let user = viewModel.users[index]
                Button {
                    navigationPath.append(user)
                } label: {
                    userRow(user)
                }
                .onAppear {
                    handleOnAppear(at: index)
                }
            }

            if viewModel.isLoadingMore {
                loadingFooter
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadInitialUsers()
        }
    }

    private func userRow(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private func handleOnAppear(at index: Int) {
        guard !viewModel.isLoading,
              !viewModel.isLoadingMore,
              viewModel.canLoadMore else {
            return
        }

        let threshold = 5
        let lastIndex = viewModel.users.count - 1
        let triggerIndex = max(lastIndex - threshold, 0)

        if index >= triggerIndex {
            Task {
                await viewModel.loadMoreUsers()
            }
        }
    }

    private var loadingFooter: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Error: \(message)")
                .multilineTextAlignment(.center)
                .foregroundColor(.red)

            Button("Retry") {
                Task {
                    await viewModel.loadInitialUsers()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}




// Views/UserDetailView.swift
struct UserDetailView: View {
    let user: User

    var body: some View {
        VStack(spacing: 20) {
            Text(user.name)
                .font(.largeTitle)
            Text(user.email)
                .font(.title3)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
        .navigationTitle("User Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
