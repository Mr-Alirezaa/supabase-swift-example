//
//  LoginView.swift
//  SupabaseSwiftExample
//
//  Created by Alireza Asadi on 2/10/25.
//

import SwiftUI
import Supabase

struct LoginView: View {
    // MARK: - State Properties

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            let welcome = Text("Welcome to")
                .font(.body)
                .fontWeight(.bold)
                .fontWidth(.expanded)

            Text("\(welcome)\nSupabase Intro")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontWidth(.expanded)
                .padding(.bottom, 40)
                .multilineTextAlignment(.center)

            Spacer()

            VStack {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                // Display any error messages.
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Loading indicator.
            if isLoading {
                ProgressView()
            }
            
            // Buttons for Sign In and Sign Up
            VStack(spacing: 16) {
                Button {
                    Task { await signIn() }
                } label: {
                    Text("Sign In")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    Task { await signUp() }
                } label: {
                    Text("Sign Up")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Authentication Methods

    /// Signs in the user using Supabase authentication.
    func signIn() async {
        // Validate inputs.
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
    
        isLoading = true
        errorMessage = nil
    
        do {
            // Call Supabase's sign-in method.
            let response = try await supabase.auth.signIn(email: email, password: password)
            print("Sign in successful: \(response)")
            // On success, you might transition to the main app view.
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    
        isLoading = false
    }
    
    /// Signs up the user using Supabase authentication.
    func signUp() async {
        // Validate inputs.
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
    
        isLoading = true
        errorMessage = nil
    
        do {
            // Call Supabase's sign-up method.
            let response = try await supabase.auth.signUp(email: email, password: password)
            print("Sign up successful: \(response)")
            // You may opt to sign in automatically or instruct the user to verify their email.
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
    
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    LoginView(supabase: SupabaseClient(supabaseURL: URL(string: "")!, supabaseKey: ""))
}
