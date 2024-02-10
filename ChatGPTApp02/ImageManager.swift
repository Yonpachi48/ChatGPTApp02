//
//  ImageManager.swift
//  ChatGPTApp02
//
//  Created by Yudai Takahashi on 2023/11/28.
//

import Foundation
import UIKit

func fetchImage(from url: URL) async throws -> UIImage? {
    let (data, _) = try await URLSession.shared.data(from: url)
    return UIImage(data: data)
}
