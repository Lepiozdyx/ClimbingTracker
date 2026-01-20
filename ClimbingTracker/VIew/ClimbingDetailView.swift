
import SwiftUI
import UIKit

struct ClimbingDetailView: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    let climbingId: UUID

    @State private var showDeleteAlert = false

    private var climbing: Climbing? {
        store.climbings.first(where: { $0.id == climbingId })
    }

    private var place: Place? {
        guard let c = climbing else { return nil }
        return store.places.first(where: { $0.id == c.placeId })
    }

    private var route: Route? {
        guard let c = climbing else { return nil }
        return store.routes.first(where: { $0.id == c.routeId })
    }

    var body: some View {
        ClimbingScreen(
            title: "Climbing",
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            if let c = climbing {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerBlock(
                            placeName: place?.name ?? "Unknown",
                            dateText: CalendarLogic.prettyMonthDay(from: c.date),
                            placeKindText: place?.kind.title ?? "",
                            tries: c.attempts
                        )

                        iconsRow(
                            mood: c.mood,
                            weather: c.weather,
                            result: c.result
                        )

                        Text("Photos")
                            .font(AppFont.make(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.top, 6)

                        photosRow(photos: c.photos)

                        Text("Note")
                            .font(AppFont.make(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.top, 6)

                        noteBlock(text: c.note)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Climbing not found")
                        .font(AppFont.make(size: 22, weight: .bold))
                        .foregroundStyle(.gray)
                    Button("Back") { dismiss() }
                        .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showDeleteAlert = true
            } label: {
                Image(.delButton)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
        }
        .alert("Delete climbing?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteClimbing() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func deleteClimbing() {
        store.deleteClimbing(id: climbingId)
        dismiss()
    }

    private func headerBlock(placeName: String, dateText: String, placeKindText: String, tries: Int) -> some View {
        VStack(spacing: 6) {
            Text(placeName)
                .font(AppFont.make(size: 38, weight: .heavy))
                .foregroundStyle(Color(hex: "00A8E1"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(dateText)
                .font(AppFont.make(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "#232F3E"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !placeKindText.isEmpty {
                Text(placeKindText)
                    .font(AppFont.make(size: 20, weight: .regular))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Text("Tries \(tries)")
                .font(AppFont.make(size: 20, weight: .regular))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 2)
    }

    private func iconsRow(mood: MoodKind, weather: WeatherKind, result: ClimbingResult) -> some View {
        HStack(spacing: 16) {
            Image(mood.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(UIConstants.navBarAccent, lineWidth: 2)
                    .frame(width: 44, height: 44)

                Image(weather.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }

            Image(place?.kind == .natural ? "place_natural" : "place_climbing")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            Image(result == .complete ? "result_complete" : "result_fail")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 10)
        .frame(height: 68)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#232F3E"))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.top, 6)
    }

    private func photosRow(photos: [ClimbingPhoto]) -> some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let totalSpacing = spacing * 2
            let w = floor((geo.size.width - totalSpacing) / 3)
            let h = floor(w * (118.0 / 92.0))

            HStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { index in
                    photoSlot(index: index, width: w, height: h, photos: photos)
                }
            }
            .frame(width: geo.size.width, height: h, alignment: .leading)
        }
        .frame(height: 150)
    }

    private func photoSlot(index: Int, width: CGFloat, height: CGFloat, photos: [ClimbingPhoto]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                .frame(width: width, height: height)

            if index < photos.count,
               let data = store.photoData(for: photos[index]),
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(14)
            } else {
                Image("photo_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(width * 0.35, 30), height: min(height * 0.35, 30))
                    .opacity(0.85)
            }
        }
    }

    private func noteBlock(text: String) -> some View {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Group {
            if clean.isEmpty {
                Text("No note")
                    .font(AppFont.make(size: 16, weight: .regular))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(clean)
                    .font(AppFont.make(size: 16, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .background(Color.white)
        
    }
}

private extension CalendarLogic {
    static func prettyMonthDay(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "LLLL, d"
        let raw = f.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

#Preview {
    NavigationStack {
        ClimbingDetailView(climbingId: UUID())
            .environmentObject(ClimbingStore())
            .navigationBarBackButtonHidden()
    }
}
