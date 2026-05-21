import SwiftUI
import SwiftData
import PhotosUI

// MARK: - TaskPhoto モデル拡張
// CleaningModels.swift に TaskPhoto を追加するのではなく、
// PhotosPickerで選択した画像を Data として TaskLog に持たせる設計にする

// MARK: - PhotoRecordView（タスク完了時の写真記録）

struct PhotoRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var log: TaskLog

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var isLoading = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // タスク情報
                    if let task = log.task {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.headline)
                                Text(task.room?.name ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // 撮影・選択ボタン
                    HStack(spacing: 12) {
                        // カメラで撮影
                        Button {
                            showCamera = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2).foregroundStyle(.teal)
                                Text(LocalizationManager.shared.language == .japanese ? "撮影する" : "Take Photo").font(.caption).foregroundStyle(.teal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.teal.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // ライブラリから選択
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2).foregroundStyle(.blue)
                                Text(LocalizationManager.shared.language == .japanese ? "写真を選択" : "Choose Photo").font(.caption).foregroundStyle(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .onChange(of: selectedItems) { _, newItems in
                            loadSelectedPhotos(newItems)
                        }
                    }
                    .padding(.horizontal)

                    // 選択済み写真プレビュー
                    if !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(LocalizationManager.shared.language == .japanese ? "追加する写真 (\(photos.count)枚)" : "Photos to add (\(photos.count))")
                                    .font(.subheadline).fontWeight(.semibold)
                                Spacer()
                                Button(LocalizationManager.shared.language == .japanese ? "すべて削除" : "Remove All") { photos = []; selectedItems = [] }
                                    .font(.caption).foregroundStyle(.red)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(photos.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                            Button {
                                                photos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title3)
                                                    .foregroundStyle(.white)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 既存の写真
                    if !log.photoDataList.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizationManager.shared.language == .japanese ? "記録済みの写真 (\(log.photoDataList.count)枚)" : "Recorded photos (\(log.photoDataList.count))")
                                .font(.subheadline).fontWeight(.semibold)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(log.photoDataList.enumerated()), id: \.offset) { index, data in
                                        if let uiImage = UIImage(data: data) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                                Button {
                                                    log.photoDataList.remove(at: index)
                                                    try? context.save()
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    if isLoading {
                        HStack { Spacer(); ProgressView(LocalizationManager.shared.language == .japanese ? "読み込み中..." : "Loading..."); Spacer() }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizationManager.shared.language == .japanese ? "写真を記録" : "Record Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.save)) { savePhotos() }
                        .fontWeight(.semibold)
                        .disabled(photos.isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $cameraImage)
                    .ignoresSafeArea()
                    .onChange(of: cameraImage) { _, newImage in
                        if let img = newImage {
                            photos.append(img)
                            cameraImage = nil
                        }
                    }
            }
        }
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        isLoading = true
        photos = []
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { photos.append(image) }
                }
            }
            await MainActor.run { isLoading = false }
        }
    }

    private func savePhotos() {
        for image in photos {
            // JPEG圧縮（品質0.7）でサイズを抑える
            if let data = image.jpegData(compressionQuality: 0.7) {
                log.photoDataList.append(data)
            }
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - CameraView（UIImagePickerController ラッパー）

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - PhotoGalleryView（写真一覧・フルスクリーン表示）

struct PhotoGalleryView: View {
    let log: TaskLog
    @State private var selectedIndex: Int? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(log.photoDataList.enumerated()), id: \.offset) { index, data in
                    if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { selectedIndex = index }
                    }
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedIndex.map { IdentifiableInt(value: $0) } },
            set: { selectedIndex = $0?.value }
        )) { item in
            FullScreenPhotoView(
                photos: log.photoDataList.compactMap { UIImage(data: $0) },
                initialIndex: item.value
            )
        }
    }
}

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}

// MARK: - FullScreenPhotoView

struct FullScreenPhotoView: View {
    let photos: [UIImage]
    let initialIndex: Int
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(photos: [UIImage], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(.page)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
                Text("\(currentIndex + 1) / \(photos.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
            }
        }
    }
}
