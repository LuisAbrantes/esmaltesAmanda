import SwiftUI

struct PolishDetailView: View {
    let polishID: UUID

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingDeleteConfirmation = false
    @State private var editingPolish: Polish?

    var body: some View {
        Group {
            if let polish = appModel.polish(id: polishID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PolishPhotoView(path: polish.photoPath, height: 260, cornerRadius: 28)

                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(polish.name)
                                    .font(.largeTitle.weight(.bold))

                                Text(polish.brandDisplayName)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    AppTagChip(text: polish.colorFamily.title)
                                    AppTagChip(text: polish.tone.title)
                                    AppTagChip(text: polish.finish.title)
                                }
                            }
                        }

                        if polish.tags.isEmpty == false {
                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Tags")
                                        .font(.headline)

                                    FlowLayout(tags: polish.tags.map(\.name))
                                }
                            }
                        }

                        if polish.notes.isEmpty == false {
                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Notas")
                                        .font(.headline)

                                    Text(polish.notes)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Criado em \(polish.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                                Label("Atualizado em \(polish.updatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock.arrow.circlepath")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                }
                .background(AppGradientBackground())
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Editar") {
                            editingPolish = polish
                        }

                        Button("Excluir", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
                .confirmationDialog(
                    "Excluir esmalte?",
                    isPresented: $isShowingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Excluir", role: .destructive) {
                        Task {
                            try? await appModel.deletePolish(polish)
                            dismiss()
                        }
                    }
                    Button("Cancelar", role: .cancel) {}
                }
                .sheet(item: $editingPolish) { polish in
                    NavigationStack {
                        PolishEditorView(mode: .edit(polish))
                    }
                }
            } else {
                AppEmptyStateView(
                    title: "Esmalte nao encontrado",
                    message: "Esse item foi removido ou ainda nao sincronizou.",
                    systemImage: "questionmark.circle"
                )
                .padding(20)
            }
        }
        .navigationTitle("Detalhe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                AppTagChip(text: tag.capitalized)
            }
        }
    }
}

