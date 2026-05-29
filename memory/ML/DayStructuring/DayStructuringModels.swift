import Foundation

struct DayStructureResult {
    var events: [DraftEvent]
    var clarifications: [DayClarification]
}

struct DayClarification: Identifiable, Equatable {
    let id: UUID
    let kind: Kind
    let eventId: UUID
    let prompt: String
    var relatedEventId: UUID?

    enum Kind: Equatable {
        case missingTime
        case orderBetweenTwo
    }

    init(
        id: UUID = UUID(),
        kind: Kind,
        eventId: UUID,
        prompt: String,
        relatedEventId: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.eventId = eventId
        self.prompt = prompt
        self.relatedEventId = relatedEventId
    }
}

struct ParsedDaySegment {
    var text: String
    var time: Date?
    var sourceOrder: Int
}
