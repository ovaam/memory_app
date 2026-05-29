import Foundation
import SwiftData

@Model
final class MemoryDay {
    @Attribute(.unique) var dayStart: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MemoryEvent.day)
    var events: [MemoryEvent] = []

    init(dayStart: Date) {
        self.dayStart = dayStart
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class MemoryEvent {
    var id: UUID = UUID()
    var order: Int = 0
    var time: Date?
    var text: String = ""

    @Relationship(deleteRule: .cascade, inverse: \MemoryAttachment.event)
    var attachments: [MemoryAttachment] = []

    @Relationship var day: MemoryDay?

    init(order: Int, time: Date? = nil, text: String) {
        self.order = order
        self.time = time
        self.text = text
    }
}

@Model
final class MemoryAttachment {
    var id: UUID = UUID()
    var imageData: Data?

    @Relationship var event: MemoryEvent?

    init(imageData: Data?) {
        self.imageData = imageData
    }
}
