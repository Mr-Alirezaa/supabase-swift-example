//
//  SupabaseIntroApp.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 2/9/25.
//

import SwiftUI
import Supabase

@main
struct SupabaseIntroApp: App {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://zwxeklzyemumdxrkfwjx.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3eGVrbHp5ZW11bWR4cmtmd2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyNjIwNDgsImV4cCI6MjA1NDgzODA0OH0.tO8AcouWmrLZOPya9IrqC8Iefs5FVgeI7Agsh-2-vSk"
    )

    var body: some Scene {
        WindowGroup {
            RootView(supabase: supabase)
        }
    }
}
