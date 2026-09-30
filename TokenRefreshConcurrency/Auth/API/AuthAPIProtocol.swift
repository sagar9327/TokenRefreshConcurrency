//
//  AuthAPIProtocol.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation
protocol AuthAPIProtocol {

    func login(
        username: String,
        password: String,
        expiresInMins: Int
    ) async throws -> LoginResponse

    func refreshToken(
        refreshToken: String
    ) async throws -> LoginResponse
}
