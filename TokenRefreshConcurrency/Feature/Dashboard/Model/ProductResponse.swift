//
//  ProductResponse.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import Foundation

struct ProductResponse: Decodable {
    let products: [Product]
}

struct Product: Decodable {
    let id: Int
    let title: String
}
