import PhotosUI
import SwiftUI

enum PolishEditorMode {
    case create
    case edit(Polish)

    var existingPolish: Polish? {
        switch self {
        case .create:
            nil
        case .edit(let polish):
            polish
        }
    }

    var title: String {
        switch self {
        case .create:
            "Adicionar esmalte"
        case .edit:
            "Editar esmalte"
        }
    }
}

struct PolishEditorView: View {
    let mode: PolishEditorMode
    var onSave: (Polish) -> Void = { _ in }

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PolishDraft
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(mode: PolishEditorMode, onSave: @escaping (Polish) -> Void = { _ in }) {
        self.mode = mode
        self.onSave = onSave
        _draft = State(initialValue: PolishDraft(polish: mode.existingPolish))
    }

    var body: some View {
        Form {
            Section("Foto") {
                PolishPhotoView(
                    path: draft.photoPath,
                    inlineData: draft.photoPreviewData,
                    height: 220,
                    cornerRadius: 22
                )

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Selecionar foto", systemImage: "photo.badge.plus")
                }
            }

            Section("Identificacao") {
                TextField("Nome do esmalte", text: $draft.name)

                TextField("Marca", text: $draft.brandName)

                if draft.brandName.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(appModel.brandSuggestions(for: draft.brandName)) { brand in
                                Button(brand.name) {
                                    draft.brandName = brand.name
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }

            Section("Classificacao") {
                Picker("Familia de cor", selection: $draft.colorFamily) {
                    ForEach(ColorFamily.allCases) { family in
                        Text(family.title).tag(family)
                    }
                }

                Picker("Tom", selection: $draft.tone) {
                    ForEach(PolishTone.allCases) { tone in
                        Text(tone.title).tag(tone)
                    }
                }

                Picker("Acabamento", selection: $draft.finish) {
                    ForEach(PolishFinish.allCases) { finish in
                        Text(finish.title).tag(finish)
                    }
                }
            }

            Section("Observacoes") {
                TextField("Tags separadas por virgula", text: $draft.tagsText, axis: .vertical)
                TextField("Notas sobre cobertura, uso ou combinacoes", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Salvar")
                    }
                }
                .disabled(isSaving)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadPhotoData()
        }
        .alert(
            "Nao foi possivel salvar",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() async {
        isSaving = true

        do {
            let savedPolish = try await appModel.savePolish(draft: draft, existing: mode.existingPolish)
            onSave(savedPolish)

            switch mode {
            case .create:
                draft = PolishDraft()
                selectedPhotoItem = nil
            case .edit:
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func loadPhotoData() async {
        guard let selectedPhotoItem else { return }

        do {
            draft.photoPreviewData = try await selectedPhotoItem.loadTransferable(type: Data.self)
            draft.photoPath = nil
        } catch {
            errorMessage = "Nao foi possivel carregar a foto selecionada."
        }
    }
}

#Preview("Novo esmalte") {
    NavigationStack {
        PolishEditorView(mode: .create)
            .environment(AppBootstrap.makeDefaultModel())
    }
}
