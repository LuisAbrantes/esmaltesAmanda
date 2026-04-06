import Foundation

#if canImport(Supabase)
import Supabase

@MainActor
enum SupabaseServiceFactory {
    static func makeServices(configuration: SupabaseConfiguration) -> (
        authService: any AuthServiceProtocol,
        repository: any PolishRepositoryProtocol,
        photoStorage: any PhotoStorageServiceProtocol
    ) {
        let client = SupabaseClient(
            supabaseURL: configuration.projectURL,
            supabaseKey: configuration.anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    flowType: .pkce
                )
            )
        )

        let authService = SupabaseAuthService(
            client: client,
            configuration: configuration
        )
        let repository = SupabasePolishRepository(client: client)
        let photoStorage = SupabasePhotoStorageService(client: client)

        return (authService, repository, photoStorage)
    }
}

@MainActor
final class SupabaseAuthService: AuthServiceProtocol {
    private let client: SupabaseClient
    private let configuration: SupabaseConfiguration

    private(set) var currentSession: UserSession?

    init(client: SupabaseClient, configuration: SupabaseConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    func restoreSession() async -> UserSession? {
        do {
            let session = try await client.auth.session
            let mapped = try await makeUserSession(
                userID: session.user.id,
                email: session.user.email ?? ""
            )
            currentSession = mapped
            return mapped
        } catch {
            currentSession = nil
            return nil
        }
    }

    func signIn(email: String) async throws -> UserSession {
        // Fallback robusto de email + senha apenas para v1 (sem verificacao de email real).
        let hardcodedPassword = "DefaultAppPassword2026!"
        
        do {
            let result = try await client.auth.signIn(email: email, password: hardcodedPassword)
            return try await makeUserSession(
                userID: result.user.id,
                email: result.user.email ?? email
            )
        } catch {
            // Se falhou, provavelmente a conta ainda nao existe, entao fazemos sign up
            let result = try await client.auth.signUp(email: email, password: hardcodedPassword)
            
            // Depois do Sign Up no Supabase com "Confirm email" desativado, 
            // a sessao ja vem ativa em result.session (se retornado).
            // Caso contrario, forcamos o signIn logo em seguida.
            if result.session == nil {
                _ = try await client.auth.signIn(email: email, password: hardcodedPassword)
            }
            
            let userResult = try await client.auth.session
            return try await makeUserSession(
                userID: userResult.user.id,
                email: userResult.user.email ?? email
            )
        }
    }

    func handleOpenURL(_ url: URL) async -> UserSession? {
        // Magic link nao e mais suportado na v1
        return nil
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            // Keep logout resilient even if the remote session is already gone.
        }
        currentSession = nil
    }

    private func fetchProfile(id: UUID) async throws -> DBProfileRow? {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString.lowercased())
            .single()
            .execute()
            .value
    }

    private func makeUserSession(userID: UUID, email: String) async throws -> UserSession {
        let profile = try? await fetchProfile(id: userID)
        let fallbackName = email
            .split(separator: "@")
            .first
            .map(String.init)?
            .capitalized ?? "Amanda"

        return UserSession(
            user: UserProfile(
                id: userID,
                email: email,
                displayName: profile?.displayName ?? fallbackName
            )
        )
    }
}

