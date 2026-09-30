//
//  PostResposne.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct PostResponse: Decodable {
    let posts: [Post]
}

struct Post: Decodable {
    let id: Int
    let title: String
}
