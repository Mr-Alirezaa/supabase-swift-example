//
//  TransactionInfo.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/9/25.
//

import Foundation

/// Transaction Type
///
/// Create the custom enum for transaction types
///
/// ```sql
/// CREATE TYPE transaction_type AS ENUM ('credit', 'debit');
/// ```
enum TransactionType: String, Codable, Hashable {
    case credit
    case debit
}

/// Account Status
///
/// Create the custom enum for account statuses
///
/// ```sql
/// CREATE TYPE account_status AS ENUM ('open', 'restricted', 'closed');
/// ```
enum AccountStatus: String, Codable, Hashable {
    case open
    case restricted
    case closed
}

/// Account Model
///
/// Create the accounts table:
///
/// ```sql
/// CREATE TABLE accounts (
///     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
///     user_id UUID NOT NULL,
///     created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
///     status account_status NOT NULL
/// );
/// ```
///
/// Insert a sample account for a user.
/// Replace the user_id with an actual UUID from your auth system if needed.
///
/// ```sql
/// INSERT INTO accounts (id, user_id, created_at, status)
/// VALUES (
///     '11111111-1111-1111-1111-111111111111',
///     '22222222-2222-2222-2222-222222222222',
///     now(),
///     'open'
/// );
/// ```
struct Account: Codable, Hashable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case userID = "user_id"
        case createdAt = "created_at"
        case status = "status"
    }

    let id: UUID
    let userID: UUID
    let createdAt: Date
    let status: AccountStatus
}

/// Transaction Model
///
/// Create the transactions table:
///
/// ```
/// CREATE TABLE transactions (
///     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
///     account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
///     type transaction_type NOT NULL,
///     amount NUMERIC(10,2) NOT NULL,  -- Adjust precision as needed
///     currency VARCHAR(3) NOT NULL,   -- Assuming ISO currency codes (e.g., 'USD')
///     category TEXT NOT NULL,
///     description TEXT,
///     date TIMESTAMPTZ NOT NULL
/// );
/// ```
///
/// Insert sample transactions for the created account:
///
/// ```sql
/// INSERT INTO transactions (id, account_id, type, amount, currency, category, description, date)
/// VALUES
/// (
///     'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
///     '11111111-1111-1111-1111-111111111111',
///     'credit',
///     150.00,
///     'USD',
///     'Salary',
///     'Monthly salary deposit',
///     now()
/// ),
/// (
///     'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
///     '11111111-1111-1111-1111-111111111111',
///     'debit',
///     50.00,
///     'USD',
///     'Groceries',
///     'Weekly grocery shopping',
///     now()
/// ),
/// (
///     'cccccccc-cccc-cccc-cccc-cccccccccccc',
///     '11111111-1111-1111-1111-111111111111',
///     'debit',
///     30.00,
///     'USD',
///     'Transport',
///     'Monthly bus pass',
///     now()
/// );
/// ```
struct Transaction: Codable, Identifiable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case accountID = "account_id"
        case type = "type"
        case amount = "amount"
        case currency = "currency"
        case category = "category"
        case description = "description"
        case date = "date"
    }

    var id: UUID
    var accountID: UUID
    var type: TransactionType
    var amount: Decimal
    var currency: String
    var category: String
    var description: String?
    var date: Date
}
