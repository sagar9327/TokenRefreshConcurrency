//
//  Untitled.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
