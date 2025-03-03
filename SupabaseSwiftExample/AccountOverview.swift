//
//  AccountOverview.swift
//  SupabaseSwiftExample
//
//  Created by Alireza Asadi on 2/11/25.
//

import Foundation
import Supabase
import Observation
import UIKit.UIImage
import SwiftUI

@MainActor
protocol AccountOverviewProtocol: Observable {
    var accounts: [Account] { get }
    var user: User { get }
    var avatar: Image? { get }

    func fetchAccounts() async throws
    func fetchAvatar() async throws
    func saveAvatar(_ image: AvatarImage) async throws
}

@Observable
@MainActor
class AccountOverview: AccountOverviewProtocol {
    @ObservationIgnored
    var supabase: SupabaseClient

    var accounts: [Account] = []
    var user: User
    var avatar: Image?

    init(supabase: SupabaseClient, user: User) {
        self.supabase = supabase
        self.user = user
    }

    func fetchAccounts() async throws {
        self.accounts = try await supabase.from("accounts")
            .select()
            .execute()
            .value
    }

    func fetchAvatar() async throws {
        let avatarData = try await supabase.storage
            .from("avatars")
            .download(path: "\(user.id)/avatar.png")

        avatar = UIImage(data: avatarData).map(Image.init(uiImage:))
    }

    func saveAvatar(_ image: AvatarImage) async throws {
        let resizedImage = await image.uiImage.byPreparingThumbnail(ofSize: CGSize(width: 1024, height: 1024))
        guard let resizedImage, let pngData = resizedImage.pngData() else { return }
        try await supabase.storage
            .from("avatars")
            .upload(
                "\(user.id)/avatar.png",
                data: pngData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/png",
                    upsert: true
                )
            )

        avatar = Image(uiImage: resizedImage)
    }
}
