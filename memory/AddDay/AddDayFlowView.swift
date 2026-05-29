import SwiftUI
import SwiftData

struct AddDayFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let initialDayStart: Date

    @State private var draft: DraftDay
    @State private var step: Step = .record
    @State private var inputText = ""
    @State private var clarifications: [DayClarification] = []
    @State private var clarificationAnswers: [UUID: ClarificationAnswer] = [:]
    @State private var structureError: String?

    @StateObject private var speech = SpeechDayTranscriber()

    enum Step: Int {
        case record
        case clarify
        case bindPhotos
        case preview
        case reorder
    }

    init(initialDayStart: Date) {
        self.initialDayStart = initialDayStart
        _draft = State(initialValue: DraftDay(dayStart: initialDayStart, events: [DraftEvent(text: "")]))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch step {
                case .record:
                    recordStep
                case .clarify:
                    ClarifyEventsStep(
                        draft: $draft,
                        clarifications: clarifications,
                        answers: $clarificationAnswers,
                        onContinue: applyClarificationsAndContinue
                    )
                case .bindPhotos:
                    PhotoBindingStep(draft: $draft) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            step = .preview
                        }
                    }
                case .preview:
                    DayPreviewStep(draft: $draft, onConfirm: saveDraft, onEdit: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            step = .reorder
                        }
                    })
                case .reorder:
                    ReorderEventsStep(draft: $draft) {
                        draft.events = DayStructuringEngine.sortDraftEvents(draft.events)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            step = .preview
                        }
                    }
                }
            }
            .navigationTitle(titleForStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording || !newValue.isEmpty {
                inputText = newValue
            }
        }
    }

    private var titleForStep: String {
        switch step {
        case .record: return "Запись дня"
        case .clarify: return "Уточнения"
        case .bindPhotos: return "Фото"
        case .preview: return "Превью"
        case .reorder: return "Редактирование"
        }
    }

    private var recordStep: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Запиши день голосом\nили введи текст")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("ИИ разобьёт рассказ на события и выстроит их по времени.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VoiceRecordButton(
                    isRecording: speech.isRecording,
                    onTap: { speech.toggleRecording() }
                )

                if let err = speech.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Текст")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Например: в 9 утра кофе, потом встреча, вечером прогулка…",
                        text: $inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .lineLimit(4...12)
                }

                if !draft.events.isEmpty, draft.events.contains(where: { !$0.text.isEmpty }) {
                    structuredPreviewList
                }

                Button(action: runStructuring) {
                    Text("Структурировать день")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black)
                        )
                        .foregroundStyle(.white)
                }

                if let structureError {
                    Text(structureError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }

    private var structuredPreviewList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Черновик событий")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(draft.events) { event in
                HStack(spacing: 8) {
                    Text(event.time.map(timeTitle) ?? "—")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Text(event.text)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
    }

    private func runStructuring() {
        structureError = nil
        if speech.isRecording { speech.stopRecording() }

        let source = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            structureError = "Введи текст или запиши голосом."
            return
        }

        let result = DayStructuringEngine.structure(rawInput: source, dayStart: initialDayStart)
        draft.events = result.events
        clarifications = result.clarifications
        clarificationAnswers = [:]

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if clarifications.isEmpty {
                step = .bindPhotos
            } else {
                step = .clarify
            }
        }
    }

    private func applyClarificationsAndContinue() {
        draft.events = DayStructuringEngine.applyClarifications(
            events: draft.events,
            clarifications: clarifications,
            answers: clarificationAnswers
        )
        draft.events = DayStructuringEngine.sortDraftEvents(draft.events)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            step = .bindPhotos
        }
    }

    private func saveDraft() {
        let dayStart = initialDayStart
        let existing = fetchExistingDay(for: dayStart)
        let memoryDay = existing ?? MemoryDay(dayStart: dayStart)
        memoryDay.updatedAt = Date()
        if existing != nil {
            memoryDay.events.removeAll()
        }

        let sortedEvents = DayStructuringEngine.sortDraftEvents(draft.events)
        for (idx, e) in sortedEvents.enumerated() {
            let event = MemoryEvent(order: idx, time: e.time, text: e.text)
            event.day = memoryDay
            event.attachments = e.attachments.map { MemoryAttachment(imageData: $0.imageData) }
            for attachment in event.attachments {
                attachment.event = event
            }
            memoryDay.events.append(event)
        }

        if existing == nil {
            modelContext.insert(memoryDay)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            dismiss()
        }
    }

    private func fetchExistingDay(for dayStart: Date) -> MemoryDay? {
        let start = dayStart
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let descriptor = FetchDescriptor<MemoryDay>(
            predicate: #Predicate { $0.dayStart >= start && $0.dayStart < end }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}

private struct VoiceRecordButton: View {
    var isRecording: Bool
    var onTap: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.06))
                        .frame(width: 170, height: 170)

                    Circle()
                        .fill(Color.black.opacity(isRecording ? 0.14 : 0.08))
                        .frame(width: 130, height: 130)
                        .scaleEffect(isRecording && pulse ? 1.06 : 1.0)
                        .animation(isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)

                    Circle()
                        .fill(Color.black)
                        .frame(width: 86, height: 86)
                        .overlay {
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: isRecording) { _, recording in
                pulse = recording
            }

            Text(isRecording ? "Идёт запись…" : "Начать запись")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ru_RU")
    f.dateFormat = "HH:mm"
    return f
}()

private func timeTitle(_ date: Date) -> String { timeFormatter.string(from: date) }
