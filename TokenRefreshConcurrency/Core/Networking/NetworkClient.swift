//
//  Untitled.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation
final class NetworkClient {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenManager: TokenManager

    init(
        tokenManager: TokenManager,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.tokenManager = tokenManager
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - GET

    func get<T: Decodable>(
        url: String,
        headers: [String: String] = [:]
    ) async throws -> T {

        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        addHeaders(headers, to: &request)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - POST

    func post<T: Decodable, Body: Encodable>(
        url: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {

        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        addHeaders(headers, to: &request)

        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Authenticated GET

    func authenticatedGet<T: Decodable>(
        url: String,
        isRetry: Bool = false
    ) async throws -> T {

        guard let accessToken = await tokenManager.accessToken() else {
            throw NetworkError.invalidResponse
        }

        do {

            return try await get(
                url: url,
                headers: authorizationHeader(accessToken)
            )

        } catch NetworkError.httpError(401) {

            // Prevent an infinite refresh → retry → 401 loop.
            if isRetry {
                print("❌ Request still unauthorized after token refresh")
                throw NetworkError.httpError(401)
            }

            print("⚠️ Access token expired")

            let newAccessToken =
                try await tokenManager.refreshAccessToken()

            print("🔄 Retrying request with new access token")

            return try await authenticatedGet(
                url: url,
                isRetry: true
            )
        }
    }

    // MARK: - Helpers

    private func authorizationHeader(
        _ accessToken: String
    ) -> [String: String] {

        [
            "Authorization": "Bearer \(accessToken)"
        ]
    }

    private func validateResponse(
        _ response: URLResponse
    ) throws {

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(
                httpResponse.statusCode
            )
        }
    }

    private func addHeaders(
        _ headers: [String: String],
        to request: inout URLRequest
    ) {

        for (key, value) in headers {
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }
    }
}
