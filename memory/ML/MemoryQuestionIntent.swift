import Foundation

enum MemoryQuestionIntent: String, CaseIterable, Sendable {
    case didDo
    case whenDid
    case whatDid
    case howMany
    case search
}

struct MemoryQueryResult: Identifiable, Sendable {
    let id = UUID()
    let question: String
    let intent: MemoryQuestionIntent
    let activityTerms: [String]
    let matches: [MemoryIndexedEvent]
    let answer: String
}

struct MemoryIndexedEvent: Identifiable, Sendable {
    let id: UUID
    let dayStart: Date
    let eventTime: Date?
    let text: String
    let normalizedText: String
}
