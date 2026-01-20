import SwiftUI

struct PlaceRoutesView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    let place: Place
    @State private var showCreateRoute = false

    private let fabSize: CGFloat = 70
    private let fabTrailingPadding: CGFloat = 16
    private let fabBottomPadding: CGFloat = 16

    var body: some View {
        ClimbingScreen(
            title: place.name,
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            let routes = store.routes(for: place.id)

            if routes.isEmpty {
                Text("No routes yet. Add your first route.")
                    .font(AppFont.make(size: 24, weight: .expandedHeavy))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(routes) { route in
                            RouteRowView(route: route)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 100)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showCreateRoute = true }) {
                Image(.plusButton)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fabSize, height: fabSize)
            }
            .buttonStyle(.plain)
            .padding(.trailing, fabTrailingPadding)
            .padding(.bottom, fabBottomPadding)
        }
        .navigationDestination(isPresented: $showCreateRoute) {
            CreateRouteView(placeId: place.id)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
    }
}

struct RouteRowView: View {
    let route: Route

    var body: some View {
        HStack {
            Text(route.name)
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text(route.grade.rawValue)
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(Color.gray.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    PlaceRoutesView(place: Place(name: "Eagle Rock", kind: .natural, details: ""))
        .environmentObject(ClimbingStore())
}
