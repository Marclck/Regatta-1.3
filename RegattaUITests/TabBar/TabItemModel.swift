//
//  TabItemModel.swift
//  Regatta
//
//  Created by Chikai Lai on 21/12/2024.
//

import Foundation
import SwiftUI

struct TabItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
}
