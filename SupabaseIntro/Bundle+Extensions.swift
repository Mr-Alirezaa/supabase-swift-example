//
//  Bundle+Extensions.swift
//  SupabaseIntro
//
//  Created by Alireza Asadi on 3/1/25.
//

import Foundation

extension Bundle {
    var supabaseProjectID: String {
        guard let value = infoDictionary?["SupabaseProjectID"] as? String, !value.isEmpty else {
            fatalError("""
                Value for key `SupabaseProjectID` is not set in Info.plist or is invalid.
                Either set it in Info.plist or in Supabase.xcconfig, provide the value for key `SUPABASE_PROJECT_ID`.
                """)
        }
        return value
    }

    var supabaseAnonKey: String {
        guard let value = infoDictionary?["SupabaseAnonKey"] as? String, !value.isEmpty else {
            fatalError("""
                Value for key `SupabaseAnonKey` is not set in Info.plist or is invalid.
                Either set it in Info.plist or in Supabase.xcconfig, provide the value for key `SUPABASE_ANON_KEY`.
                """)
        }
        return value
    }
}
