import SwiftUI

struct CreateRouteView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    let initialPlaceId: UUID

    @State private var name: String = ""
    @State private var selectedPlaceId: UUID?
    @State private var grade: ClimbingGrade = .g5c
    @State private var kind: RouteKind = .sports
    @State private var details: String = ""

    @State private var showSelectPlace = false

    init(placeId: UUID) {
        self.initialPlaceId = placeId
    }

    var body: some View {
        ClimbingScreen(
            title: "Create Route",
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    nameField
                    placeDropdown

                    Text("Category")
                        .font(AppFont.make(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: "#232F3E"))
                        .padding(.top, 8)

                    gradeGrid

                    Text("Type")
                        .font(AppFont.make(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: "#232F3E"))
                        .padding(.top, 8)

                    typeRow

                    Text("Description")
                        .font(AppFont.make(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: "#232F3E"))
                        .padding(.top, 8)

                    descriptionBox

                    saveButton
                        .padding(.top, 14)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            if selectedPlaceId == nil {
                selectedPlaceId = initialPlaceId
            }
        }
        .navigationDestination(isPresented: $showSelectPlace) {
            PlacePickerView(
                title: "Select Place",
                selectedPlaceId: Binding(
                    get: { selectedPlaceId },
                    set: { selectedPlaceId = $0 }
                ),
                showsCreateButton: true,
                onPicked: { _ in }
            )
            .environmentObject(store)
            .navigationBarBackButtonHidden()
        }
    }

    private var nameField: some View {
        ZStack(alignment: .leading) {
            if name.isEmpty {
                Text("Name")
                    .font(AppFont.make(size: 24, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
            }

            TextField("", text: $name)
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .frame(height: 58)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )
        )
    }

    private var placeDropdown: some View {
        Button { showSelectPlace = true } label: {
            HStack {
                Text(placeTitleText().isEmpty ? "Place" : placeTitleText())
                    .font(AppFont.make(size: 24, weight: .medium))
                    .foregroundStyle(placeTitleText().isEmpty ? .gray : .black)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var gradeGrid: some View {
        FixedFiveGrid(
            items: ClimbingGrade.allCases,
            spacing: 10
        ) { item, w in
            ChipButton(
                title: item.rawValue,
                isSelected: grade == item,
                fixedWidth: w,
                cornerRadius: 14,
                onTap: { grade = item }
            )
        }
    }

    private var typeRow: some View {
        HStack(spacing: 12) {
            ForEach(RouteKind.allCases) { item in
                ChipButton(
                    title: item.title,
                    isSelected: kind == item,
                    fixedWidth: nil,
                    cornerRadius: 16,
                    fontSize: 15,
                    fontWeight: .medium,
                    onTap: { kind = item }
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var descriptionBox: some View {
        ZStack(alignment: .topLeading) {
            if details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Text")
                    .font(AppFont.make(size: 16, weight: .regular))
                    .foregroundStyle(.black.opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $details)
                .font(AppFont.make(size: 16, weight: .regular))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                .background(Color.white)
        }
        .frame(height: 160)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var saveButton: some View {
        Button(action: onSaveTap) {
            Text("Save")
                .font(AppFont.make(size: 24, weight: .expandedHeavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(UIConstants.navBarAccent)
                .cornerRadius(18)
                .opacity(canSave ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private var canSave: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanName.isEmpty && selectedPlaceId != nil
    }

    private func placeTitleText() -> String {
        guard let id = selectedPlaceId,
              let place = store.places.first(where: { $0.id == id }) else { return "" }
        return place.name
    }

    private func onSaveTap() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        guard let placeId = selectedPlaceId else { return }

        store.addRoute(
            placeId: placeId,
            name: cleanName,
            grade: grade,
            kind: kind,
            details: details
        )

        dismiss()
    }
}

#Preview {
    CreateRouteView(placeId: UUID())
        .environmentObject(ClimbingStore())
}


private struct ChipButton: View {
    let title: String
    let isSelected: Bool

    var fixedWidth: CGFloat? = nil
    var cornerRadius: CGFloat = 14

    var fontSize: CGFloat = 15
    var fontWeight: AppFont.Weight = .medium

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFont.make(size: fontSize, weight: fontWeight)) // ✅ medium 15
                .foregroundStyle(isSelected ? .white : .black)
                .frame(width: fixedWidth, height: 34)
                .frame(maxWidth: fixedWidth == nil ? .infinity : nil) // ✅ удобно для typeRow
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isSelected ? UIConstants.navBarAccent : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
private struct FlexibleChipGrid<Item: Hashable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content

    init(items: [Item], spacing: CGFloat = 10, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {

            GeometryReader { geo in
                let maxWidth = geo.size.width

                VStack(alignment: .leading, spacing: spacing) {
                    buildRows(maxWidth: maxWidth)
                }
            }
            .frame(height: calculatedHeight())
        }
    }

    private func buildRows(maxWidth: CGFloat) -> some View {
        var rows: [[Item]] = []
        var current: [Item] = []
        var currentWidth: CGFloat = 0

        for item in items {
            let w = estimatedChipWidth(for: item)

            if current.isEmpty {
                current = [item]
                currentWidth = w
            } else if currentWidth + spacing + w <= maxWidth {
                current.append(item)
                currentWidth += spacing + w
            } else {
                rows.append(current)
                current = [item]
                currentWidth = w
            }
        }

        if !current.isEmpty {
            rows.append(current)
        }

        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func estimatedChipWidth(for item: Item) -> CGFloat {
        let str = String(describing: item)
        let base = CGFloat(str.count) * 10
        return max(50, base + 38)
    }

    private func calculatedHeight() -> CGFloat {
        return 220
    }
}

private struct FixedFiveGrid<Item: Hashable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item, CGFloat) -> Content

    init(items: [Item], spacing: CGFloat = 10, @ViewBuilder content: @escaping (Item, CGFloat) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let columns: CGFloat = 5
            let totalSpacing = spacing * (columns - 1)
            let chipWidth = floor((geo.size.width - totalSpacing) / columns)

            let gridColumns = Array(repeating: GridItem(.fixed(chipWidth), spacing: spacing, alignment: .leading), count: Int(columns))

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: spacing) {
                ForEach(items, id: \.self) { item in
                    content(item, chipWidth)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: gridHeight(itemCount: items.count))
    }

    private func gridHeight(itemCount: Int) -> CGFloat {
        let rows = Int(ceil(Double(itemCount) / 5.0))
        let chipH: CGFloat = 34
        return CGFloat(rows) * chipH + CGFloat(max(0, rows - 1)) * spacing
    }
}

