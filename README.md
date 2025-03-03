# Supabase Swift Example

A SwiftUI app, showcasing usage of Supabase with examples of using auth, database, edge-functions, storage and realtime.

## Introduction

This example app demonstrates how to integrate Supabase with a SwiftUI application. It covers several key Supabase features:

- **Authentication**, to sign up and sign in users with email and password.
- **Database** to handle showing list of accounts and showing and operating on the list of transactions associated to an account.
- **Edge Functions** to make a transfer, it actually create 2 transactions on sender and recipient accounts.
- **Storage** to store user's profile photo.
- **Realtime** to track changes in the list of user's transactions.

## Prerequisites

Before running this example, you'll need:

1. A Supabase account (sign up at [supabase.com](https://supabase.com) if you don't have one)
2. A Supabase project created in your account
3. Configuration of your Supabase project details in the app

## Setup

1. Clone this repository
2. Open the project in Xcode
3. Locate the `Supabase.xcconfig` file and update it with your Supabase project credentials from [Data API Configurations](https://supabase.com/dashboard/project/_/settings/api):
   ```
   SUPABASE_PROJECT_ID=<your-project-id>
   SUPABASE_ANON_KEY=<your-anon-key>
   ```
4. Make sure your Supabase project has the necessary tables and configurations described in the [Models.swift](/SupabaseSwiftExample/Models.swift) file. \
There are also example data provided. You can run all SQLs in the Supabase SQL Editor.
5. Use Supabase [Local Development & CLI](https://supabase.com/docs/guides/local-development) document to install Supabase CLI on your machine.
6. Use [Deploy to Production](https://supabase.com/docs/guides/functions/deploy) guide from edge functions to deploy transfer function to your Supabase project.
7. You will need to define a Postgres function as described in [transfer function](/supabase/functions/transfer/index.ts#l62) in order to find transfer's recipient user by their email address. (This is required because Supabase does not allow you to run queries on protected schemas, including auth schema.)
8. Create a public bucket named "avatars".
9. As per Supabase's requirements, you need to setup RLS policy for the said bucket to control access to the files in the bucket. Create a policy for the avatars bucket, select all operations to allow all. Use the following as the policy definition.
    ```sql
    (bucket_id = 'avatars') AND (auth.role() = 'authenticated')
    ```
10. Lastly, make sure to use [RLS policies](https://supabase.com/docs/guides/database/postgres/row-level-security) and other security measurements to keep access to your supabase project safe. Always check [security advisor](https://supabase.com/dashboard/project/_/advisors/security) for warnings and errors.

You are now ready to use the App with the Supabase.

## Supabase Codes

For the examples on how to use supabase features, see the following files.

### Database

The following files, and the specified functions, contain simple examples on how to use databases in Supabase.

#### [TransactionList.swift](/SupabaseSwiftExample/TransactionList.swift)

```swift
class TransactionList: TransactionListProtocol {
    var supabase: SupabaseClient

    // ...

    func fetchTransactions() async throws

    func insertTransaction(_ transaction: Transaction) async throws 

    func updateTransaction(_ transaction: Transaction, id: UUID) async throws

    func deleteTransaction(_ transaction: Transaction) async throws 

    // ...
}
```

#### [AccountOverview.swift](/SupabaseSwiftExample/AccountOverview.swift)

```swift
class AccountOverview: AccountOverviewProtocol {
    var supabase: SupabaseClient

    // ...

    func fetchAccounts() async throws

    // ...
}
```

### Edge Function

#### [TransactionList.swift](/SupabaseSwiftExample/TransactionList.swift)

```swift
class TransactionList: TransactionListProtocol {
    var supabase: SupabaseClient

    // ...

    func makeTransfer(_ transfer: TransferRequest) async throws

    // ...
}
```

### Storage

#### [AccountOverview.swift](/SupabaseSwiftExample/AccountOverview.swift)

```swift
class AccountOverview: AccountOverviewProtocol {
    var supabase: SupabaseClient

    // ...

    func fetchAvatar() async throws

    func saveAvatar(_ image: AvatarImage) async throws
}
```

### Realtime

#### [TransactionList.swift](/SupabaseSwiftExample/TransactionList.swift)

```swift
class TransactionList: TransactionListProtocol {
    var supabase: SupabaseClient

    // ...

    func observeChanges() async throws
}
```

### Auth

#### [LoginView.swift](/SupabaseSwiftExample/LoginView.swift)

```swift
struct LoginView: View {
    // ...

    func signIn() async
    
    func signUp() async
}
```