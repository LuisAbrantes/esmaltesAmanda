import Foundation
import Observation

enum AuthSignInResult: Equatable {
    case magicLinkSent(email: String)
    case signedIn(UserSession)
}

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var currentSession: UserSession? { get }
    func restoreSession() async -> UserSession?
    func signIn(email: String) async throws -> AuthSignInResult
    func handleOpenURL(_ url: URL) async -> UserSession?
    func signOut() async
}

protocol PolishRepositoryProtocol: Sendable {
    func fetchPolishes(for userID: UUID) async throws -> [Polish]
    func upsertPolish(id: UUID, draft: PolishDraft, userID: UUID) async throws -> Polish
    func deletePolish(id: UUID, userID: UUID) async throws
    func brands(for userID: UUID) async throws -> [Brand]
    func tags(for userID: UUID) async throws -> [PolishTag]
}

protocol PhotoStorageServiceProtocol: Sendable {
    func uploadMainPhoto(data: Data, for polishID: UUID, userID: UUID, replacing existingPath: String?) async throws -> String
    func loadPhotoData(at path: String) async -> Data?
    func deletePhoto(at path: String) async
}

enum AppModelError: LocalizedError {
    case missingSession
    case invalidEmail
    case emptyName

    var errorDescription: String? {
        switch self {
        case .missingSession:
            "Nenhuma sessao ativa encontrada."
        case .invalidEmail:
            "Digite um email valido para continuar."
        case .emptyName:
            "Cada esmalte precisa ter pelo menos um nome."
        }
    }
}

@MainActor
@Observable
final class AppModel {
    @ObservationIgnored private let authService: any AuthServiceProtocol
    @ObservationIgnored private let polishRepository: any PolishRepositoryProtocol
    @ObservationIgnored private let photoStorageService: any PhotoStorageServiceProtocol

    let dataSourceMode: DataSourceMode

    var authPhase: AuthPhase = .checking
    var polishes: [Polish] = []
    var brands: [Brand] = []
    var availableTags: [PolishTag] = []
    var filters = PolishFilters()
    var isLoadingCollection = false
    var collectionErrorMessage: String?

    init(
        authService: any AuthServiceProtocol,
        polishRepository: any PolishRepositoryProtocol,
        photoStorageService: any PhotoStorageServiceProtocol,
        dataSourceMode: DataSourceMode
    ) {
        self.authService = authService
        self.polishRepository = polishRepository
        self.photoStorageService = photoStorageService
        self.dataSourceMode = dataSourceMode
    }

    var currentUser: UserProfile? {
        guard case .signedIn(let session) = authPhase else { return nil }
        return session.user
    }

    var filteredPolishes: [Polish] {
        filters.apply(to: polishes)
    }

    var totalBrands: Int {
        brands.count
    }

    var totalTags: Int {
        availableTags.count
    }

    func bootstrap() async {
        if let session = await authService.restoreSession() {
            authPhase = .signedIn(session)
            await refreshCollection()
            return
        }

        authPhase = .signedOut
    }

    func sendMagicLink(to email: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            authPhase = .failed(AppModelError.invalidEmail.localizedDescription)
            return
        }

        do {
            let result = try await authService.signIn(email: trimmedEmail)

            switch result {
            case .magicLinkSent(let email):
                authPhase = .emailSent(email)
            case .signedIn(let session):
                authPhase = .signedIn(session)
                await refreshCollection()
            }
        } catch {
            authPhase = .failed(error.localizedDescription)
        }
    }

    func signOut() async {
        await authService.signOut()
        polishes = []
        brands = []
        availableTags = []
        filters = PolishFilters()
        authPhase = .signedOut
    }

    func handleOpenURL(_ url: URL) async {
        guard let session = await authService.handleOpenURL(url) else {
            return
        }

        authPhase = .signedIn(session)
        await refreshCollection()
    }

    func refreshCollection() async {
        guard let user = currentUser else {
            collectionErrorMessage = AppModelError.missingSession.localizedDescription
            return
        }

        isLoadingCollection = true
        collectionErrorMessage = nil

        do {
            async let fetchedPolishes = polishRepository.fetchPolishes(for: user.id)
            async let fetchedBrands = polishRepository.brands(for: user.id)
            async let fetchedTags = polishRepository.tags(for: user.id)

            polishes = try await fetchedPolishes
            brands = try await fetchedBrands
            availableTags = try await fetchedTags
        } catch {
            collectionErrorMessage = error.localizedDescription
        }

        isLoadingCollection = false
    }

    func savePolish(draft: PolishDraft, existing: Polish?) async throws -> Polish {
        guard let user = currentUser else {
            throw AppModelError.missingSession
        }

        let cleanedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedName.isEmpty == false else {
            throw AppModelError.emptyName
        }

        let polishID = existing?.id ?? UUID()
        var preparedDraft = draft

        if let photoData = draft.photoPreviewData {
            preparedDraft.photoPath = try await photoStorageService.uploadMainPhoto(
                data: photoData,
                for: polishID,
                userID: user.id,
                replacing: existing?.photoPath
            )
        } else if let existing {
            preparedDraft.photoPath = existing.photoPath
        }

        let saved = try await polishRepository.upsertPolish(
            id: polishID,
            draft: preparedDraft,
            userID: user.id
        )

        await refreshCollection()
        return saved
    }

    func deletePolish(_ polish: Polish) async throws {
        guard let user = currentUser else {
            throw AppModelError.missingSession
        }

        try await polishRepository.deletePolish(id: polish.id, userID: user.id)

        if let photoPath = polish.photoPath {
            await photoStorageService.deletePhoto(at: photoPath)
        }

        await refreshCollection()
    }

    func polish(id: UUID) -> Polish? {
        polishes.first(where: { $0.id == id })
    }

    func brandSuggestions(for searchTerm: String) -> [Brand] {
        let term = searchTerm.normalizedForSearch

        guard term.isEmpty == false else {
            return brands
        }

        return brands.filter { $0.normalizedName.contains(term) }
    }

    func photoData(for path: String?) async -> Data? {
        guard let path else { return nil }
        return await photoStorageService.loadPhotoData(at: path)
    }
}
