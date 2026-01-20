import SwiftUI
import UIKit
import PhotosUI

struct CreateEditClimbing: View {
    @EnvironmentObject private var store: ClimbingStore
    @Environment(\.dismiss) private var dismiss

    private let editingClimbing: Climbing?
    private var isEditing: Bool { editingClimbing != nil }

    @State private var showPickPlace = false
    @State private var showPickRoute = false
    @State private var showCreateRoute = false

    @State private var selectedPlaceId: UUID?
    @State private var selectedRouteId: UUID?

    @State private var result: ClimbingResult = .complete
    @State private var attemptsText: String = "1"

    @State private var weather: WeatherKind = .sun
    @State private var mood: MoodKind = .happyBig

    @State private var note: String = ""

    @State private var existingPhotos: [ClimbingPhoto] = []
    @State private var newUIImagePhotos: [UIImage] = []

    @State private var showCamera = false
    @State private var showGallery = false

    @State private var showDeleteAlert = false
    @State private var showPhotoSourceDialog = false
    @State private var activePhotoSlotIndex: Int? = nil

    init(editingClimbing: Climbing? = nil) {
        self.editingClimbing = editingClimbing
    }

    var body: some View {
        ClimbingScreen(
            title: isEditing ? "Edit Climbing" : "Create Climbing",
            showsBackButton: true,
            onBackTap: { dismiss() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    dropdownField(
                        title: placeTitleText(),
                        placeholder: "Place",
                        isEnabled: true,
                        onTap: { showPickPlace = true }
                    )

                    dropdownField(
                        title: routeTitleText(),
                        placeholder: "Route",
                        isEnabled: selectedPlaceId != nil,
                        onTap: {
                            guard let pid = selectedPlaceId else { return }
                            let hasRoutes = store.routes.contains(where: { $0.placeId == pid })
                            if hasRoutes {
                                showPickRoute = true
                            } else {
                                showCreateRoute = true
                            }
                        }
                    )

                    resultRow
                    attemptsRow
                    weatherBlock
                    moodBlock
                    photosBlock
                    noteBlock

                    Button(action: onSaveTap) {
                        Text("Save")
                            .font(AppFont.make(size: 24, weight: .expandedHeavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(UIConstants.navBarAccent)
                            .cornerRadius(28)
                            .opacity(canSave ? 1.0 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .padding(.top, 10)

                    if isEditing {
                        Button(action: { showDeleteAlert = true }) {
                            Text("Delete")
                                .font(AppFont.make(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.red)
                                .cornerRadius(26)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                        .alert("Delete climbing?", isPresented: $showDeleteAlert) {
                            Button("Delete", role: .destructive) { onDeleteTap() }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This action cannot be undone.")
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
        .navigationDestination(isPresented: $showPickPlace) {
            PlacePickerView(
                selectedPlaceId: $selectedPlaceId,
                onPicked: { pickedId in
                    if selectedPlaceId != pickedId {
                        selectedPlaceId = pickedId
                        selectedRouteId = nil
                    } else {
                        selectedPlaceId = pickedId
                    }
                    showPickPlace = false
                }
            )
            .environmentObject(store)
            .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $showPickRoute) {
            RoutePickerView(
                placeId: selectedPlaceId,
                selectedRouteId: $selectedRouteId,
                onPicked: { pickedId in
                    selectedRouteId = pickedId
                    showPickRoute = false
                },
                onCreateRoute: {
                    showPickRoute = false
                    showCreateRoute = true
                }
            )
            .environmentObject(store)
            .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $showCreateRoute) {
            if let pid = selectedPlaceId {
                CreateRouteView(placeId: pid)
                    .environmentObject(store)
                    .navigationBarBackButtonHidden()
                    .onDisappear {
                        let routes = store.routes.filter { $0.placeId == pid }
                        if let newest = routes.last {
                            selectedRouteId = newest.id
                        }
                    }
            } else {
                EmptyView()
                    .navigationBarBackButtonHidden()
            }
        }
        .confirmationDialog(
            "Add photo",
            isPresented: $showPhotoSourceDialog,
            titleVisibility: .visible
        ) {
            Button("Camera") { showCamera = true }
            Button("Gallery") { showGallery = true }
            Button("Cancel", role: .cancel) { activePhotoSlotIndex = nil }
        }
        .sheet(isPresented: $showGallery) {
            GalleryPicker { image in
                handlePickedImage(image)
                showGallery = false
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                handlePickedImage(image)
                showCamera = false
            }
        }
        .onAppear {
            preloadIfEditing()
        }
    }

    private var canSave: Bool {
        guard selectedPlaceId != nil else { return false }
        guard selectedRouteId != nil else { return false }
        let attempts = Int(attemptsText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return attempts >= 1
    }

    private var resultRow: some View {
        HStack(spacing: 12) {
            Text("Result")
                .font(AppFont.make(size: 24, weight: .medium))
                .foregroundStyle(.black)

            Spacer()

            resultSegment
                .frame(width: 200)
        }
        .fieldContainer()
    }

    private var resultSegment: some View {
        HStack(spacing: 0) {
            placeStyleSegmentButton(
                title: "Complete",
                isSelected: result == .complete,
                onTap: { result = .complete }
            )

            placeStyleSegmentButton(
                title: "Fail",
                isSelected: result == .fail,
                onTap: { result = .fail }
            )
        }
        .frame(height: 31)
        .padding(5)
        .background(Color(hex: "#EFEFEF"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func placeStyleSegmentButton(
        title: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFont.make(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private var attemptsRow: some View {
        HStack(spacing: 12) {
            Text("Tries")
                .font(AppFont.make(size: 24, weight: .medium))
                .foregroundStyle(.black)

            Spacer()

            TextField("1", text: $attemptsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(AppFont.make(size: 20, weight: .bold))
                .foregroundStyle(.gray)
        }
        .fieldContainer()
    }

    private var weatherBlock: some View {
        VStack(spacing: 10) {
            Text("Weather")
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.black)

            GeometryReader { geo in
                let count = CGFloat(WeatherKind.allCases.count)
                let spacing: CGFloat = 10
                let available = geo.size.width - spacing * (count - 1)
                let raw = floor(available / count)
                let slot = min(max(raw, 28), 44)

                HStack(spacing: spacing) {
                    ForEach(WeatherKind.allCases) { item in
                        Button {
                            weather = item
                        } label: {
                            Image(item == weather ? item.selectedAssetName : item.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: slot, height: slot)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .frame(width: slot, height: slot)
                    }
                }
                .frame(width: geo.size.width, height: slot, alignment: .center)
            }
            .frame(height: 52)
        }
        .padding(.top, 6)
    }

    private var moodBlock: some View {
        VStack(spacing: 10) {
            Text("Mood")
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.black)

            GeometryReader { geo in
                let count = CGFloat(MoodKind.allCases.count)
                let spacing: CGFloat = 10
                let available = geo.size.width - spacing * (count - 1)
                let raw = floor(available / count)
                let slot = min(max(raw, 28), 46)

                HStack(spacing: spacing) {
                    ForEach(MoodKind.allCases) { item in
                        Button {
                            mood = item
                        } label: {
                            Image(item.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: slot, height: slot)
                                .background(
                                    Circle()
                                        .stroke(Color.green, lineWidth: mood == item ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(width: slot, height: slot)
                    }
                }
                .frame(width: geo.size.width, height: slot, alignment: .center)
            }
            .frame(height: 56)
        }
        .padding(.top, 6)
    }

    private var photosBlock: some View {
        VStack(spacing: 10) {
            Text("Photos")
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.black)

            GeometryReader { geo in
                let spacing: CGFloat = 12
                let totalSpacing = spacing * 2
                let w = floor((geo.size.width - totalSpacing) / 3)
                let h = floor(w * (118.0 / 92.0))

                HStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { index in
                        photoSlot(at: index, width: w, height: h)
                    }
                }
                .frame(width: geo.size.width, height: h, alignment: .center)
            }
            .frame(height: 150)
        }
        .padding(.top, 6)
    }

    private var noteBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text \(note.count)/150")
                .font(AppFont.make(size: 14, weight: .medium))
                .foregroundColor(.gray)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)

                TextEditor(text: $note)
                    .font(AppFont.make(size: 16, weight: .regular))
                    .foregroundColor(.black)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: note) { newValue in
                        if newValue.count > 150 {
                            note = String(newValue.prefix(150))
                        }
                    }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 6)
    }
    
    private func dropdownField(
        title: String,
        placeholder: String,
        isEnabled: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            guard isEnabled else { return }
            onTap()
        } label: {
            HStack {
                Text(title.isEmpty ? placeholder : title)
                    .font(AppFont.make(size: 24, weight: .medium))
                    .foregroundStyle(title.isEmpty ? .gray : .black)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
    }

    private func placeTitleText() -> String {
        guard let id = selectedPlaceId,
              let place = store.places.first(where: { $0.id == id }) else { return "" }
        return place.name
    }

    private func routeTitleText() -> String {
        guard let id = selectedRouteId,
              let route = store.routes.first(where: { $0.id == id }) else { return "" }
        return route.name
    }

    private func onSaveTap() {
        guard let placeId = selectedPlaceId else { return }
        guard let routeId = selectedRouteId else { return }

        let attempts = Int(attemptsText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
        let safeAttempts = max(1, attempts)

        if !isEditing {
            store.addClimbing(
                date: Date(),
                placeId: placeId,
                routeId: routeId,
                weather: weather,
                result: result,
                attempts: safeAttempts,
                mood: mood,
                uiImages: newUIImagePhotos,
                photoData: [],
                note: note
            )
            dismiss()
            return
        }

        guard let original = editingClimbing else { return }

        var updated = original
        updated.placeId = placeId
        updated.routeId = routeId
        updated.weather = weather
        updated.result = result
        updated.attempts = safeAttempts
        updated.mood = mood
        updated.note = String(note.prefix(150))

        store.updateClimbing(updated)

        if !newUIImagePhotos.isEmpty {
            store.replaceClimbingPhotos(
                climbingId: original.id,
                uiImages: newUIImagePhotos,
                photoData: [],
                jpegCompressionQuality: 0.82
            )
        } else {
            if existingPhotos.isEmpty && !original.photos.isEmpty {
                store.replaceClimbingPhotos(climbingId: original.id, uiImages: [], photoData: [])
            }
        }

        dismiss()
    }

    private func onDeleteTap() {
        guard let original = editingClimbing else { return }
        store.deleteClimbing(id: original.id)
        dismiss()
    }

    private func preloadIfEditing() {
        guard let item = editingClimbing else { return }
        selectedPlaceId = item.placeId
        selectedRouteId = item.routeId
        result = item.result
        attemptsText = "\(item.attempts)"
        weather = item.weather
        mood = item.mood
        note = item.note
        existingPhotos = item.photos
    }

    private func photoSlot(at index: Int, width: CGFloat, height: CGFloat) -> some View {
        let previews = combinedPhotosForPreview()

        return Button {
            activePhotoSlotIndex = index
            showPhotoSourceDialog = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    .frame(width: width, height: height)

                if index < previews.count {
                    Image(uiImage: previews[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(14)

                    Button {
                        removePhoto(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                } else {
                    Image("photo_placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(width * 0.35, 30), height: min(height * 0.35, 30))
                        .opacity(0.85)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func combinedPhotosForPreview() -> [UIImage] {
        var resultImages: [UIImage] = []

        for photo in existingPhotos {
            guard resultImages.count < 3 else { break }
            if let data = store.photoData(for: photo), let img = UIImage(data: data) {
                resultImages.append(img)
            }
        }

        for img in newUIImagePhotos {
            guard resultImages.count < 3 else { break }
            resultImages.append(img)
        }

        return resultImages
    }

    private func removePhoto(at previewIndex: Int) {
        let existingPreviewCount = existingPhotos
            .compactMap { store.photoData(for: $0) }
            .compactMap { UIImage(data: $0) }
            .prefix(3)
            .count

        if previewIndex < existingPreviewCount {
            if previewIndex < existingPhotos.count {
                existingPhotos.remove(at: previewIndex)
            }
            return
        }

        let newIndex = previewIndex - existingPreviewCount
        if newIndex >= 0 && newIndex < newUIImagePhotos.count {
            newUIImagePhotos.remove(at: newIndex)
        }
    }

    private func handlePickedImage(_ image: UIImage) {
        guard let slot = activePhotoSlotIndex else { return }

        let existingPreviewCount = existingPhotos
            .compactMap { store.photoData(for: $0) }
            .compactMap { UIImage(data: $0) }
            .prefix(3)
            .count

        if slot < existingPreviewCount {
            if slot < existingPhotos.count {
                existingPhotos.remove(at: slot)
            }
        } else {
            let newIndex = slot - existingPreviewCount
            if newIndex >= 0 && newIndex < newUIImagePhotos.count {
                newUIImagePhotos.remove(at: newIndex)
            }
        }

        if combinedPhotosForPreview().count < 3 {
            newUIImagePhotos.append(image)
        }

        activePhotoSlotIndex = nil
    }
}

private extension View {
    func fieldContainer() -> some View {
        self
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(1), lineWidth: 1)
                    )
            )
    }
}


struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct GalleryPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }
            guard provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.onImagePicked(image)
                }
            }
        }
    }
}

#Preview {
    CreateEditClimbing(editingClimbing: nil)
        .environmentObject(ClimbingStore())
}
