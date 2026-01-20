import SwiftUI

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ClimbingStore
    @State private var showAddClimbing = false

    private let fabSize: CGFloat = 70
    private let fabTrailingPadding: CGFloat = 16
    private let fabBottomPaddingAboveTabBar: CGFloat = 16

    var body: some View {
        ClimbingScreen(
            title: "Home",
            showsBackButton: false,
            onBackTap: nil
        ) {
            content
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .navigationDestination(isPresented: $showAddClimbing) {
            CreateEditClimbing(editingClimbing: nil)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if store.climbings.isEmpty {
            VStack {
                Spacer()

                Text("There's nothing here yet. Add an climb.")
                    .font(AppFont.make(size: 24, weight: .expandedHeavy))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(store.climbings) { climbing in
                        NavigationLink {
                            ClimbingDetailView(climbingId: climbing.id)
                                .environmentObject(store)
                                .navigationBarBackButtonHidden()
                        } label: {
                            HomeClimbingCard(
                                climbing: climbing,
                                place: store.places.first { $0.id == climbing.placeId },
                                route: store.routes.first { $0.id == climbing.routeId }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var addButton: some View {
        Button {
            showAddClimbing = true
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
}

private struct HomeClimbingCard: View {
    let climbing: Climbing
    let place: Place?
    let route: Route?

    var body: some View {
        VStack(spacing: 8) {

            Text(place?.name ?? "Unknown")
                .font(AppFont.make(size: 24, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)

            Rectangle()
                .fill(Color.white)
                .frame(height: 2)

            Text(dateText)
                .font(AppFont.make(size: 17, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)

            Image(placeImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 60)

            Spacer(minLength: 0)

            bottomRow
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#00A8E1"))
        .clipShape(RoundedRectangle(cornerRadius: 21))
    }


    
    private var bottomRow: some View {
        ZStack {
            Text("Difficulty: \(route?.grade.rawValue ?? "-")")
                .font(AppFont.make(size: 16, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Image(resultImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
        }
    }


    private var placeImageName: String {
        switch place?.kind {
        case .natural: return "place_natural"
        case .climbing: return "place_climbing"
        default: return "place_natural"
        }
    }

    private var resultImageName: String {
        climbing.result == .complete ? "result_complete" : "result_fail"
    }

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM"
        return f.string(from: climbing.date)
    }
}
