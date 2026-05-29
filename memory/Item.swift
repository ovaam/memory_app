//
//  Item.swift
//  memory
//
//  Created by Малова Олеся on 13.04.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    // Для CloudKit важно, чтобы у всех свойств было значение "по умолчанию"
    // (или чтобы они были Optional). Так система сможет корректно создавать
    // записи при миграциях/синхронизации.
    var timestamp: Date = Date()
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
