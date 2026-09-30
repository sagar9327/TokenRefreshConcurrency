//
//  LoginViewModel.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var username = "emilys"
    @Published var password = "emilyspass"

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoggedIn = false

    let tokenStorage: TokenStorage

    private let networkClient: NetworkClient

    init(
        tokenStorage: TokenStorage,
        networkClient: NetworkClient
    ) {
        self.tokenStorage = tokenStorage
        self.networkClient = networkClient
    }

    func login() async {

        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password are required."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            let request = LoginRequest(
                username: username,
                password: password,
                expiresInMins: 1
            )

            let response: LoginResponse = try await networkClient.post(
                url: "https://dummyjson.com/auth/login",
                body: request
            )

            tokenStorage.save(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            print("✅ Login successful")
            print("Access Token:", response.accessToken)
            print("Refresh Token:", response.refreshToken)

            isLoggedIn = true

        } catch {

            errorMessage = error.localizedDescription

            print("❌ Login failed:", error)
        }
    }
}
