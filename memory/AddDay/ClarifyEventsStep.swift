import SwiftUI

struct ClarifyEventsStep: View {
    @Binding var draft: DraftDay
    let clarifications: [DayClarification]
    @Binding var answers: [UUID: ClarificationAnswer]
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Уточним детали")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))

                Text("Так мы точнее выстроим хронологию дня. Можно пропустить любой пункт.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(clarifications) { item in
                    clarificationCard(item)
                }

                Button(action: onContinue) {
                    Text("Продолжить")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private func clarificationCard(_ item: DayClarification) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.prompt)
                .font(.system(size: 15, weight: .semibold))

            switch item.kind {
            case .missingTime:
                DatePicker(
                    "Время",
                    selection: Binding(
                        get: {
                            if case .time(let d) = answers[item.id] { return d }
                            return defaultTime(for: item.eventId)
                        },
                        set: { answers[item.id] = .time($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()

                Button("Не помню") {
                    answers[item.id] = .skipped
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            case .orderBetweenTwo:
                if let otherId = item.relatedEventId,
                   let first = draft.events.first(where: { $0.id == item.eventId }),
                   let second = draft.events.first(where: { $0.id == otherId }) {
                    HStack(spacing: 10) {
                        Button {
                            answers[item.id] = .orderPreferFirst
                        } label: {
                            Text(first.text)
                                .font(.footnote.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectionBackground(item.id, preferred: .orderPreferFirst))
                        }
                        .buttonStyle(.plain)

                        Button {
                            answers[item.id] = .orderPreferSecond
                        } label: {
                            Text(second.text)
                                .font(.footnote.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectionBackground(item.id, preferred: .orderPreferSecond))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func defaultTime(for eventId: UUID) -> Date {
        draft.events.first(where: { $0.id == eventId })?.time ?? Date()
    }

    private func selectionBackground(_ id: UUID, preferred: ClarificationAnswer) -> Color {
        answers[id] == preferred ? Color.black.opacity(0.12) : Color.black.opacity(0.05)
    }
}
