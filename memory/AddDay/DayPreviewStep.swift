import SwiftUI

struct DayPreviewStep: View {
    @Binding var draft: DraftDay
    var onConfirm: () -> Void
    var onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Мы поняли ваш день так…")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    ForEach(Array(draft.events.enumerated()), id: \.element.id) { index, event in
                        PreviewEventRow(event: event)

                        if index != draft.events.count - 1 {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.25))
                                .padding(.vertical, 4)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        onEdit()
                    } label: {
                        Text("Редактировать")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black.opacity(0.06))
                            )
                            .foregroundStyle(.primary)
                    }

                    Button {
                        onConfirm()
                    } label: {
                        Text("Подтвердить")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black)
                            )
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }
}

private struct PreviewEventRow: View {
    var event: DraftEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 10, height: 10)

                if let time = event.time {
                    Text(timeTitle(time))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(event.text.isEmpty ? "Событие" : event.text)
                    .font(.system(size: 16, weight: .semibold))

                if let data = event.attachments.first?.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ru_RU")
    f.dateFormat = "HH:mm"
    return f
}()

private func timeTitle(_ date: Date) -> String { timeFormatter.string(from: date) }
