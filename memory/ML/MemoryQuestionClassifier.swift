import Foundation
import CoreML
import NaturalLanguage

final class MemoryQuestionClassifier {
    static let shared = MemoryQuestionClassifier()

    private var coreMLModel: NLModel?

    private init() {
        if let url = Bundle.main.url(forResource: "MemoryQuestionIntent", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "MemoryQuestionIntent", withExtension: "mlmodel") {
            coreMLModel = try? NLModel(contentsOf: url)
        }
    }

    func classify(_ question: String) -> MemoryQuestionIntent {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .search }

        if let coreMLModel {
            let label = coreMLModel.predictedLabel(for: trimmed) ?? ""
            if let intent = MemoryQuestionIntent(rawValue: label) {
                return intent
            }
            switch label.lowercased() {
            case "whendid", "when": return .whenDid
            case "diddo", "did": return .didDo
            case "whatdid", "what": return .whatDid
            case "howmany", "count": return .howMany
            default: break
            }
        }

        return Self.heuristicIntent(trimmed)
    }

    private static func heuristicIntent(_ text: String) -> MemoryQuestionIntent {
        let lower = text.lowercased()

        if lower.contains("сколько") || lower.contains("раз") {
            return .howMany
        }
        if lower.contains("когда") || lower.hasPrefix("в какой") {
            return .whenDid
        }
        if lower.contains("делал") || lower.contains("делала")
            || lower.contains("был") || lower.contains("была")
            || lower.contains("ходил") || lower.contains("ходила")
            || lower.contains("ли я") || lower.contains("ли мы") {
            return .didDo
        }
        if lower.contains("что я") || lower.contains("что мы")
            || lower.contains("расскажи") || lower.contains("покажи") {
            return .whatDid
        }
        return .search
    }
}
