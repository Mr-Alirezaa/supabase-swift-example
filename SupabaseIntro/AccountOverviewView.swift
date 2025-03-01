//
//  AccountOverviewView.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/11/25.
//

import SwiftUI
import PhotosUI
import Supabase

/// Displays the user’s profile (email and profile photo) along with a list of their accounts.
struct AccountOverviewView: View {
    private let accountOverview: any AccountOverviewProtocol
    private let supabase: SupabaseClient

    @State private var selectedPhotoItem: PhotosPickerItem?

    init(supabase: SupabaseClient, accountOverview: any AccountOverviewProtocol) {
        self.accountOverview = accountOverview
        self.supabase = supabase
    }

    var body: some View {
            // Header: Profile photo and email.
            // List of accounts.
        List {
            Section("Profile") {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let avatar = accountOverview.avatar {
                            avatar
                                .resizable()
                                .frame(width: 80, height: 80)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .frame(width: 80, height: 80)
                                .background(.background.secondary)
                                .foregroundStyle(.primary)
                        }
                    }
                    .clipShape(Circle())

                    Text(accountOverview.user.email ?? accountOverview.user.id.uuidString)
                        .font(.title3)
                        .bold()

                    Spacer()
                }
            }

            Section("Accounts") {
                if accountOverview.accounts.isEmpty {
                    Text("No accounts found.")
                        .foregroundStyle(.secondary)

                } else {
                    ForEach(accountOverview.accounts) { account in
                        NavigationLink(value: account) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Account: \(account.id.uuidString.prefix(8))...")
                                        .font(.headline)
                                    Text("Status: \(account.status.rawValue.capitalized)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(account.createdAt, style: .date)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("My Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Log out") {
                    Task { try await supabase.auth.signOut() }
                }
            }
        }
        .navigationDestination(for: Account.self) { account in
            TransactionsListView(
                transactionList: TransactionList(
                    supabase: supabase,
                    accountID: account.id
                )
            )
        }
        .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
            Task {
                self.selectedPhotoItem = nil

                if let item = selectedPhotoItem {
                    if let image = try? await item.loadTransferable(type: AvatarImage.self) {
                        try await accountOverview.saveAvatar(image)
                    }
                }
            }
        }
        .task {
            do {
                try await accountOverview.fetchAccounts()
            } catch {
                print("Failed fetching accounts due to: \(error)")
            }
        }
        .task {
            do {
                try await accountOverview.fetchAvatar()
            } catch {
                print("Failed fetching accounts due to: \(error)")
            }
        }
    }
}
