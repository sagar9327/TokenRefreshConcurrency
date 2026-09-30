//
//  TokenManager.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

actor TokenManager {

    private let tokenStorage: TokenStorage
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private var refreshTask: Task<String, Error>?

    init(
        tokenStorage: TokenStorage,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.tokenStorage = tokenStorage
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - Access Token

    func accessToken() -> String? {
        tokenStorage.accessToken
    }

    // MARK: - Refresh Access Token

    func refreshAccessToken() async throws -> String {

        // Someone is already refreshing the token.
        if let refreshTask {

            print("⏳ Waiting for existing token refresh")

            return try await refreshTask.value
        }

        print("🔄 Starting token refresh")

        let task = Task<String, Error> {

            guard let refreshToken = tokenStorage.refreshToken else {
                throw NetworkError.invalidResponse
            }

            let requestBody = RefreshTokenRequest(
                refreshToken: refreshToken,
                expiresInMins: 1
            )

            guard let url = URL(
                string: "https://dummyjson.com/auth/refresh"
            ) else {
                throw NetworkError.invalidURL
            }

            var request = URLRequest(url: url)

            request.httpMethod = "POST"

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.httpBody = try encoder.encode(requestBody)

            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(
                    httpResponse.statusCode
                )
            }

            let refreshResponse =
                try decoder.decode(
                    RefreshTokenResponse.self,
                    from: data
                )

            tokenStorage.save(
                accessToken: refreshResponse.accessToken,
                refreshToken: refreshResponse.refreshToken
            )

            print("✅ Token refresh successful")

            return refreshResponse.accessToken
        }

        refreshTask = task

        do {

            let accessToken = try await task.value

            refreshTask = nil

            return accessToken

        } catch {

            refreshTask = nil

            throw error
        }
    }
}
