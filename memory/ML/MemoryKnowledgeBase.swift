import Foundation
import NaturalLanguage
import SwiftData

@MainActor
final class MemoryKnowledgeBase {
    static let shared = MemoryKnowledgeBase()

    private(set) var events: [MemoryIndexedEvent] = []
    private var embedding: NLEmbedding?

    private init() {
        embedding = NLEmbedding.wordEmbedding(for: .russian)
            ?? NLEmbedding.wordEmbedding(for: .english)
    }

    func rebuild(from days: [MemoryDay]) {
        var indexed: [MemoryIndexedEvent] = []
        indexed.reserveCapacity(days.reduce(0) { $0 + $1.events.count })

        for day in days {
            let dayStart = Calendar.current.startOfDay(for: day.dayStart)
            for event in day.events {
                let text = event.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                indexed.append(
                    MemoryIndexedEvent(
                        id: event.id,
                        dayStart: dayStart,
                        eventTime: event.time,
                        text: text,
                        normalizedText: Self.normalize(text)
                    )
                )
            }
        }

        events = indexed.sorted { $0.dayStart > $1.dayStart }
    }

    func search(activityTerms: [String], limit: Int = 12) -> [MemoryIndexedEvent] {
        guard !events.isEmpty else { return [] }

        let terms = activityTerms
            .map { Self.normalize($0) }
            .filter { !$0.isEmpty }

        if terms.isEmpty {
            return Array(events.prefix(limit))
        }

        let scored: [(MemoryIndexedEvent, Double)] = events.map { event in
            (event, Self.score(event: event, terms: terms, embedding: embedding))
        }

        return scored
            .filter { $0.1 > 0.08 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    static func extractActivityTerms(from question: String) -> [String] {
        let lower = question.lowercased()
        var cleaned = lower

        let patterns = [
            #"делал\s+ли\s+я\s+"#,
            #"делала\s+ли\s+я\s+"#,
            #"когда\s+я\s+"#,
            #"что\s+я\s+"#,
            #"сколько\s+раз\s+я\s+"#,
            #"я\s+"#,
            #"ли\s+"#,
            #"вчера\s+"#,
            #"сегодня\s+"#,
        ]
        for p in patterns {
            cleaned = cleaned.replacingOccurrences(of: p, with: " ", options: .regularExpression)
        }

        let stop: Set<String> = [
            "делал", "делала", "делали", "был", "была", "были", "когда", "где", "что", "как",
            "ли", "я", "мы", "ты", "он", "она", "это", "в", "на", "и", "или", "не", "нет",
            "да", "про", "мой", "моя", "мои", "раз", "сколько", "память", "memory", "ask",
            "your", "the", "a", "an", "did", "do", "when", "was", "were", "have", "has",
        ]

        let tokens = normalize(cleaned)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 2 && !stop.contains($0) }

        if tokens.isEmpty {
            return question.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 3 }
                .prefix(4)
                .map { String($0) }
        }

        var terms = [tokens.joined(separator: " ")]
        terms.append(contentsOf: tokens)
        return Array(Set(terms))
    }

    static func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ru_RU"))
            .replacingOccurrences(of: "ё", with: "е")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func score(
        event: MemoryIndexedEvent,
        terms: [String],
        embedding: NLEmbedding?
    ) -> Double {
        let hay = event.normalizedText
        var best = 0.0

        for term in terms {
            if hay.contains(term) {
                best = max(best, 1.0)
                continue
            }

            let termTokens = term.split(separator: " ").map(String.init)
            let matched = termTokens.filter { hay.contains($0) }.count
            if matched > 0 {
                best = max(best, Double(matched) / Double(max(termTokens.count, 1)) * 0.85)
            }

            if let embedding {
                for word in termTokens where word.count > 3 {
                    let neighbors = embedding.neighbors(for: word, maximumCount: 8)
                    for (neighbor, distance) in neighbors where hay.contains(neighbor) {
                        let sim = max(0, 1.0 - distance)
                        best = max(best, sim * 0.7)
                    }
                }
            }
        }

        return best
    }
}
