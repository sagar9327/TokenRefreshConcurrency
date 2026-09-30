//
//  DashboardViewModel.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published private(set) var results: [DashboardResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    // MARK: - Load Dashboard

    func loadDashboard() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            let user: CurrentUserResponse =
                try await networkClient.authenticatedGet(
                    url: "https://dummyjson.com/auth/me"
                )

            results = [
                DashboardResult(
                    id: user.id,
                    name: "Welcome \(user.firstName) \(user.lastName)",
                    success: true
                ),

                DashboardResult(
                    id: 2,
                    name: "Username: \(user.username)",
                    success: true
                ),

                DashboardResult(
                    id: 3,
                    name: "Email: \(user.email)",
                    success: true
                )
            ]

            print("✅ Dashboard loaded")

        } catch {

            errorMessage = error.localizedDescription

            print("❌ Dashboard failed:", error)
        }
    }

    // MARK: - Test Concurrent Requests

    func testConcurrentRequests() async {

        print("🚀 Starting 7 concurrent requests")

        async let user1: CurrentUserResponse = fetchUser()
        async let user2: CurrentUserResponse = fetchUser()
        async let user3: CurrentUserResponse = fetchUser()
        async let user4: CurrentUserResponse = fetchUser()
        async let user5: CurrentUserResponse = fetchUser()
        async let user6: CurrentUserResponse = fetchUser()
        async let user7: CurrentUserResponse = fetchUser()

        do {

            let users = try await (
                user1,
                user2,
                user3,
                user4,
                user5,
                user6,
                user7
            )

            print("✅ All 7 requests completed")

            print("User 1:", users.0.username)
            print("User 2:", users.1.username)
            print("User 3:", users.2.username)
            print("User 4:", users.3.username)
            print("User 5:", users.4.username)
            print("User 6:", users.5.username)
            print("User 7:", users.6.username)

        } catch {

            print("❌ Concurrent request failed:", error)
        }
    }

    // MARK: - Fetch User

    private func fetchUser() async throws -> CurrentUserResponse {

        try await networkClient.authenticatedGet(
            url: "https://dummyjson.com/auth/me"
        )
    }
}
