//
//  LoginRequest.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
    let expiresInMins: Int
}
