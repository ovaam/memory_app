import SwiftUI

struct ReorderEventsStep: View {
    @Binding var draft: DraftDay
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach($draft.events) { $event in
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                            Text(event.text.isEmpty ? "Событие" : event.text)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .onMove(perform: move)
                } header: {
                    Text("Перетащи, чтобы изменить порядок")
                }
            }
            .listStyle(.insetGrouped)

            Button {
                onDone()
            } label: {
                Text("Готово")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black)
                    )
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                    .padding(.top, 10)
            }
        }
        .toolbar {
            EditButton()
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        draft.events.move(fromOffsets: source, toOffset: destination)
    }
}

