//
//  SupabaseSwiftExampleApp.swift
//  SupabaseSwiftExample
//
//  Created by Alireza Asadi on 2/9/25.
//

import SwiftUI
import Supabase

@main
struct SupabaseSwiftExampleApp: App {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://\(Bundle.main.supabaseProjectID).supabase.co")!,
        supabaseKey: Bundle.main.supabaseAnonKey
    )

    var body: some Scene {
        WindowGroup {
            RootView(supabase: supabase)
        }
    }
}
