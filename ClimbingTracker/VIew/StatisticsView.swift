import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: ClimbingStore

    private let chartHeight: CGFloat = 270

    var body: some View {
        ClimbingScreen(title: "Statistics", showsBackButton: false, onBackTap: nil) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    chartBlock
                        .padding(.top, 14)

                    moodsBlock

                    tipBlock

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var chartBlock: some View {
        let year = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())

        let monthStats = buildMonthlyStats(forYear: year, upToMonth: currentMonth)
        let segments = splitIntoConsecutiveSegments(monthStats)

        let yDomain = difficultyDomain()

        return VStack(spacing: 0) {
            Chart {
                ForEach(segments.indices, id: \.self) { segIndex in
                    let segment = segments[segIndex]

                    if segment.count >= 2 {
                        ForEach(segment) { item in
                            LineMark(
                                x: .value("Month", item.monthIndex),
                                y: .value("Difficulty", item.gradeRank)
                            )
                        }
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color(hex: "#F2B51C"))
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        ForEach(segment) { item in
                            PointMark(
                                x: .value("Month", item.monthIndex),
                                y: .value("Difficulty", item.gradeRank)
                            )
                            .foregroundStyle(Color(hex: "#F2B51C"))
                            .symbolSize(35)
                        }
                    } else if let only = segment.first {
                        PointMark(
                            x: .value("Month", only.monthIndex),
                            y: .value("Difficulty", only.gradeRank)
                        )
                        .foregroundStyle(Color(hex: "#F2B51C"))
                        .symbolSize(60)
                    }
                }
            }
            .frame(height: chartHeight)
            .chartXScale(domain: 1...12)
            .chartYScale(domain: yDomain.min...yDomain.max)
            .chartXAxis {
                AxisMarks(values: Array(1...12)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.black.opacity(0.15))
                    AxisTick()
                        .foregroundStyle(Color.black.opacity(0.6))
                    AxisValueLabel {
                        if let m = value.as(Int.self) {
                            Text(shortMonthTitle(m))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Color.black.opacity(0.85))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: yDomain.axisValues) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.black.opacity(0.25))
                    AxisTick()
                        .foregroundStyle(Color.black.opacity(0.6))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(gradeLabel(forRank: v))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.black.opacity(0.85))
                        }
                    }
                }
            }
        }
    }


    private var moodsBlock: some View {
        let items = topMoods(limit: 4)

        return VStack(alignment: .leading, spacing: 10) {
            if items.isEmpty {
                Text("No data yet")
                    .font(AppFont.make(size: 18, weight: .bold))
                    .foregroundColor(.gray)
            } else {
                ForEach(items, id: \.kind.id) { item in
                    HStack(spacing: 10) {
                        Image(item.kind.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)

                        Text("— \(item.percent)% (\(item.kind.title))")
                            .font(AppFont.make(size: 18, weight: .regular))
                            .foregroundColor(Color.black.opacity(0.85))

                        Spacer()
                    }
                }
            }
        }
        .padding(.top, 2)
    }


    private var tipBlock: some View {
        let tipText = buildTipText()

        return HStack(alignment: .top, spacing: 12) {
            Image(.tip)

            HStack(spacing: 6) {
                Text("Tip:")
                    .font(AppFont.make(size: 24, weight: .expandedHeavy))
                    .foregroundColor(Color.black.opacity(0.9))

                Text("“\(tipText)”")
                    .font(AppFont.make(size: 24, weight: .regular))
                    .foregroundColor(Color.black.opacity(0.75))
            }

            Spacer(minLength: 12)
        }
        .padding(.top, 4)
    }


    private func buildMonthlyStats(forYear year: Int, upToMonth currentMonth: Int) -> [MonthlyDifficultyPoint] {
        var dict: [Int: Int] = [:]

        for climb in store.climbings {
            let comps = Calendar.current.dateComponents([.year, .month], from: climb.date)
            guard comps.year == year else { continue }
            guard let m = comps.month, m >= 1, m <= 12 else { continue }
            guard m <= currentMonth else { continue }

            guard let route = store.routes.first(where: { $0.id == climb.routeId }) else { continue }
            let rank = route.grade.rank

            if let existing = dict[m] {
                dict[m] = max(existing, rank)
            } else {
                dict[m] = rank
            }
        }

        let points: [MonthlyDifficultyPoint] = dict
            .map { (month, rank) in MonthlyDifficultyPoint(monthIndex: month, gradeRank: rank) }
            .sorted(by: { $0.monthIndex < $1.monthIndex })

        return points
    }

    private func splitIntoConsecutiveSegments(_ points: [MonthlyDifficultyPoint]) -> [[MonthlyDifficultyPoint]] {
        guard !points.isEmpty else { return [] }

        var result: [[MonthlyDifficultyPoint]] = []
        var current: [MonthlyDifficultyPoint] = [points[0]]

        for i in 1..<points.count {
            let prev = points[i - 1]
            let now = points[i]
            if now.monthIndex == prev.monthIndex + 1 {
                current.append(now)
            } else {
                result.append(current)
                current = [now]
            }
        }

        result.append(current)
        return result
    }

    private func topMoods(limit: Int) -> [(kind: MoodKind, percent: Int)] {
        let year = Calendar.current.component(.year, from: Date())

        var counts: [MoodKind: Int] = [:]
        var total = 0

        for climb in store.climbings {
            let y = Calendar.current.component(.year, from: climb.date)
            guard y == year else { continue }
            counts[climb.mood, default: 0] += 1
            total += 1
        }

        guard total > 0 else { return [] }

        let sorted = counts
            .map { (kind: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)

        let percents = sorted.map { item -> (MoodKind, Int) in
            let p = Int(round(Double(item.count) / Double(total) * 100.0))
            return (item.kind, p)
        }

        return Array(percents)
    }

    private func buildTipText() -> String {
        let doneGrades = Set(store.climbings.compactMap { climb -> ClimbingGrade? in
            guard let route = store.routes.first(where: { $0.id == climb.routeId }) else { return nil }
            return route.grade
        })

        let all = ClimbingGrade.allCases.sorted(by: { $0.rank < $1.rank })

        guard let bestDone = doneGrades.max(by: { $0.rank < $1.rank }) else {
            return "Start with 4 — you’re ready!"
        }

        if let next = all.first(where: { $0.rank > bestDone.rank && !doneGrades.contains($0) }) {
            return "Try \(next.rawValue) — you’re ready!"
        }

        if let higher = all.first(where: { $0.rank > bestDone.rank }) {
            return "Try \(higher.rawValue) — you’re ready!"
        }

        return "Keep going — you’re ready!"
    }


    private func difficultyDomain() -> DifficultyDomain {
        let all = ClimbingGrade.allCases.sorted(by: { $0.rank < $1.rank })
        guard let minG = all.first, let maxG = all.last else {
            return DifficultyDomain(min: 0, max: 1, axisValues: [0, 1])
        }

        let minRank = minG.rank
        let maxRank = maxG.rank

        let midRank = rankClosest(to: (minRank + maxRank) / 2, in: all.map { $0.rank })

        return DifficultyDomain(
            min: minRank,
            max: maxRank,
            axisValues: uniqueSorted([minRank, midRank, maxRank])
        )
    }

    private func gradeLabel(forRank rank: Int) -> String {
        if let g = ClimbingGrade.allCases.first(where: { $0.rank == rank }) {
            return g.rawValue
        }
        let nearest = nearestGrade(toRank: rank)
        return nearest?.rawValue ?? "\(rank)"
    }

    private func nearestGrade(toRank rank: Int) -> ClimbingGrade? {
        let all = ClimbingGrade.allCases
        return all.min(by: { abs($0.rank - rank) < abs($1.rank - rank) })
    }

    private func rankClosest(to target: Int, in ranks: [Int]) -> Int {
        guard let best = ranks.min(by: { abs($0 - target) < abs($1 - target) }) else { return target }
        return best
    }

    private func uniqueSorted(_ values: [Int]) -> [Int] {
        Array(Set(values)).sorted()
    }


    private func shortMonthTitle(_ month: Int) -> String {
        switch month {
        case 1: return "Jan"
        case 2: return "Feb"
        case 3: return "Mar"
        case 4: return "Apr"
        case 5: return "May"
        case 6: return "Jun"
        case 7: return "Jul"
        case 8: return "Aug"
        case 9: return "Sep"
        case 10: return "Oct"
        case 11: return "Nov"
        case 12: return "Dec"
        default: return ""
        }
    }
}


private struct MonthlyDifficultyPoint: Identifiable {
    let id = UUID()
    let monthIndex: Int
    let gradeRank: Int
}

private struct DifficultyDomain {
    let min: Int
    let max: Int
    let axisValues: [Int]
}

#Preview {
    NavigationStack {
        StatisticsView()
            .environmentObject(ClimbingStore())
            .navigationBarBackButtonHidden()
    }
}

#Preview {
    StatisticsView()
        .environmentObject(ClimbingStore())
}
