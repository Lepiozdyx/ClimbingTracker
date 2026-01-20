import SwiftUI

struct PlacePickerView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selectedPlaceId: UUID?
    let showsCreateButton: Bool
    let onPicked: (UUID) -> Void

    @State private var showCreatePlace = false

    init(
        title: String = "Select Place",
        selectedPlaceId: Binding<UUID?>,
        showsCreateButton: Bool = true,
        onPicked: @escaping (UUID) -> Void
    ) {
        self.title = title
        self._selectedPlaceId = selectedPlaceId
        self.showsCreateButton = showsCreateButton
        self.onPicked = onPicked
    }

    var body: some View {
        ClimbingScreen(
            title: title,
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if store.places.isEmpty {
                        Text("No places yet. Create a place.")
                            .font(AppFont.make(size: 20, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    } else {
                        ForEach(store.places) { place in
                            Button {
                                selectedPlaceId = place.id
                                onPicked(place.id)
                            } label: {
                                HStack {
                                    Text(place.name)
                                        .font(AppFont.make(size: 20, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(place.kind.title)
                                        .font(AppFont.make(size: 18, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.95))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 58)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color(hex: selectedPlaceId == place.id ? "#00A8E1" : "#AFAFAF"))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsCreateButton {
                Button {
                    showCreatePlace = true
                } label: {
                    Image(.plusButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationDestination(isPresented: $showCreatePlace) {
            CreatePlaceView()
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
    }
}
