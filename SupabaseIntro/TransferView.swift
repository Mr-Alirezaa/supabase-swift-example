//
//  TransferView.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/17/25.
//

import SwiftUI

struct TransferView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var amount: Double = 0
    @State private var currency: String = "USD"
    @State private var category: String = "Transfer"
    @State private var descriptionText: String = ""

    @State private var isTransfering: Bool = false
    @State private var errorMessage: String?

    private let accountID: UUID
    private var makeTransfer: (TransferRequest) async throws -> Void

    init(accountID: UUID, makeTransfer: @escaping (TransferRequest) async throws -> Void) {
        self.accountID = accountID
        self.makeTransfer = makeTransfer
    }

    var body: some View {
        NavigationStack {
            Form {
                // Recipient email.
                Section(header: Text("Recipient")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                // Transfer details.
                Section {
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Currency", text: $currency)
                    TextField("Category (Optional)", text: $category)
                    TextField("Description (Optional)", text: $descriptionText)
                } header: {
                    Text("Transfer Details")
                }

                // Show error message if any.
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    if isTransfering {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            Task {
                                await performTransfer()
                            }
                        } label: {
                            Text("Transfer")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isTransfering)
                    }
                }
                .padding()
            }
            .navigationTitle("Transfer")
        }
        .interactiveDismissDisabled(isTransfering)
    }

    /// Validates the input and encodes the transfer data as JSON.
    func performTransfer() async {
        // Validate that amount is a valid number.
        guard !email.isEmpty else {
            errorMessage = "Please enter a email for recepient."
            return
        }

        guard amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        guard currency.count == 3 else {
            errorMessage = "Please enter a 3-letter currency code."
            return
        }

        // Create the transfer body.
        let transfer = TransferRequest(
            originAccount: accountID,
            targetUserEmail: email,
            amount: amount,
            currency: currency,
            category: category,
            description: descriptionText.isEmpty ? nil : descriptionText
        )

        // Encode transfer as JSON and print to the console.
        do {
            isTransfering = true
            try await makeTransfer(transfer)
            dismiss()
        } catch let error as ErrorResponse {
            errorMessage = "Error \(error.code), \(error.message)"
        } catch {
            errorMessage = "Failed to transfer: unexpected error"

        }
        isTransfering = false
    }
}

#Preview {
    TransferView(accountID: UUID()) { _ in }
}
