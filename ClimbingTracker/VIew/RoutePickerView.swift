import SwiftUI

struct RoutePickerView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    let title: String
    let placeId: UUID?
    @Binding var selectedRouteId: UUID?
    let showsCreateButton: Bool
    let onPicked: (UUID) -> Void
    let onCreateRoute: () -> Void

    init(
        title: String = "Select Route",
        placeId: UUID?,
        selectedRouteId: Binding<UUID?>,
        showsCreateButton: Bool = true,
        onPicked: @escaping (UUID) -> Void,
        onCreateRoute: @escaping () -> Void
    ) {
        self.title = title
        self.placeId = placeId
        self._selectedRouteId = selectedRouteId
        self.showsCreateButton = showsCreateButton
        self.onPicked = onPicked
        self.onCreateRoute = onCreateRoute
    }

    private var routesForPlace: [Route] {
        guard let pid = placeId else { return [] }
        return store.routes.filter { $0.placeId == pid }
    }

    var body: some View {
        ClimbingScreen(
            title: title,
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if placeId == nil {
                        Text("Pick a place first.")
                            .font(AppFont.make(size: 20, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    } else if routesForPlace.isEmpty {
                        Text("No routes for this place yet.")
                            .font(AppFont.make(size: 20, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                            .onAppear { onCreateRoute() }
                    } else {
                        ForEach(routesForPlace) { route in
                            Button {
                                selectedRouteId = route.id
                                onPicked(route.id)
                            } label: {
                                HStack {
                                    Text(route.name)
                                        .font(AppFont.make(size: 24, weight: .regular))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Spacer()
                                    Rectangle()
                                        .frame(width: 2, height: 27, alignment: .center)
                                        .foregroundStyle(.white)
                                    Text(route.grade.rawValue)
                                        .font(AppFont.make(size: 24, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.95))
                                        .lineLimit(1)
                                    Rectangle()
                                        .frame(width: 2, height: 27, alignment: .center)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 58)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color(hex: selectedRouteId == route.id ? "#00A8E1" : "#AFAFAF"))
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
            if showsCreateButton, placeId != nil {
                Button { onCreateRoute() } label: {
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
    }
}

#Preview {
    RoutePickerView(title: "123", placeId: UUID(), selectedRouteId: .constant(UUID()), showsCreateButton: true) { UUID in
        
    } onCreateRoute: {
        
    }
    .environmentObject(ClimbingStore())

}
