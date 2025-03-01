//
//  TransactionList.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/10/25.
//

import Foundation
import Observation
import Supabase

protocol TransactionListProtocol: Observable {
    var transactions: [Transaction] { get }
    var accountID: UUID { get }

    func fetchTransactions() async throws
    func insertTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction, id: UUID) async throws
    func deleteTransaction(_ transaction: Transaction) async throws
}

@Observable
class TransactionList: TransactionListProtocol {
    @ObservationIgnored
    var supabase: SupabaseClient

    var transactions: [Transaction] = []
    let accountID: UUID

    init(supabase: SupabaseClient, accountID: UUID) {
        self.supabase = supabase
        self.accountID = accountID
    }

    func fetchTransactions() async throws {
        transactions = try await supabase.from("transactions")
            .select()
            .eq("account_id", value: accountID)
            .execute()
            .value
    }

    func insertTransaction(_ transaction: Transaction) async throws {
        var transaction = transaction
        transaction.accountID = accountID
        let insertedTransaction: Transaction = try await supabase.from("transactions")
            .insert(transaction)
            .select()
            .single()
            .execute()
            .value

        transactions.append(insertedTransaction)
    }

    func updateTransaction(_ transaction: Transaction, id: UUID) async throws {
        let updatedTransaction: Transaction = try await supabase
            .from("transactions")
            .update(transaction)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value

        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index] = updatedTransaction
        } else {
            transactions.append(updatedTransaction)
        }
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        try await supabase
            .from("transactions")
            .delete()
            .eq("id", value: transaction.id)
            .execute()

        transactions.removeAll(where: { $0.id == transaction.id })
    }
}
