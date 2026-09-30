//
//  UserResponse.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct UserResponse: Decodable {
    let users: [User]
}

struct User: Decodable {
    let id: Int
    let firstName: String
}
