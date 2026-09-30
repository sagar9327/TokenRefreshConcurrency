//
//  LoginRequest.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation
struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let id: Int
    let username: String
    let email: String
}
