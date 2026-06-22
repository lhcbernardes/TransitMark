//
//  Item.swift
//  TransitMark
//
//  Created by Leandro Henrique Cavalcanti Bernardes on 22/06/26.
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
