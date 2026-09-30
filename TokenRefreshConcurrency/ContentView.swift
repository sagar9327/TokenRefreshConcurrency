//
//  ContentView.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var loginViewModel: LoginViewModel

    private let tokenStorage: TokenStorage
    private let tokenManager: TokenManager
    private let networkClient: NetworkClient

    init() {

        let tokenStorage = TokenStorage()

        let tokenManager = TokenManager(
            tokenStorage: tokenStorage
        )

        let networkClient = NetworkClient(
            tokenManager: tokenManager
        )

        self.tokenStorage = tokenStorage
        self.tokenManager = tokenManager
        self.networkClient = networkClient

        _loginViewModel = StateObject(
            wrappedValue: LoginViewModel(
                tokenStorage: tokenStorage,
                networkClient: networkClient
            )
        )
    }

    var body: some View {

        if loginViewModel.isLoggedIn {

            DashboardView(
                networkClient: networkClient,
                tokenStorage: tokenStorage
            )

        } else {

            LoginView(
                viewModel: loginViewModel
            )
        }
    }
}
