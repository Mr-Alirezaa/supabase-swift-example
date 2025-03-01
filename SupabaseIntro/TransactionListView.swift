//
//  TransactionListView.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/10/25.
//

import SwiftUI


// MARK: - Transactions List View

struct TransactionsListView: View {
    // In a real app, this data might come from a ViewModel or network call.
    let transactionList: any TransactionListProtocol

    // Controls presentation of the editor sheet for adding a sheet
    @State private var isAddingTransaction = false

    // Holds the transaction to be edited.
    @State private var transactionToEdit: Transaction? = nil

    // Group transactions by the start of the day.
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: transactionList.transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }

    // Sorted list of dates for section headers (newest dates first).
    private var sortedDates: [Date] {
        groupedTransactions.keys.sorted(by: >)
    }

    init(
        transactionList: any TransactionListProtocol,
        isAddingTransaction: Bool = false,
        transactionToEdit: Transaction? = nil
    ) {
        self.transactionList = transactionList
        self.isAddingTransaction = isAddingTransaction
        self.transactionToEdit = transactionToEdit
    }

    var body: some View {
        List {
            // Display transactions for the specific day.
            ForEach(transactionList.transactions) { transaction in
                TransactionRowView(transaction: transaction)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await transactionList.deleteTransaction(transaction)
                                } catch {
                                    print("Failed to delete transaction due to: \(error)")
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            isAddingTransaction = false
                            transactionToEdit = transaction
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            // Toolbar item for adding a new transaction.
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    transactionToEdit = nil
                    isAddingTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTransaction) {
            TransactionEditorView(
                transaction: nil,
                accountID: transactionList.accountID
            ) { (savedTransaction: Transaction) in
                try await transactionList.insertTransaction(savedTransaction)
            }
        }
        .sheet(item: $transactionToEdit) { transactionToEdit in
            TransactionEditorView(
                transaction: transactionToEdit,
                accountID: transactionList.accountID
            ) { (savedTransaction: Transaction) in
                try await transactionList.updateTransaction(savedTransaction, id: transactionToEdit.id)
            }
        }
        .task {
            do {
                try await transactionList.fetchTransactions()
            } catch {
                print("Failed fetching transactions due to: \(error)")
            }
        }
    }
}

// MARK: - Transaction Row View

/// Displays a single transaction's details.
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top row with category and amount
            HStack {
                Text(transaction.category)
                    .font(.headline)
                Spacer()
                // Format the amount; credit transactions appear in green, debit in red.
                Text("\(transaction.currency) \(transaction.amount.description)")
                    .font(.subheadline)
                    .foregroundColor(transaction.type == .credit ? .green : .red)
            }

            // Optional description
            if let description = transaction.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Display date in a friendly format.
            Text(transaction.date, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    let sampleTransactions = [
        Transaction(
            id: UUID(),
            accountID: UUID(),
            type: .credit,
            amount: 150.0,
            currency: "USD",
            category: "Salary",
            description: "Monthly salary deposit",
            date: Date()
        ),
        Transaction(
            id: UUID(),
            accountID: UUID(),
            type: .debit,
            amount: 50.0,
            currency: "USD",
            category: "Groceries",
            description: "Weekly grocery shopping",
            date: Date()
        ),
        Transaction(
            id: UUID(),
            accountID: UUID(),
            type: .debit,
            amount: 30.0,
            currency: "USD",
            category: "Transport",
            description: "Monthly bus pass",
            date: Date()
        )
    ]

    TransactionsListView(
        transactionList: _TransactionList_Preview(
            transactions: sampleTransactions,
            accountID: UUID()
        )
    )
}
