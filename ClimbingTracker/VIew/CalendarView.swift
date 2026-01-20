import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: ClimbingStore

    @State private var visibleMonthStart: Date = CalendarLogic.monthStart(for: Date())
    @State private var selectedDate: Date = CalendarLogic.stripTime(Date())

    private let borderWidth: CGFloat = 2
    private let listRowHeight: CGFloat = 81

    private var monthTitle: String {
        CalendarLogic.monthTitle(for: visibleMonthStart)
    }

    private var gridModel: CalendarLogic.MonthGrid {
        CalendarLogic.buildMonthGrid(for: visibleMonthStart)
    }

    private var climbingsForSelectedDay: [Climbing] {
        let day = CalendarLogic.stripTime(selectedDate)
        return store.climbings
            .filter { CalendarLogic.stripTime($0.date) == day }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ClimbingScreen(title: "Calendar", showsBackButton: false, onBackTap: nil) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 14)
                        .padding(.horizontal, 12)

                    weekdayRow

                    calendarGrid
                        .padding(.horizontal, -2)
                        .padding(.top, 0)
                        .padding(.bottom, 18)

                    climbsSection
                        .padding(.top, 22)
                        .padding(.horizontal, 12)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    visibleMonthStart = CalendarLogic.addMonths(visibleMonthStart, -1)
                }
            } label: {
                Image(.backButton)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle)
                .font(AppFont.make(size: 24, weight: .expandedHeavy))
                .foregroundStyle(Color(hex: "#232F3E"))

            Spacer()

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    visibleMonthStart = CalendarLogic.addMonths(visibleMonthStart, 1)
                }
            } label: {
                Image(.backButton)
                    .rotationEffect(.degrees(180))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 10)
    }

    private var weekdayRow: some View {
        let titles = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

        return HStack(spacing: 0) {
            ForEach(titles, id: \.self) { t in
                Text(t)
                    .font(AppFont.make(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.black)
            }
        }
    }

    private var calendarGrid: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let cell = floor(totalW / 7.0)
            let rows = gridModel.rows
            let gridH = cell * CGFloat(rows)

            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let idx = row * 7 + col
                            let cellModel = gridModel.cells[idx]

                            DayCellView(
                                cell: cellModel,
                                isSelected: cellModel.date.map { CalendarLogic.stripTime($0) == CalendarLogic.stripTime(selectedDate) } ?? false,
                                hasClimbings: cellModel.date.map { CalendarLogic.hasClimbings(on: $0, in: store.climbings) } ?? false,
                                borderWidth: borderWidth
                            ) {
                                if let d = cellModel.date {
                                    selectedDate = d
                                }
                            }
                            .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .frame(width: totalW, height: gridH, alignment: .top)
        }
        .frame(height: CalendarLogic.estimatedGridHeight(forWidth: UIScreen.main.bounds.width - 24, rows: gridModel.rows))
    }

    private var climbsSection: some View {
        VStack(spacing: 10) {
            if climbingsForSelectedDay.isEmpty {
                Text("No climbings for this day")
                    .font(AppFont.make(size: 18, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            } else {
                ForEach(climbingsForSelectedDay) { climbing in
                    NavigationLink {
                        ClimbingDetailView(climbingId: climbing.id)
                            .environmentObject(store)
                            .navigationBarBackButtonHidden()
                    } label: {
                        CalendarClimbingRow(
                            dateText: CalendarLogic.dayMonthText(from: climbing.date),
                            placeName: store.places.first(where: { $0.id == climbing.placeId })?.name ?? "Unknown",
                            gradeText: store.routes.first(where: { $0.id == climbing.routeId })?.grade.rawValue ?? "-"
                        )
                        .frame(height: listRowHeight)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DayCellView: View {
    let cell: CalendarLogic.DayCell
    let isSelected: Bool
    let hasClimbings: Bool
    let borderWidth: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                background

                VStack(spacing: 6) {
                    Text(cell.dayNumberText)
                        .font(AppFont.make(size: 23, weight: .heavy))
                        .foregroundStyle(dayTextColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    if hasClimbings && cell.date != nil {
                        Circle()
                            .fill(UIConstants.navBarAccent)
                            .frame(width: 7, height: 7)
                            .padding(.bottom, 6)
                    } else {
                        Color.clear
                            .frame(width: 7, height: 7)
                            .padding(.bottom, 6)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
            }
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: borderWidth)
            )
        }
        .buttonStyle(.plain)
        .disabled(cell.date == nil)
    }

    private var background: Color {
        if isSelected && cell.isInCurrentMonth {
            return Color(hex: "#4EA3D8")
        }
        return Color.white
    }

    private var dayTextColor: Color {
        if !cell.isInCurrentMonth {
            return Color.gray.opacity(0.65)
        }
        if isSelected {
            return .white
        }
        return .black
    }
}

private struct CalendarClimbingRow: View {
    let dateText: String
    let placeName: String
    let gradeText: String

    var body: some View {
        HStack(spacing: 0) {
            Text(dateText)
                .font(AppFont.make(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .center)

            divider

            Text(placeName)
                .font(AppFont.make(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)

            divider

            Text(gradeText)
                .font(AppFont.make(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, alignment: .center)
        }
        .background(Color(hex: "#4EA3D8"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.85))
            .frame(width: 1)
            .padding(.vertical, 10)
    }
}

enum CalendarLogic {
    struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
        let dayNumber: Int?
        let isInCurrentMonth: Bool

        var dayNumberText: String {
            guard let dayNumber else { return "" }
            return "\(dayNumber)"
        }
    }

    struct MonthGrid {
        let cells: [DayCell]
        let rows: Int
    }

    static func mondayFirstCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = 2
        return cal
    }

    static func stripTime(_ date: Date) -> Date {
        let cal = mondayFirstCalendar()
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return cal.date(from: comps) ?? date
    }

    static func monthStart(for date: Date) -> Date {
        let cal = mondayFirstCalendar()
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    static func addMonths(_ date: Date, _ value: Int) -> Date {
        let cal = mondayFirstCalendar()
        return cal.date(byAdding: .month, value: value, to: date) ?? date
    }

    static func monthTitle(for monthStart: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "LLLL"
        let raw = f.string(from: monthStart)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    static func dayMonthText(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "dd.MM"
        return f.string(from: date)
    }

    static func hasClimbings(on date: Date, in climbings: [Climbing]) -> Bool {
        let day = stripTime(date)
        return climbings.contains { stripTime($0.date) == day }
    }

    static func buildMonthGrid(for month: Date) -> MonthGrid {
        let cal = mondayFirstCalendar()
        let firstDay = monthStart(for: month)

        guard let daysRange = cal.range(of: .day, in: .month, for: firstDay) else {
            return MonthGrid(cells: Array(repeating: DayCell(date: nil, dayNumber: nil, isInCurrentMonth: true), count: 35), rows: 5)
        }

        let numberOfDays = daysRange.count

        let weekday = cal.component(.weekday, from: firstDay)
        let leading = ((weekday - cal.firstWeekday) + 7) % 7

        let used = leading + numberOfDays
        let trailing = (7 - (used % 7)) % 7
        let totalCells = used + trailing

        let rows = max(5, Int(ceil(Double(totalCells) / 7.0)))
        let neededCells = rows * 7

        var cells: [DayCell] = []

        if leading > 0 {
            let prevMonthStart = addMonths(firstDay, -1)
            let prevFirst = monthStart(for: prevMonthStart)
            let prevDaysRange = cal.range(of: .day, in: .month, for: prevFirst) ?? 1..<2
            let prevCount = prevDaysRange.count

            let startDay = prevCount - leading + 1
            for day in startDay...prevCount {
                var comps = cal.dateComponents([.year, .month], from: prevFirst)
                comps.day = day
                let d = cal.date(from: comps)
                cells.append(DayCell(date: d, dayNumber: day, isInCurrentMonth: false))
            }
        }

        for day in 1...numberOfDays {
            var comps = cal.dateComponents([.year, .month], from: firstDay)
            comps.day = day
            let d = cal.date(from: comps)
            cells.append(DayCell(date: d, dayNumber: day, isInCurrentMonth: true))
        }

        if trailing > 0 {
            let nextMonthStart = addMonths(firstDay, 1)
            let nextFirst = monthStart(for: nextMonthStart)

            for day in 1...trailing {
                var comps = cal.dateComponents([.year, .month], from: nextFirst)
                comps.day = day
                let d = cal.date(from: comps)
                cells.append(DayCell(date: d, dayNumber: day, isInCurrentMonth: false))
            }
        }

        while cells.count < neededCells {
            cells.append(DayCell(date: nil, dayNumber: nil, isInCurrentMonth: true))
        }

        return MonthGrid(cells: cells, rows: rows)
    }

    static func estimatedGridHeight(forWidth width: CGFloat, rows: Int) -> CGFloat {
        let cell = floor(width / 7.0)
        return cell * CGFloat(rows)
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .environmentObject(ClimbingStore())
            .navigationBarBackButtonHidden()
    }
}
