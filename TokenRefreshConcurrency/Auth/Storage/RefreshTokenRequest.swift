//
//  RefreshTokenRequest.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
    let expiresInMins: Int
}
