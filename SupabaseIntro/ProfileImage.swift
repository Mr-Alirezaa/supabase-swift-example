//
//  AvatarImage.swift
//  SupabaseIntro
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
    let image: Image

    init(uiImage: UIImage, image: Image) {
        self.uiImage = uiImage
        self.image = image
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return AvatarImage(uiImage: uiImage, image: image)
        }
    }
}
