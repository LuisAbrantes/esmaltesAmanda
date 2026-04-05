import Foundation

enum PreviewFixtures {
    static let primaryUser = UserProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "amanda@example.com",
        displayName: "Amanda"
    )

    static func seedPolishes() -> [Polish] {
        let risque = Brand(id: UUID(uuidString: "22222222-2222-2222-2222-222222222221")!, name: "Risque")
        let impala = Brand(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, name: "Impala")
        let brilho = PolishTag(id: UUID(uuidString: "33333333-3333-3333-3333-333333333331")!, name: "brilho")
        let festa = PolishTag(id: UUID(uuidString: "33333333-3333-3333-3333-333333333332")!, name: "festa")
        let trabalho = PolishTag(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, name: "trabalho")

        return [
            Polish(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444441")!,
                userID: primaryUser.id,
                brand: risque,
                name: "Rosa Bailarina",
                colorFamily: .rosa,
                tone: .claro,
                finish: .cremoso,
                notes: "Otimo para unhas curtas e para o dia a dia.",
                photoPath: nil,
                tags: [trabalho],
                isFavorite: false,
                createdAt: Date.now.addingTimeInterval(-86_400 * 4),
                updatedAt: Date.now.addingTimeInterval(-86_400 * 2)
            ),
            Polish(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444442")!,
                userID: primaryUser.id,
                brand: impala,
                name: "Noite Estrelada",
                colorFamily: .preto,
                tone: .escuro,
                finish: .glitter,
                notes: "Combina melhor com cobertura por cima.",
                photoPath: nil,
                tags: [brilho, festa],
                isFavorite: true,
                createdAt: Date.now.addingTimeInterval(-86_400),
                updatedAt: Date.now.addingTimeInterval(-3_600)
            ),
            Polish(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444443")!,
                userID: primaryUser.id,
                brand: risque,
                name: "Nude Sereno",
                colorFamily: .nude,
                tone: .medio,
                finish: .transparente,
                notes: "Bom para base e combinacoes minimalistas.",
                photoPath: nil,
                tags: [],
                isFavorite: false,
                createdAt: Date.now.addingTimeInterval(-86_400 * 9),
                updatedAt: Date.now.addingTimeInterval(-86_400 * 7)
            )
        ]
    }
}

@MainActor
final class DemoAuthService: AuthServiceProtocol {
    var currentSession: UserSession?

    func restoreSession() async -> UserSession? {
        currentSession
    }

    func signIn(email: String) async throws -> AuthSignInResult {
        let profile = UserProfile(
            id: PreviewFixtures.primaryUser.id,
            email: email,
            displayName: email
                .split(separator: "@")
                .first
                .map(String.init)?
                .capitalized ?? "Amanda"
        )

        let session = UserSession(user: profile)
        currentSession = session
        return .signedIn(session)
    }

    func handleOpenURL(_ url: URL) async -> UserSession? {
        currentSession
    }

    func signOut() async {
        currentSession = nil
    }
}

actor InMemoryPolishRepository: PolishRepositoryProtocol {
    private var storage: [UUID: [Polish]]

    init(seedPolishes: [Polish]) {
        storage = Dictionary(grouping: seedPolishes, by: \.userID)
    }

    func fetchPolishes(for userID: UUID) async throws -> [Polish] {
        storage[userID, default: []]
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsertPolish(id: UUID, draft: PolishDraft, userID: UUID) async throws -> Polish {
        var items = storage[userID, default: []]
        let existingIndex = items.firstIndex(where: { $0.id == id })
        let now = Date.now
        let existing = existingIndex.map { items[$0] }

        let brand = draft.brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : Brand(id: existing?.brand?.id ?? UUID(), name: draft.brandName.trimmingCharacters(in: .whitespacesAndNewlines))

        let tags = draft.tagNames.map { tagName in
            PolishTag(
                id: UUID(),
                name: tagName
            )
        }

        let polish = Polish(
            id: id,
            userID: userID,
            brand: brand,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorFamily: draft.colorFamily,
            tone: draft.tone,
            finish: draft.finish,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoPath: draft.photoPath,
            tags: uniqueTags(from: tags),
            isFavorite: existing?.isFavorite ?? false,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now
        )

        if let existingIndex {
            items[existingIndex] = polish
        } else {
            items.append(polish)
        }

        storage[userID] = items
        return polish
    }

    func deletePolish(id: UUID, userID: UUID) async throws {
        storage[userID] = storage[userID, default: []].filter { $0.id != id }
    }

    func brands(for userID: UUID) async throws -> [Brand] {
        let values = storage[userID, default: []].compactMap(\.brand)
        return Dictionary(grouping: values, by: \.normalizedName)
            .values
            .compactMap(\.first)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func tags(for userID: UUID) async throws -> [PolishTag] {
        let values = storage[userID, default: []].flatMap(\.tags)
        return Dictionary(grouping: values, by: \.normalizedName)
            .values
            .compactMap(\.first)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func uniqueTags(from tags: [PolishTag]) -> [PolishTag] {
        Dictionary(grouping: tags, by: \.normalizedName)
            .values
            .compactMap(\.first)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

actor InMemoryPhotoStorageService: PhotoStorageServiceProtocol {
    private var storage: [String: Data] = [:]

    func uploadMainPhoto(data: Data, for polishID: UUID, userID: UUID, replacing existingPath: String?) async throws -> String {
        if let existingPath {
            storage.removeValue(forKey: existingPath)
        }

        let path = "\(userID.uuidString)/\(polishID.uuidString)/main.jpg"
        storage[path] = data
        return path
    }

    func loadPhotoData(at path: String) async -> Data? {
        storage[path]
    }

    func deletePhoto(at path: String) async {
        storage.removeValue(forKey: path)
    }
}