actor SupabasePolishRepository: PolishRepositoryProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchPolishes(for userID: UUID) async throws -> [Polish] {
        async let brandsRows: [DBBrandRow] = client
            .from("brands")
            .select()
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
            .value

        async let tagRows: [DBTagRow] = client
            .from("tags")
            .select()
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
            .value

        async let polishRows: [DBPolishRow] = client
            .from("polishes")
            .select()
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
            .value

        async let mappingRows: [DBPolishTagRow] = client
            .from("polish_tags")
            .select()
            .execute()
            .value

        let brands = try await brandsRows
        let tags = try await tagRows
        let polishes = try await polishRows
        let mappings = try await mappingRows

        return buildPolishes(
            polishes: polishes,
            brands: brands,
            tags: tags,
            mappings: mappings
        )
    }

    func upsertPolish(id: UUID, draft: PolishDraft, userID: UUID) async throws -> Polish {
        let brandRow = try await upsertBrandIfNeeded(name: draft.brandName, userID: userID)
        let tagRows = try await upsertTagsIfNeeded(names: draft.tagNames, userID: userID)

        let payload = DBPolishUpsertRow(
            id: id,
            userID: userID,
            brandID: brandRow?.id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            normalizedName: draft.name.normalizedForSearch,
            colorFamily: draft.colorFamily.rawValue,
            tone: draft.tone.rawValue,
            finish: draft.finish.rawValue,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            photoPath: draft.photoPath,
            isFavorite: false
        )

        let savedRow: DBPolishRow = try await client
            .from("polishes")
            .upsert(payload)
            .select()
            .single()
            .execute()
            .value

        try await client
            .from("polish_tags")
            .delete()
            .eq("polish_id", value: id.uuidString.lowercased())
            .execute()

        if tagRows.isEmpty == false {
            let mappings = tagRows.map {
                DBPolishTagUpsertRow(polishID: savedRow.id, tagID: $0.id)
            }

            try await client
                .from("polish_tags")
                .insert(mappings)
                .execute()
        }

        return mapPolish(
            row: savedRow,
            brandRows: brandRow.map { [$0] } ?? [],
            tagRows: tagRows,
            mappings: tagRows.map { DBPolishTagRow(polishID: savedRow.id, tagID: $0.id) }
        )
    }

    func deletePolish(id: UUID, userID: UUID) async throws {
        try await client
            .from("polishes")
            .delete()
            .eq("id", value: id.uuidString.lowercased())
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
    }

    func brands(for userID: UUID) async throws -> [Brand] {
        let rows: [DBBrandRow] = try await client
            .from("brands")
            .select()
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
            .value

        return rows.map { Brand(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func tags(for userID: UUID) async throws -> [PolishTag] {
        let rows: [DBTagRow] = try await client
            .from("tags")
            .select()
            .eq("user_id", value: userID.uuidString.lowercased())
            .execute()
            .value

        return rows.map { PolishTag(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func upsertBrandIfNeeded(name: String, userID: UUID) async throws -> DBBrandRow? {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedName.isEmpty == false else { return nil }

        let payload = DBBrandUpsertRow(
            userID: userID,
            name: cleanedName,
            normalizedName: cleanedName.normalizedForSearch
        )

        let rows: [DBBrandRow] = try await client
            .from("brands")
            .upsert(payload, onConflict: "user_id,normalized_name")
            .select()
            .execute()
            .value

        return rows.first
    }

    private func upsertTagsIfNeeded(names: [String], userID: UUID) async throws -> [DBTagRow] {
        let uniqueNames = Array(
            Set(names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        ).sorted()

        guard uniqueNames.isEmpty == false else { return [] }

        let payload = uniqueNames.map {
            DBTagUpsertRow(
                userID: userID,
                name: $0,
                normalizedName: $0.normalizedForSearch
            )
        }

        return try await client
            .from("tags")
            .upsert(payload, onConflict: "user_id,normalized_name")
            .select()
            .execute()
            .value
    }

    private func buildPolishes(
        polishes rows: [DBPolishRow],
        brands brandRows: [DBBrandRow],
        tags tagRows: [DBTagRow],
        mappings: [DBPolishTagRow]
    ) -> [Polish] {
        let brandByID = Dictionary(uniqueKeysWithValues: brandRows.map { ($0.id, $0) })
        let tagByID = Dictionary(uniqueKeysWithValues: tagRows.map { ($0.id, $0) })

        return rows
            .map { row in
                let scopedMappings = mappings.filter { $0.polishID == row.id }
                let mappedTags = scopedMappings.compactMap { tagByID[$0.tagID] }
                return mapPolish(
                    row: row,
                    brandRows: row.brandID.flatMap { brandByID[$0].map { [$0] } } ?? [],
                    tagRows: mappedTags,
                    mappings: scopedMappings
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func mapPolish(
        row: DBPolishRow,
        brandRows: [DBBrandRow],
        tagRows: [DBTagRow],
        mappings: [DBPolishTagRow]
    ) -> Polish {
        let brand = brandRows.first.map { Brand(id: $0.id, name: $0.name) }
        let tagByID = Dictionary(uniqueKeysWithValues: tagRows.map { ($0.id, $0) })
        let tags = mappings.compactMap { mapping in
            tagByID[mapping.tagID].map { PolishTag(id: $0.id, name: $0.name) }
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return Polish(
            id: row.id,
            userID: row.userID,
            brand: brand,
            name: row.name,
            colorFamily: ColorFamily(rawValue: row.colorFamily) ?? .nude,
            tone: PolishTone(rawValue: row.tone) ?? .medio,
            finish: PolishFinish(rawValue: row.finish) ?? .cremoso,
            notes: row.notes ?? "",
            photoPath: row.photoPath,
            tags: tags,
            isFavorite: row.isFavorite,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt
        )
    }
}

actor SupabasePhotoStorageService: PhotoStorageServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func uploadMainPhoto(data: Data, for polishID: UUID, userID: UUID, replacing existingPath: String?) async throws -> String {
        let path = "\(userID.uuidString.lowercased())/\(polishID.uuidString.lowercased())/main.jpg"

        if let existingPath, existingPath != path {
            _ = try? await client.storage
                .from("polish-photos")
                .remove(paths: [existingPath])
        }

        try await client.storage
            .from("polish-photos")
            .upload(
                path,
                data: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        return path
    }

    func loadPhotoData(at path: String) async -> Data? {
        try? await client.storage
            .from("polish-photos")
            .download(path: path)
    }

    func deletePhoto(at path: String) async {
        _ = try? await client.storage
            .from("polish-photos")
            .remove(paths: [path])
    }
}

private struct DBProfileRow: Decodable {
    let id: UUID
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

private struct DBBrandRow: Codable {
    let id: UUID
    let userID: UUID
    let name: String
    let normalizedName: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case normalizedName = "normalized_name"
    }
}

private struct DBBrandUpsertRow: Encodable {
    let userID: UUID
    let name: String
    let normalizedName: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case name
        case normalizedName = "normalized_name"
    }
}

private struct DBTagRow: Codable {
    let id: UUID
    let userID: UUID
    let name: String
    let normalizedName: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case normalizedName = "normalized_name"
    }
}

private struct DBTagUpsertRow: Encodable {
    let userID: UUID
    let name: String
    let normalizedName: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case name
        case normalizedName = "normalized_name"
    }
}

private struct DBPolishRow: Codable {
    let id: UUID
    let userID: UUID
    let brandID: UUID?
    let name: String
    let normalizedName: String
    let colorFamily: String
    let tone: String
    let finish: String
    let notes: String?
    let photoPath: String?
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case brandID = "brand_id"
        case name
        case normalizedName = "normalized_name"
        case colorFamily = "color_family"
        case tone
        case finish
        case notes
        case photoPath = "photo_path"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct DBPolishUpsertRow: Encodable {
    let id: UUID
    let userID: UUID
    let brandID: UUID?
    let name: String
    let normalizedName: String
    let colorFamily: String
    let tone: String
    let finish: String
    let notes: String?
    let photoPath: String?
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case brandID = "brand_id"
        case name
        case normalizedName = "normalized_name"
        case colorFamily = "color_family"
        case tone
        case finish
        case notes
        case photoPath = "photo_path"
        case isFavorite = "is_favorite"
    }
}

private struct DBPolishTagRow: Decodable {
    let polishID: UUID
    let tagID: UUID

    enum CodingKeys: String, CodingKey {
        case polishID = "polish_id"
        case tagID = "tag_id"
    }
}

private struct DBPolishTagUpsertRow: Encodable {
    let polishID: UUID
    let tagID: UUID

    enum CodingKeys: String, CodingKey {
        case polishID = "polish_id"
        case tagID = "tag_id"
    }
}

#endif

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
