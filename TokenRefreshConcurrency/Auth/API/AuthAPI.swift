//
//  AuthAPIProtocol.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

final class AuthAPI: AuthAPIProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(
        username: String,
        password: String,
        expiresInMins: Int
    ) async throws -> LoginResponse {

        let url = URL(
            string: "https://dummyjson.com/auth/login"
        )!

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = LoginRequest(
            username: username,
            password: password,
            expiresInMins: expiresInMins
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(
            LoginResponse.self,
            from: data
        )
    }

    func refreshToken(
        refreshToken: String
    ) async throws -> LoginResponse {

        let url = URL(
            string: "https://dummyjson.com/auth/refresh"
        )!

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = [
            "refreshToken": refreshToken,
            "expiresInMins": 1
        ] as [String : Any]

        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        let (data, response) = try await session.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(
            LoginResponse.self,
            from: data
        )
    }
}
