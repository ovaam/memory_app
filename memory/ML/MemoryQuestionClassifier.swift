import Foundation
import NaturalLanguage

final class MemoryQuestionClassifier {
    static let shared = MemoryQuestionClassifier()

    private let model: NLModel?

    private init() {
        let url = Bundle.main.url(forResource: "MemoryClassifier 1", withExtension: "mlmodelc")
               ?? Bundle.main.url(forResource: "MemoryClassifier 1", withExtension: "mlmodel")
        model = url.flatMap { try? NLModel(contentsOf: $0) }
    }

    func classify(_ question: String) -> MemoryQuestionIntent {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .search }

        let label = model?.predictedLabel(for: trimmed) ?? ""
        return MemoryQuestionIntent(rawValue: label) ?? mapLabel(label)
    }

    private func mapLabel(_ label: String) -> MemoryQuestionIntent {
        switch label.lowercased() {
        case "whendid": return .whenDid
        case "diddo":   return .didDo
        case "whatdid": return .whatDid
        case "howmany": return .howMany
        default:        return .search
        }
    }
}
