import SwiftUI

struct CollectionView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isFilterSheetPresented = false

    var body: some View {
        List {
            Section {
                summaryHeader
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
            .listRowBackground(Color.clear)

            if let collectionErrorMessage = appModel.collectionErrorMessage {
                Section {
                    AppBanner(
                        title: "Falha ao sincronizar",
                        message: collectionErrorMessage,
                        systemImage: "wifi.exclamationmark"
                    )
                }
                .listRowBackground(Color.clear)
            }

            if appModel.filteredPolishes.isEmpty {
                Section {
                    AppEmptyStateView(
                        title: appModel.filters.isEmpty ? "Sua colecao vai aparecer aqui" : "Nenhum esmalte bateu com os filtros",
                        message: appModel.filters.isEmpty
                            ? "Comece cadastrando os esmaltes favoritos dela e use as tags para criar uma organizacao mais pessoal."
                            : "Limpe os filtros ou ajuste a busca para voltar a encontrar esmaltes.",
                        systemImage: appModel.filters.isEmpty ? "paintpalette" : "magnifyingglass",
                        actionTitle: appModel.filters.isEmpty ? nil : "Limpar filtros"
                    ) {
                        appModel.filters = PolishFilters()
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section("Colecao") {
                    ForEach(appModel.filteredPolishes) { polish in
                        NavigationLink(value: AppRoute.polishDetail(polish.id)) {
                            CollectionRow(polish: polish)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Colecao")
        .searchable(
            text: Binding(
                get: { appModel.filters.query },
                set: { appModel.filters.query = $0 }
            ),
            prompt: "Buscar por nome ou marca"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isFilterSheetPresented = true
                } label: {
                    Label("Filtros", systemImage: "line.3.horizontal.decrease.circle")
                }

                Button {
                    Task { await appModel.refreshCollection() }
                } label: {
                    Label("Atualizar", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            NavigationStack {
                CollectionFiltersView()
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            if appModel.polishes.isEmpty {
                await appModel.refreshCollection()
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Visao geral")
                .font(.headline.weight(.bold))

            HStack(spacing: 12) {
                AppMetricCard(
                    title: "Na tela",
                    value: "\(appModel.filteredPolishes.count)",
                    systemImage: "circle.grid.2x2"
                )

                AppMetricCard(
                    title: "Marcas",
                    value: "\(appModel.totalBrands)",
                    systemImage: "tag"
                )
            }

            if appModel.filters.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        if let family = appModel.filters.colorFamily {
                            AppTagChip(text: family.title, isSelected: true)
                        }

                        if let tone = appModel.filters.tone {
                            AppTagChip(text: tone.title, isSelected: true)
                        }

                        if let finish = appModel.filters.finish {
                            AppTagChip(text: finish.title, isSelected: true)
                        }

                        ForEach(Array(appModel.filters.selectedTagNames).sorted(), id: \.self) { tag in
                            AppTagChip(text: tag.capitalized, isSelected: true)
                        }
                    }
                }
            }
        }
    }
}

private struct CollectionRow: View {
    let polish: Polish

    var body: some View {
        HStack(spacing: 14) {
            CollectionThumbnail(path: polish.photoPath)

            VStack(alignment: .leading, spacing: 6) {
                Text(polish.name)
                    .font(.headline)

                Text(polish.brandDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    AppTagChip(text: polish.colorFamily.title)
                    AppTagChip(text: polish.finish.title)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 14, height: 14)

                Text(polish.tone.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct CollectionThumbnail: View {
    let path: String?

    @Environment(AppModel.self) private var appModel
    @State private var imageData: Data?

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppTheme.accentSoft, AppTheme.secondarySurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                }
            }
        }
        .frame(width: 62, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task(id: path) {
            imageData = await appModel.photoData(for: path)
        }
    }
}

private struct CollectionFiltersView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Ordenacao") {
                Picker("Ordenar por", selection: Binding(
                    get: { appModel.filters.sort },
                    set: { appModel.filters.sort = $0 }
                )) {
                    ForEach(PolishSort.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }

            Section("Categoria") {
                Picker("Familia de cor", selection: Binding(
                    get: { appModel.filters.colorFamily },
                    set: { appModel.filters.colorFamily = $0 }
                )) {
                    Text("Todas").tag(ColorFamily?.none)
                    ForEach(ColorFamily.allCases) { family in
                        Text(family.title).tag(Optional(family))
                    }
                }

                Picker("Tom", selection: Binding(
                    get: { appModel.filters.tone },
                    set: { appModel.filters.tone = $0 }
                )) {
                    Text("Todos").tag(PolishTone?.none)
                    ForEach(PolishTone.allCases) { tone in
                        Text(tone.title).tag(Optional(tone))
                    }
                }

                Picker("Acabamento", selection: Binding(
                    get: { appModel.filters.finish },
                    set: { appModel.filters.finish = $0 }
                )) {
                    Text("Todos").tag(PolishFinish?.none)
                    ForEach(PolishFinish.allCases) { finish in
                        Text(finish.title).tag(Optional(finish))
                    }
                }
            }

            if appModel.brands.isEmpty == false {
                Section("Marcas") {
                    ForEach(appModel.brands) { brand in
                        Toggle(
                            brand.name,
                            isOn: Binding(
                                get: { appModel.filters.selectedBrandIDs.contains(brand.id) },
                                set: { newValue in
                                    if newValue {
                                        appModel.filters.selectedBrandIDs.insert(brand.id)
                                    } else {
                                        appModel.filters.selectedBrandIDs.remove(brand.id)
                                    }
                                }
                            )
                        )
                    }
                }
            }

            if appModel.availableTags.isEmpty == false {
                Section("Tags") {
                    ForEach(appModel.availableTags) { tag in
                        Toggle(
                            tag.name.capitalized,
                            isOn: Binding(
                                get: { appModel.filters.selectedTagNames.contains(tag.normalizedName) },
                                set: { newValue in
                                    if newValue {
                                        appModel.filters.selectedTagNames.insert(tag.normalizedName)
                                    } else {
                                        appModel.filters.selectedTagNames.remove(tag.normalizedName)
                                    }
                                }
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle("Filtros")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { dismiss() }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Limpar") {
                    appModel.filters = PolishFilters()
                }
            }
        }
    }
}

#Preview("Colecao") {
    NavigationStack {
        CollectionView()
            .environment(AppBootstrap.makeDefaultModel())
            .environment(TabRouter())
    }
}
