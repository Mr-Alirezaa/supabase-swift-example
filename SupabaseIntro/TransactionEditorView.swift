//
//  TransactionEditorView.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/10/25.
//

import SwiftUI

/// A view that allows the user to create a new transaction or edit an existing one.
struct TransactionEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    // Editable fields.
    @State private var type: TransactionType
    @State private var category: String
    @State private var descriptionText: String
    @State private var amountText: String
    @State private var currency: String
    @State private var date: Date

    @State private var isLoading: Bool = false

    /// The transaction being edited (if any). For new transactions, this is nil.
    let transaction: Transaction?
    
    /// For a new transaction, provide the accountID from the current context.
    let accountID: UUID?
    
    /// Called when the user taps Save.
    var onSave: (Transaction) async throws -> Void

    /// Initializes the editor view.
    /// - Parameters:
    ///   - transaction: The transaction to edit. If nil, the view is used to create a new transaction.
    ///   - accountID: For a new transaction, provide the accountID.
    ///   - onSave: Callback with the saved transaction.
    init(transaction: Transaction? = nil, accountID: UUID? = nil, onSave: @escaping (Transaction) async throws -> Void) {
        self.transaction = transaction
        self.accountID = accountID
        
        // Initialize state values from the transaction if available, otherwise use default values.
        _type = State(initialValue: transaction?.type ?? .credit)
        _category = State(initialValue: transaction?.category ?? "")
        _descriptionText = State(initialValue: transaction?.description ?? "")
        _amountText = State(initialValue: transaction != nil ? "\(transaction!.amount)" : "")
        _currency = State(initialValue: transaction?.currency ?? "USD")
        _date = State(initialValue: transaction?.date ?? Date())
        
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Transaction Details Section
                Section(header: Text("Transaction Details")) {
                    Picker("Type", selection: $type) {
                        Text("Credit").tag(TransactionType.credit)
                        Text("Debit").tag(TransactionType.debit)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Category", text: $category)
                    
                    // Using a regular text field for description.
                    TextField("Description", text: $descriptionText)
                }
                
                // MARK: Amount & Currency Section
                Section(header: Text("Amount & Currency")) {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Currency", text: $currency)
                }
                
                // MARK: Date Section
                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                }
            }
            .disabled(isLoading)
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                // Cancel button dismisses the view.
                if !isLoading {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                // Save button validates the data and passes the new/updated transaction back.
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveTransaction()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isLoading)
        }
    }
    
    /// Validates and creates the transaction object, then calls the onSave callback.
    private func saveTransaction() {
        // Convert the amount text to a Decimal.
        guard let decimalAmount = Decimal(string: amountText) else {
            return
        }
        
        // Use the existing transaction id if editing; otherwise, generate a new UUID.
        let transactionID = transaction?.id ?? UUID()
        // For new transactions, use the provided accountID, or fall back on an existing one.
        let accID = transaction?.accountID ?? accountID ?? UUID()
        
        let newTransaction = Transaction(
            id: transactionID,
            accountID: accID,
            type: type,
            amount: decimalAmount,
            currency: currency,
            category: category,
            description: descriptionText.isEmpty ? nil : descriptionText,
            date: date
        )

        Task {
            do {
                isLoading = true
                try await onSave(newTransaction)
                dismiss()
            } catch {
                print("Error saving transaction: \(error)")
            }
            
            isLoading = false
        }
    }
}

#Preview {
    TransactionEditorView { transaction in
        print("New Transaction Saved: \(transaction)")
    }
}

#Preview {
    TransactionEditorView(
        transaction: Transaction(
            id: UUID(),
            accountID: UUID(),
            type: .debit,
            amount: Decimal(75.50),
            currency: "USD",
            category: "Utilities",
            description: "Electricity bill",
            date: Date()
        )
    ) { transaction in
        print("Edited Transaction Saved: \(transaction)")
    }
}
