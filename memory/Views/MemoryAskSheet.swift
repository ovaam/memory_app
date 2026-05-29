import SwiftUI

struct MemoryAskSheet: View {
    let result: MemoryQueryResult
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Вопрос")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(result.question)
                        .font(.system(size: 20, weight: .semibold, design: .serif))

                    Text("Ответ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(result.answer)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !result.matches.isEmpty {
                        Text("Найденные записи")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(result.matches) { event in
                            NavigationLink {
                                DayDetailsView(dayStart: event.dayStart)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.text)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(daySubtitle(event))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.black.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Память")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово", action: onDismiss)
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func daySubtitle(_ event: MemoryIndexedEvent) -> String {
        if let t = event.eventTime {
            return Self.dateTimeFormatter.string(from: t)
        }
        return Self.dateFormatter.string(from: event.dayStart)
    }
}
