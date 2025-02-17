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
        supabaseURL: URL(string: "https://\(Bundle.main.infoDictionary!["SupabaseProjectID"]! as! String).supabase.co")!,
        supabaseKey: Bundle.main.infoDictionary!["SupabaseAnonKey"]! as! String
    )

    var body: some Scene {
        WindowGroup {
            RootView(supabase: supabase)
        }
    }
}
