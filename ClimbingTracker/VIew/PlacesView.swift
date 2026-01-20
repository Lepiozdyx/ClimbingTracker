import SwiftUI

struct PlacesView: View {
    @EnvironmentObject private var store: ClimbingStore

    @State private var showAddPlace = false
    @State private var showPlaceRoutes = false
    @State private var selectedPlaceId: UUID? = nil

    private let fabSize: CGFloat = 70
    private let fabTrailingPadding: CGFloat = 16
    private let fabBottomPaddingAboveTabBar: CGFloat = 16

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ClimbingScreen(
            title: "Places and routes",
            showsBackButton: false,
            onBackTap: nil
        ) {
            ZStack(alignment: .bottomTrailing) {
                content
                fabButton
            }
            .navigationDestination(isPresented: $showAddPlace) {
                CreatePlaceView()
                    .environmentObject(store)
                    .navigationBarBackButtonHidden()
            }
            .navigationDestination(isPresented: $showPlaceRoutes) {
                if let id = selectedPlaceId,
                   let place = store.places.first(where: { $0.id == id }) {
                    PlaceRoutesView(place: place)
                        .environmentObject(store)
                        .navigationBarBackButtonHidden()
                } else {
                    EmptyView()
                        .navigationBarBackButtonHidden()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.places.isEmpty {
            VStack {
                Spacer()

                Text("There's nothing here yet. Add a place.")
                    .font(AppFont.make(size: 24, weight: .expandedHeavy))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(store.places) { place in
                        Button {
                            selectedPlaceId = place.id
                            showPlaceRoutes = true
                        } label: {
                            PlaceCardView(
                                title: "\(place.name) - \(place.kind.title)",
                                subtitle: subtitleForPlace(place),
                                bottomText: bottomTextForPlace(place)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, fabSize + fabBottomPaddingAboveTabBar + 12)
            }
        }
    }

    private var fabButton: some View {
        Button {
            showAddPlace = true
        } label: {
            Image(.plusButton)
                .resizable()
                .scaledToFit()
                .frame(width: fabSize, height: fabSize)
        }
        .buttonStyle(.plain)
        .padding(.trailing, fabTrailingPadding)
        .padding(.bottom, fabBottomPaddingAboveTabBar)
    }

    private func subtitleForPlace(_ place: Place) -> String {
        let count = store.routes.filter { $0.placeId == place.id }.count
        return "Routes: \(count)"
    }

    private func bottomTextForPlace(_ place: Place) -> String {
        let routes = store.routes.filter { $0.placeId == place.id }
        guard let best = routes.max(by: { $0.grade.rank < $1.grade.rank }) else {
            return "No routes yet"
        }
        return "Difficulty: \(best.grade.rawValue)"
    }
}

private struct PlaceCardView: View {
    let title: String
    let subtitle: String
    let bottomText: String

    var body: some View {
        VStack(spacing: 10) {

            Text(title)
                .font(AppFont.make(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(height: 1)
                .padding(.horizontal, 16)

            Text(subtitle)
                .font(AppFont.make(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Text(bottomText)
                .font(AppFont.make(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(height: 170)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(hex: "#00A8E1"))
        .clipShape(RoundedRectangle(cornerRadius: 21))
    }
}

#Preview {
    NavigationStack {
        PlacesView()
            .environmentObject(ClimbingStore())
            .navigationBarBackButtonHidden()
    }
}
