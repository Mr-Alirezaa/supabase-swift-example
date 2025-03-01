//
//  TransactionList.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/10/25.
//

import Foundation
import Observation
import Supabase

@MainActor
protocol TransactionListProtocol: Observable {
    var transactions: [Transaction] { get }
    var accountID: UUID { get }

    func fetchTransactions() async throws
    func insertTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction, id: UUID) async throws
    func deleteTransaction(_ transaction: Transaction) async throws

    func makeTransfer(_ tranfser: TransferRequest) async throws
    func observeChanges() async throws
}

@Observable
@MainActor
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

    func makeTransfer(_ transfer: TransferRequest) async throws {
        var transfer = transfer
        transfer.senderAccountID = accountID
        do {
            try await supabase.functions.invoke(
                "transfer",
                options: FunctionInvokeOptions(body: transfer)
            )
        } catch {
            throw ErrorResponse(error: error)
        }
    }

    func observeChanges() async throws {
        let channel = supabase.channel("transaction-changes")

        let changeStream = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "transactions",
            filter: "account_id=eq.\(accountID)"
        )

        await channel.subscribe()

        for await change in changeStream {
            switch change {
            case .delete(let action):
                let transaction = try action.decodeOldRecord(as: Transaction.self)
                self.transactions.removeAll(where: { $0.id == transaction.id })
                
            case .insert(let action):
                let transaction = try action.decodeRecord(as: Transaction.self)
                self.transactions.append(transaction)
                
            case .update(let action):
                let transaction = try action.decodeRecord(as: Transaction.self)
                if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
                    self.transactions[index] = transaction
                }
            }
        }
    }
}

extension HasRecord {
    func decodeRecord<T: Decodable>(as _: T.Type = T.self) throws -> T {
        try record.decode(as: T.self, decoder: PostgrestClient.Configuration.jsonDecoder)
    }
}

extension HasOldRecord {
    func decodeOldRecord<T: Decodable>(as _: T.Type = T.self) throws -> T {
        try oldRecord.decode(as: T.self, decoder: PostgrestClient.Configuration.jsonDecoder)
    }
}

@Observable
@MainActor
class _TransactionList_Preview: TransactionListProtocol {
    var initialTransactions: [Transaction] = []
    var transactions: [Transaction] = []
    let accountID: UUID

    init(transactions: [Transaction], accountID: UUID) {
        self.initialTransactions = transactions
        self.accountID = accountID
    }

    func fetchTransactions() async throws {
        transactions = initialTransactions
    }

    func insertTransaction(_ transaction: Transaction) async throws {

    }

    func updateTransaction(_ transaction: Transaction, id: UUID) async throws {

    }

    func deleteTransaction(_ transaction: Transaction) async throws {

    }

    func makeTransfer(_ tranfser: TransferRequest) async throws {

    }

    func observeChanges() async throws {

    }
}
