//
//  DashboardView.swift
//  TokenRefreshConcurrency
//
//  Created by Sagar Kalathil on 30/09/26.
//
import SwiftUI

struct DashboardView: View {

    let tokenStorage: TokenStorage
    let networkClient: NetworkClient

    @StateObject private var viewModel: DashboardViewModel

    init(
        networkClient: NetworkClient,
        tokenStorage: TokenStorage
    ) {
        self.networkClient = networkClient
        self.tokenStorage = tokenStorage

        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                networkClient: networkClient
            )
        )
    }

    var body: some View {
        NavigationStack {

            VStack(spacing: 16) {

                if viewModel.isLoading {
                    ProgressView("Loading...")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                List(viewModel.results) { result in

                    HStack {
                        Text(result.name)

                        Spacer()

                        Image(
                            systemName: result.success
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )
                    }
                }

                // MARK: - Refresh Dashboard

                Button {
                    Task {
                        await viewModel.loadDashboard()
                    }
                } label: {
                    Text("Refresh Dashboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // MARK: - Test Concurrent Requests

                Button {
                    Task {
                        await viewModel.testConcurrentRequests()
                    }
                } label: {
                    Text("Test 7 Concurrent Requests")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                // MARK: - Temporary Testing

                Button {
                    tokenStorage.invalidateAccessToken()

                    print("🧪 Access token manually invalidated")
                } label: {
                    Text("Invalidate Access Token")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
}
