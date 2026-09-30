//
//  TokenStorage.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

final class TokenStorage {

    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    func save(
        accessToken: String,
        refreshToken: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func invalidateAccessToken() {
        accessToken = "asdf"
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}
