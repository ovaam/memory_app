import SwiftUI
import PhotosUI

struct PhotoBindingStep: View {
    @Binding var draft: DraftDay
    var onContinue: () -> Void

    @State private var pickerSelectionByEvent: [UUID: PhotosPickerItem] = [:]
    @State private var isLoadingByEvent: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Выбери фото и привяжи\nк каждому событию")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    ForEach($draft.events) { $event in
                        PhotoBindCard(
                            event: $event,
                            pickerItem: Binding(
                                get: { pickerSelectionByEvent[event.id] },
                                set: { pickerSelectionByEvent[event.id] = $0 }
                            ),
                            isLoading: isLoadingByEvent.contains(event.id),
                            onPickedData: { data in
                                if let data {
                                    event.attachments = [DraftAttachment(imageData: data)]
                                } else {
                                    event.attachments = []
                                }
                            },
                            onLoadState: { loading in
                                if loading { isLoadingByEvent.insert(event.id) }
                                else { isLoadingByEvent.remove(event.id) }
                            }
                        )
                    }
                }

                Button {
                    onContinue()
                } label: {
                    Text("Дальше: превью")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }
}

private struct PhotoBindCard: View {
    @Binding var event: DraftEvent
    @Binding var pickerItem: PhotosPickerItem?
    var isLoading: Bool

    var onPickedData: (Data?) -> Void
    var onLoadState: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(event.text.isEmpty ? "Событие" : event.text)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(2)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .frame(width: 74, height: 74)

                    if let data = event.attachments.first?.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2")
                            Text("Выбрать фото")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button {
                        event.attachments = []
                        pickerItem = nil
                        onPickedData(nil)
                    } label: {
                        Text("Убрать фото")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(.black)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                onLoadState(true)
                defer { onLoadState(false) }
                let data = try? await newValue.loadTransferable(type: Data.self)
                onPickedData(data)
            }
        }
    }
}

