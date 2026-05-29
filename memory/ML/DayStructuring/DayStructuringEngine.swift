import Foundation

enum DayStructuringEngine {

    static func structure(rawInput: String, dayStart: Date) -> DayStructureResult {
        let normalized = normalize(rawInput)
        guard !normalized.isEmpty else {
            return DayStructureResult(events: [DraftEvent(text: "")], clarifications: [])
        }

        let segments = splitIntoSegments(normalized)
        var parsed: [ParsedDaySegment] = []

        for (index, segment) in segments.enumerated() {
            let (time, cleaned) = extractTime(from: segment, dayStart: dayStart)
            let title = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            parsed.append(ParsedDaySegment(text: title, time: time, sourceOrder: index))
        }

        if parsed.isEmpty {
            parsed = [ParsedDaySegment(text: normalized, time: nil, sourceOrder: 0)]
        }

        let ordered = sortChronologically(parsed, dayStart: dayStart)
        let events = ordered.map { DraftEvent(time: $0.time, text: $0.text) }
        let clarifications = buildClarifications(for: events)

        return DayStructureResult(events: events, clarifications: clarifications)
    }

    static func applyClarifications(
        events: [DraftEvent],
        clarifications: [DayClarification],
        answers: [UUID: ClarificationAnswer]
    ) -> [DraftEvent] {
        var updated = events

        for item in clarifications {
            guard let answer = answers[item.id] else { continue }
            guard let idx = updated.firstIndex(where: { $0.id == item.eventId }) else { continue }

            switch answer {
            case .time(let date):
                updated[idx].time = date
            case .orderPreferFirst:
                if let otherId = item.relatedEventId,
                   let otherIdx = updated.firstIndex(where: { $0.id == otherId }),
                   idx > otherIdx {
                    let ev = updated.remove(at: idx)
                    updated.insert(ev, at: otherIdx)
                }
            case .orderPreferSecond:
                if let otherId = item.relatedEventId,
                   let otherIdx = updated.firstIndex(where: { $0.id == otherId }),
                   idx < otherIdx {
                    let ev = updated.remove(at: otherIdx)
                    updated.insert(ev, at: idx)
                }
            case .skipped:
                break
            }
        }

        return sortDraftEvents(updated)
    }

    static func sortDraftEvents(_ events: [DraftEvent]) -> [DraftEvent] {
        let keyed = events.enumerated().map { index, event in
            let key: Int
            if let time = event.time {
                key = Int(time.timeIntervalSince1970)
            } else {
                key = 86_400 + index
            }
            return (key, index, event)
        }
        return keyed.sorted {
            if $0.0 == $1.0 { return $0.1 < $1.1 }
            return $0.0 < $1.0
        }.map(\.2)
    }

