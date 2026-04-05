import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.89, green: 0.36, blue: 0.39)
    static let accentSoft = Color(red: 0.97, green: 0.89, blue: 0.86)
    static let surface = Color(red: 0.99, green: 0.97, blue: 0.95)
    static let secondarySurface = Color(red: 0.95, green: 0.92, blue: 0.89)
    static let ink = Color(red: 0.21, green: 0.18, blue: 0.18)
}

struct AppGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.96, blue: 0.93),
                Color(red: 0.98, green: 0.91, blue: 0.88),
                Color(red: 0.95, green: 0.88, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.secondarySurface, lineWidth: 1)
            }
    }
}

struct AppMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
    }
}

struct AppTagChip: View {
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? AppTheme.accent : AppTheme.secondarySurface,
                in: Capsule(style: .continuous)
            )
            .foregroundStyle(isSelected ? .white : AppTheme.ink)
    }
}

struct AppEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.title3.weight(.bold))

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct AppBanner: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct PolishPhotoView: View {
    let path: String?
    var inlineData: Data? = nil
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 24

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
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .medium))
                        Text("Sem foto ainda")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.ink)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: path) {
            if let inlineData {
                imageData = inlineData
            } else {
                imageData = await appModel.photoData(for: path)
            }
        }
    }
}
