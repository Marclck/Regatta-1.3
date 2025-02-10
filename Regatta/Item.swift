//
//  Item.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
