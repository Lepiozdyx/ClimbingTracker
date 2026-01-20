import SwiftUI

struct CreatePlaceView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var kind: PlaceKind = .natural

    var body: some View {
        ClimbingScreen(
            title: "Add Place",
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            VStack(spacing: 8) {
                titleField
                kindSegment

                Spacer()

                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 26)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var titleField: some View {
        ZStack(alignment: .leading) {
            if title.isEmpty {
                Text("Title")
                    .font(AppFont.make(size: 22, weight: .bold))
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .padding(.horizontal, 18)
            }

            TextField("", text: $title)
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

    private var kindSegment: some View {
        HStack(spacing: 0) {
            segmentButton(
                title: PlaceKind.natural.title,
                isSelected: kind == .natural,
                onTap: { kind = .natural }
            )

            segmentButton(
                title: PlaceKind.climbing.title,
                isSelected: kind == .climbing,
                onTap: { kind = .climbing }
            )
        }
        .frame(height: 54)
        .padding(6)
        .background(Color(hex: "#EFEFEF"))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }

    private func segmentButton(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFont.make(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func onSaveTap() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        store.addPlace(
            name: cleanTitle,
            kind: kind,
            details: ""
        )

        dismiss()
    }
}

#Preview {
    CreatePlaceView()
        .environmentObject(ClimbingStore())
        .preferredColorScheme(.dark)
        
}