    private static func splitIntoSegments(_ text: String) -> [String] {
        var work = text

        let splitMarkers = [
            "\n", "•", ";",
            " потом ", " затем ", " далее ", " после этого ",
            " а потом ", " и потом ", " сначала ",
        ]
        for marker in splitMarkers {
            work = work.replacingOccurrences(of: marker, with: "\n", options: .caseInsensitive)
        }

        let parts = work
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count > 1 { return parts }

        if work.lowercased().contains(" и ") {
            let pieces = work.components(separatedBy: " и ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 3 }
            if pieces.count > 1 { return pieces }
        }

        return [work]
    }

    private static func extractTime(from segment: String, dayStart: Date) -> (Date?, String) {
        let lower = segment.lowercased()
        var remaining = segment

        if let match = firstMatch(in: lower, pattern: #"\b(\d{1,2})[:\.](\d{2})\b"#) {
            if let date = timeOnDay(dayStart, hour: match.0, minute: match.1) {
                remaining = removePattern(remaining, pattern: #"\b(\d{1,2})[:\.](\d{2})\b"#)
                return (date, remaining)
            }
        }

        if let match = firstHourMatch(
            in: lower,
            pattern: #"\bв\s*(\d{1,2})(?:\s*(утра|утром|дня|днем|днём|вечера|вечером|часа|часов))?"#
        ) {
            let adjusted = adjustHour(match.hour, dayPart: match.dayPart)
            if let date = timeOnDay(dayStart, hour: adjusted, minute: 0) {
                remaining = removePattern(
                    remaining,
                    pattern: #"\bв\s*(\d{1,2})(?:\s*(утра|утром|дня|днем|днём|вечера|вечером|часа|часов))?"#
                )
                return (date, remaining)
            }
        }

        let dayParts: [(String, Int)] = [
            ("утром", 9), ("утра", 9),
            ("днём", 13), ("днем", 13), ("дня", 13),
            ("вечером", 19), ("вечера", 19),
            ("ночью", 22),
        ]
        for (word, hour) in dayParts {
            if lower.contains(word), let date = timeOnDay(dayStart, hour: hour, minute: 0) {
                remaining = remaining.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
                return (date, remaining)
            }
        }

        return (nil, remaining)
    }

    private static func adjustHour(_ hour: Int, dayPart: String) -> Int {
        switch dayPart {
        case "вечера", "вечером": return hour < 12 ? hour + 12 : hour
        case "дня", "днем", "днём": return hour < 12 && hour <= 6 ? hour + 12 : hour
        case "утра", "утром": return hour == 12 ? 0 : hour
        default: return hour
        }
    }

    private static func timeOnDay(_ dayStart: Date, hour: Int, minute: Int) -> Date? {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: dayStart)
        comps.hour = min(23, max(0, hour))
        comps.minute = min(59, max(0, minute))
        return Calendar.current.date(from: comps)
    }

    private static func sortChronologically(_ segments: [ParsedDaySegment], dayStart: Date) -> [ParsedDaySegment] {
        segments.sorted { a, b in
            switch (a.time, b.time) {
            case let (t1?, t2?):
                if t1 != t2 { return t1 < t2 }
                return a.sourceOrder < b.sourceOrder
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return a.sourceOrder < b.sourceOrder
            }
        }
    }

    private static func buildClarifications(for events: [DraftEvent]) -> [DayClarification] {
        guard events.count > 1 else { return [] }

        var items: [DayClarification] = []
        let untimed = events.filter { $0.time == nil }

        for event in untimed.prefix(4) {
            items.append(
                DayClarification(
                    kind: .missingTime,
                    eventId: event.id,
                    prompt: "Во сколько было: «\(event.text)»?"
                )
            )
        }

        if untimed.count >= 2 {
            let a = untimed[0]
            let b = untimed[1]
            items.append(
                DayClarification(
                    kind: .orderBetweenTwo,
                    eventId: a.id,
                    prompt: "Что было раньше?",
                    relatedEventId: b.id
                )
            )
        }

        return items
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(in text: String, pattern: String) -> (Int, Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        guard match.numberOfRanges >= 2,
              let hRange = Range(match.range(at: 1), in: text),
              let h = Int(text[hRange]) else { return nil }
        let m: Int
        if match.numberOfRanges >= 3, let mRange = Range(match.range(at: 2), in: text) {
            m = Int(text[mRange]) ?? 0
        } else {
            m = 0
        }
        return (h, m)
    }

    private struct HourMatch {
        var hour: Int
        var dayPart: String
    }

    private static func firstHourMatch(in text: String, pattern: String) -> HourMatch? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges >= 2,
              let hRange = Range(match.range(at: 1), in: text),
              let h = Int(text[hRange]) else { return nil }
        let part: String
        if match.numberOfRanges >= 3, let pRange = Range(match.range(at: 2), in: text) {
            part = String(text[pRange])
        } else {
            part = ""
        }
        return HourMatch(hour: h, dayPart: part)
    }

    private static func removePattern(_ text: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ClarificationAnswer: Equatable {
    case time(Date)
    case orderPreferFirst
    case orderPreferSecond
    case skipped
}
