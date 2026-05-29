import SwiftUI
import SwiftData

struct CalendarHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MemoryDay.dayStart, order: .reverse)
    private var days: [MemoryDay]

    @State private var monthAnchor: Date = Date()
    @State private var presentingAdd = false
    @State private var pressedDayStart: Date?
    @State private var queryText: String = ""
    @State private var askResult: MemoryQueryResult?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                CalendarBackgroundView()
                    .ignoresSafeArea()

                GeometryReader { proxy in
                    let safeTop = proxy.safeAreaInsets.top
                    let safeBottom = proxy.safeAreaInsets.bottom

                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: safeTop + 86)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(monthGridSlots(for: monthAnchor).enumerated()), id: \.offset) { _, slot in
                                if let dayStart = slot {
                                    CalendarDayCell(
                                        dayStart: dayStart,
                                        hasContent: dayFor(dayStart) != nil,
                                        previewImages: previewImages(for: dayStart)
                                    )
                                    .contentShape(Circle())
                                    .onLongPressGesture(minimumDuration: 0.2, maximumDistance: 20) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            pressedDayStart = dayStart
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                            withAnimation(.easeOut(duration: 0.25)) {
                                                if pressedDayStart == dayStart {
                                                    pressedDayStart = nil
                                                }
                                            }
                                        }
                                    }
                                    .overlay {
                                        if pressedDayStart == dayStart {
                                            DayPreviewOverlay(images: previewImages(for: dayStart))
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .scaleEffect(pressedDayStart == dayStart ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pressedDayStart)
                                } else {
                                    Color.clear
                                        .frame(height: 46)
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .contentShape(Rectangle())
                        .gesture(monthSwipeGesture)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: monthAnchor)

                        Spacer(minLength: 20)

                        MonthNavigator(date: monthAnchor, onPrevious: { shiftMonth(by: -1) }, onNext: { shiftMonth(by: 1) })
                            .padding(.bottom, 10)

                        CalendarSearchBar(text: $queryText, onSubmit: submitMemoryQuestion)
                            .padding(.horizontal, 22)

                        addButton
                            .padding(.top, 26)

                        Spacer()
                            .frame(height: safeBottom + 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationDestination(for: Date.self) { dayStart in
                DayDetailsView(dayStart: dayStart)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $presentingAdd) {
            AddDayFlowView(initialDayStart: startOfDay(Date()))
        }
        .sheet(item: $askResult) { result in
            MemoryAskSheet(result: result) {
                askResult = nil
            }
        }
        .onAppear { rebuildMemoryIndex() }
        .onChange(of: days.count) { _, _ in rebuildMemoryIndex() }
        .onChange(of: presentingAdd) { _, isOpen in
            if !isOpen { rebuildMemoryIndex() }
        }
    }

    private func rebuildMemoryIndex() {
        MemoryKnowledgeBase.shared.rebuild(from: days)
    }

    private func submitMemoryQuestion() {
        let q = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        rebuildMemoryIndex()
        askResult = MemoryQueryEngine.shared.answer(question: q)
    }

    private var addButton: some View {
        Button {
            presentingAdd = true
        } label: {
            ZStack {
                CircularTextRing(
                    text: "tell your memory about this day",
                    radius: 70,
                    font: .system(size: 12, weight: .regular, design: .serif),
                    color: Color.black.opacity(0.55)
                )
                .rotationEffect(.degrees(-90))

                Circle()
                    .fill(Color(red: 0.36, green: 0.44, blue: 0.73))
                    .frame(width: 74, height: 74)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.85))
                    }
                    .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 16)
            }
            .frame(width: 172, height: 172)
        }
        .buttonStyle(.plain)
    }

    private func dayFor(_ dayStart: Date) -> MemoryDay? {
        days.first(where: { startOfDay($0.dayStart) == dayStart })
    }

    private func previewImages(for dayStart: Date) -> [Data] {
        guard let day = dayFor(dayStart) else { return [] }
        let datas = day.events
            .sorted(by: { $0.order < $1.order })
            .flatMap { $0.attachments }
            .compactMap { $0.imageData }
        return Array(datas.prefix(6))
    }

    private func monthGridSlots(for date: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count else {
            return []
        }

        let monthStart = startOfDay(interval.start)
        let weekday = calendar.component(.weekday, from: monthStart) // 1 = воскресенье
        let leading = (weekday - 1) % 7

        var slots: [Date?] = Array(repeating: nil, count: leading)

        for offset in 0..<dayCount {
            if let day = calendar.date(byAdding: .day, value: offset, to: monthStart) {
                slots.append(startOfDay(day))
            }
        }

        while slots.count % 7 != 0 {
            slots.append(nil)
        }

        return slots
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 40 else { return }

                if dx < 0 {
                    shiftMonth(by: 1)
                } else {
                    shiftMonth(by: -1)
                }
            }
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: monthAnchor) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            monthAnchor = newMonth
            pressedDayStart = nil
        }
    }
}

private struct MonthNavigator: View {
    var date: Date
    var onPrevious: () -> Void
    var onNext: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            MonthLabel(date: date)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CalendarDayCell: View {
    var dayStart: Date
    var hasContent: Bool
    var previewImages: [Data]

    var body: some View {
        NavigationLink(value: dayStart) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.07), lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: dayStart))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.75))

                    if hasContent {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 4, height: 4)
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: 46)
        }
        .buttonStyle(.plain)
    }
}

private struct MonthLabel: View {
    var date: Date

    var body: some View {
        VStack(spacing: 2) {
            Text(monthName(date))
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color.black.opacity(0.50))
            Text(yearName(date))
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(Color.black.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }

    private func yearName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

private struct DayPreviewOverlay: View {
    var images: [Data]

    var body: some View {
        VStack(spacing: 8) {
            if images.isEmpty {
                Text("Пусто")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
                    )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 6), count: 3), spacing: 6) {
                    ForEach(Array(images.prefix(6).enumerated()), id: \.offset) { _, data in
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.08))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 12)
                )
            }
        }
        .offset(y: -62)
    }
}

private var calendar: Calendar { Calendar.current }

private func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}

