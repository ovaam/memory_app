import Foundation

struct DraftDay: Identifiable {
    let id = UUID()
    var dayStart: Date
    var events: [DraftEvent]

    init(dayStart: Date, events: [DraftEvent] = []) {
        self.dayStart = dayStart
        self.events = events
    }
}

struct DraftEvent: Identifiable, Equatable {
    let id: UUID
    var time: Date?
    var text: String
    var attachments: [DraftAttachment]

    init(id: UUID = UUID(), time: Date? = nil, text: String = "", attachments: [DraftAttachment] = []) {
        self.id = id
        self.time = time
        self.text = text
        self.attachments = attachments
    }
}

struct DraftAttachment: Identifiable, Equatable {
    let id: UUID
    var imageData: Data?

    init(id: UUID = UUID(), imageData: Data?) {
        self.id = id
        self.imageData = imageData
    }
}

