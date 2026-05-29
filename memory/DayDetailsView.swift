import SwiftUI
import SwiftData

struct DayDetailsView: View {
    @Environment(\.modelContext) private var modelContext

    let dayStart: Date

    @Query private var days: [MemoryDay]

    @State private var presentingAdd = false

    init(dayStart: Date) {
        self.dayStart = dayStart

        let start = dayStart
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _days = Query(filter: #Predicate<MemoryDay> { $0.dayStart >= start && $0.dayStart < end })
    }

    private var day: MemoryDay? { days.first }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 18) {
                    header

                    if let day {
                        TimelineView(events: day.events.sorted(by: { $0.order < $1.order }))
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(dayTitle(dayStart))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $presentingAdd) {
            AddDayFlowView(initialDayStart: dayStart)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(dayTitle(dayStart))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("События идут сверху вниз.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.04))
                .frame(height: 140)
                .overlay {
                    VStack(spacing: 8) {
                        Text("Пока пусто")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Нажми «+», чтобы записать день.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

            Button {
                presentingAdd = true
            } label: {
                Text("Добавить события")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black)
                    )
                    .foregroundStyle(.white)
            }
        }
    }
}

private struct TimelineView: View {
    var events: [MemoryEvent]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                NavigationLink {
                    EventDetailsView(event: event)
                } label: {
                    TimelineEventCard(event: event)
                }
                .buttonStyle(.plain)

                if index != events.count - 1 {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.25))
                        .padding(.vertical, 4)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: events.count)
    }
}

private struct TimelineEventCard: View {
    var event: MemoryEvent

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
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let data = event.attachments.first?.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
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

private struct EventDetailsView: View {
    var event: MemoryEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let time = event.time {
                    Text(timeTitle(time))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(event.text.isEmpty ? "Событие" : event.text)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                if event.attachments.isEmpty {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.04))
                        .frame(height: 180)
                        .overlay {
                            Text("Фото пока нет")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                } else {
                    VStack(spacing: 10) {
                        ForEach(event.attachments, id: \.id) { attachment in
                            if let data = attachment.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .navigationTitle("Событие")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ru_RU")
    f.dateFormat = "d MMMM"
    return f
}()

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ru_RU")
    f.dateFormat = "HH:mm"
    return f
}()

private func dayTitle(_ date: Date) -> String { dayFormatter.string(from: date) }
private func timeTitle(_ date: Date) -> String { timeFormatter.string(from: date) }
