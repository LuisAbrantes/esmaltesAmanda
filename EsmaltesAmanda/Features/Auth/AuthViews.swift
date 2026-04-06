import SwiftUI

struct AuthGateView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TabRouter.self) private var tabRouter
    @State private var selectedTab: AppTab = .collection

    var body: some View {
        Group {
            switch appModel.authPhase {
            case .checking:
                ZStack {
                    AppGradientBackground()
                    ProgressView("Preparando sua colecao...")
                        .controlSize(.large)
                }

            case .signedIn:
                appShell

            case .signedOut, .failed:
                LoginView()
            }
        }
    }

    private var appShell: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: tabRouter.binding(for: .collection)) {
                CollectionView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .polishDetail(let polishID):
                            PolishDetailView(polishID: polishID)
                        }
                    }
            }
            .tabItem { Label(AppTab.collection.title, systemImage: AppTab.collection.systemImage) }
            .tag(AppTab.collection)

            NavigationStack {
                PolishEditorView(mode: .create) { savedPolish in
                    selectedTab = .collection
                    tabRouter.replacePath(for: .collection, with: [.polishDetail(savedPolish.id)])
                }
            }
            .tabItem { Label(AppTab.add.title, systemImage: AppTab.add.systemImage) }
            .tag(AppTab.add)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
            .tag(AppTab.profile)
        }
        .tint(AppTheme.accent)
    }
}

struct LoginView: View {
    @Environment(AppModel.self) private var appModel

    @State private var email: String = "amanda@example.com"
    @State private var isSending = false

    var body: some View {
        ZStack {
            AppGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Esmaltes da Amanda")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Uma colecao pessoal para organizar cores, marcas, acabamentos, fotos e lembrancas de cada esmalte.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    AppBanner(
                        title: appModel.dataSourceMode.title,
                        message: appModel.dataSourceMode.subtitle,
                        systemImage: "shippingbox"
                    )

                    if case .failed(let message) = appModel.authPhase {
                        AppBanner(
                            title: "Não foi possível continuar",
                            message: message,
                            systemImage: "exclamationmark.triangle"
                        )
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Acesso")
                                .font(.title3.weight(.bold))

                            TextField("E-mail", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button {
                                Task {
                                    isSending = true
                                    await appModel.authenticate(email: email)
                                    isSending = false
                                }
                            } label: {
                                HStack {
                                    if isSending {
                                        ProgressView()
                                            .tint(.white)
                                    }

                                    Text("Entrar")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Escopo inicial")
                                .font(.headline)

                            Label("Colecao com busca, filtros e detalhe", systemImage: "checkmark.seal")
                            Label("Cadastro com marca, cor, tom, acabamento e tags", systemImage: "camera.filters")
                            Label("Fluxo pronto para Supabase Auth, RLS e Storage", systemImage: "lock.shield")
                        }
                        .foregroundStyle(AppTheme.ink)
                    }
                }
                .padding(20)
            }
        }
    }
}

#Preview("Login") {
    LoginView()
        .environment(AppBootstrap.makeDefaultModel())
}

