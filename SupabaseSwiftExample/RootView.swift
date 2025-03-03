//
//  RootView.swift
//  SupabaseSwiftExample
//
//  Created by Alireza Asadi on 2/9/25.
//

import SwiftUI
import Supabase

struct RootView: View {
    let supabase: SupabaseClient

    @State var session: Session?

    @State var isLoading: Bool = true

    init(supabase: SupabaseClient, session: Session? = nil) {
        self.supabase = supabase
        self.session = session
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()

            } else if let session {
                NavigationStack {
                    AccountOverviewView(
                        supabase: supabase,
                        accountOverview: AccountOverview(
                            supabase: supabase,
                            user: session.user
                        )
                    )
                }
            } else {
                LoginView(supabase: supabase)
            }
        }
        .task {
            await checkCurrentSession()
            isLoading = false
        }
        .task {
            for await (event, _) in supabase.auth.authStateChanges where [.signedIn, .signedOut].contains(event) {
                await checkCurrentSession()
            }
        }
    }

    nonisolated private func checkCurrentSession() async {
        do {
            let session = try await supabase.auth.session
            await setSession(session)
        } catch {
            print("checkCurrentSession failed: \(error)")
            await setSession(nil)
        }
    }

    private func setSession(_ session: Session?) {
        self.session = session
    }
}

#Preview {
    RootView(supabase: SupabaseClient(supabaseURL: URL(string: "")!, supabaseKey: ""))
}
