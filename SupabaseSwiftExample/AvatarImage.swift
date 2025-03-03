//
//  AvatarImage.swift
//  SupabaseSwiftExample
//
//  Created by Alireza Asadi on 2/11/25.
//

import CoreTransferable
import UIKit
import SwiftUI

struct AvatarImage: Transferable {
    enum TransferError: Error {
        case importFailed
    }

    let uiImage: UIImage

    init(uiImage: UIImage) {
        self.uiImage = uiImage
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return AvatarImage(uiImage: uiImage)
        }
    }
}
