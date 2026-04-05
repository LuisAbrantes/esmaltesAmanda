import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let user = appModel.currentUser {
                    AppCard {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentSoft)
                                    .frame(width: 72, height: 72)

                                Text(user.initials)
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(AppTheme.ink)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.displayName)
                                    .font(.title2.weight(.bold))

                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                AppBanner(
                    title: appModel.dataSourceMode.title,
                    message: appModel.dataSourceMode.subtitle,
                    systemImage: "server.rack"
                )

                HStack(spacing: 12) {
                    AppMetricCard(title: "Esmaltes", value: "\(appModel.polishes.count)", systemImage: "paintpalette")
                    AppMetricCard(title: "Tags", value: "\(appModel.totalTags)", systemImage: "tag.circle")
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Checklist do proximo passo")
                            .font(.headline)

                        Label("Trocar o modo demo pela camada live do Supabase", systemImage: "arrow.triangle.branch")
                        Label("Configurar magic link e deep link customizado", systemImage: "link.badge.plus")
                        Label("Validar upload de fotos com Storage e RLS", systemImage: "lock.doc")
                    }
                    .foregroundStyle(AppTheme.ink)
                }

                Button(role: .destructive) {
                    Task { await appModel.signOut() }
                } label: {
                    Text("Sair")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(20)
        }
        .background(AppGradientBackground())
        .navigationTitle("Perfil")
    }
}

#Preview("Perfil") {
    NavigationStack {
        ProfileView()
            .environment(AppBootstrap.makeDefaultModel())
    }
}

