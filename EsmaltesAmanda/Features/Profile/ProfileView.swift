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
                        Text("Prontos para Launch!")
                            .font(.headline)

                        Label("Login de E-mail Único Configurado", systemImage: "checkmark.circle.fill")
                        Label("Upload de fotos testado", systemImage: "photo.badge.checkmark")
                        Label("Configurações locais aplicadas e Ícone criado", systemImage: "iphone.gen3.radiowaves.left.and.right")
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

