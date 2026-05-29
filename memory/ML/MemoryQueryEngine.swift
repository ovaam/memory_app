import Foundation

@MainActor
final class MemoryQueryEngine {
    static let shared = MemoryQueryEngine()

    private let classifier = MemoryQuestionClassifier.shared
    private let knowledgeBase = MemoryKnowledgeBase.shared

    private init() {}

    func answer(question: String) -> MemoryQueryResult {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = classifier.classify(trimmed)
        let terms = MemoryKnowledgeBase.extractActivityTerms(from: trimmed)
        let matches = knowledgeBase.search(activityTerms: terms)

        return MemoryQueryResult(
            question: trimmed,
            intent: intent,
            activityTerms: terms,
            matches: matches,
            answer: Self.formatAnswer(intent: intent, question: trimmed, terms: terms, matches: matches)
        )
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static func formatAnswer(
        intent: MemoryQuestionIntent,
        question: String,
        terms: [String],
        matches: [MemoryIndexedEvent]
    ) -> String {
        if matches.isEmpty {
            if terms.isEmpty {
                return "В памяти пока нет событий. Добавь день через «+», и я смогу отвечать на вопросы."
            }
            let topic = terms.first ?? "это"
            return "Я не нашёл в твоей памяти ничего про «\(topic)». Попробуй переформулировать или добавь запись за тот день."
        }

        switch intent {
        case .didDo:   return formatDidDo(terms: terms, matches: matches)
        case .whenDid: return formatWhen(terms: terms, matches: matches)
        case .howMany: return formatCount(terms: terms, matches: matches)
        case .whatDid: return formatList(matches: matches, header: "Вот что нашёл в памяти:")
        case .search:  return formatList(matches: matches, header: "По твоему запросу:")
        }
    }

    private static func formatDidDo(terms: [String], matches: [MemoryIndexedEvent]) -> String {
        let topic = terms.first ?? "это"
        if matches.isEmpty {
            return "Похоже, ты не записывал(а) «\(topic)»."
        }
        let first = matches[0]
        var lines = ["Да — в памяти есть «\(first.text)» (\(dayString(first.dayStart)))."]
        if matches.count > 1 {
            lines.append("Ещё \(matches.count - 1) похожих записей.")
            lines.append(contentsOf: matches.prefix(4).dropFirst().map { "• \($0.text) — \(dayString($0.dayStart))\(timeSuffix($0))" })
        }
        return lines.joined(separator: "\n")
    }

    private static func formatWhen(terms: [String], matches: [MemoryIndexedEvent]) -> String {
        let topic = terms.first ?? "это"
        guard let first = matches.first else {
            return "Не нашёл, когда ты делал(а) «\(topic)»."
        }
        var line = "Последний раз: \(dayString(first.dayStart))"
        if let t = first.eventTime {
            line += ", \(timeString(t))"
        }
        line += " — «\(first.text)»."

        if matches.count > 1 {
            let more = matches.prefix(5).map { "• \(dayString($0.dayStart))\(timeSuffix($0)) — \($0.text)" }.joined(separator: "\n")
            return line + "\n\nРаньше:\n" + more
        }
        return line
    }

    private static func formatCount(terms: [String], matches: [MemoryIndexedEvent]) -> String {
        let topic = terms.first ?? "это"
        let n = matches.count
        let header = "«\(topic)»: \(n) \(russianTimesWord(n)) в памяти."
        let list = matches.prefix(6).map { "• \(dayString($0.dayStart)) — \($0.text)" }.joined(separator: "\n")
        return header + "\n" + list
    }

    private static func formatList(matches: [MemoryIndexedEvent], header: String) -> String {
        let list = matches.prefix(8).map { "• \(dayString($0.dayStart))\(timeSuffix($0)) — \($0.text)" }.joined(separator: "\n")
        return header + "\n" + list
    }

    private static func dayString(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private static func timeString(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private static func timeSuffix(_ event: MemoryIndexedEvent) -> String {
        guard let t = event.eventTime else { return "" }
        return ", \(timeString(t))"
    }

    private static func russianTimesWord(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod100 >= 11 && mod100 <= 14 { return "раз" }
        switch mod10 {
        case 1: return "раз"
        case 2, 3, 4: return "раза"
        default: return "раз"
        }
    }
}
