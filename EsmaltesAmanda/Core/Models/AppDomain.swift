import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case collection
    case add
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collection: "Colecao"
        case .add: "Adicionar"
        case .profile: "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .collection: "square.grid.2x2"
        case .add: "plus.circle"
        case .profile: "person.crop.circle"
        }
    }
}

enum ColorFamily: String, CaseIterable, Codable, Identifiable {
    case vermelho
    case rosa
    case nude
    case azul
    case verde
    case preto
    case branco
    case roxo
    case prata
    case dourado
    case multicolorido

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PolishTone: String, CaseIterable, Codable, Identifiable {
    case claro
    case medio
    case escuro

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PolishFinish: String, CaseIterable, Codable, Identifiable {
    case cremoso
    case cintilante
    case glitter
    case transparente
    case metalico

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PolishSort: String, CaseIterable, Identifiable {
    case recentFirst
    case nameAscending
    case brandAscending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recentFirst: "Mais recentes"
        case .nameAscending: "Nome"
        case .brandAscending: "Marca"
        }
    }
}

struct Brand: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String

    var normalizedName: String {
        name.normalizedForSearch
    }
}

struct PolishTag: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String

    var normalizedName: String {
        name.normalizedForSearch
    }
}

struct UserProfile: Identifiable, Hashable, Codable {
    var id: UUID
    var email: String
    var displayName: String

    var initials: String {
        let pieces = displayName
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)).uppercased() }

        return pieces.joined()
    }
}

struct UserSession: Equatable {
    var user: UserProfile
}

struct Polish: Identifiable, Hashable, Codable {
    var id: UUID
    var userID: UUID
    var brand: Brand?
    var name: String
    var colorFamily: ColorFamily
    var tone: PolishTone
    var finish: PolishFinish
    var notes: String
    var photoPath: String?
    var tags: [PolishTag]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    var normalizedName: String {
        name.normalizedForSearch
    }

    var brandDisplayName: String {
        brand?.name ?? "Sem marca"
    }
}

struct PolishDraft: Equatable {
    var name: String = ""
    var brandName: String = ""
    var colorFamily: ColorFamily = .nude
    var tone: PolishTone = .medio
    var finish: PolishFinish = .cremoso
    var notes: String = ""
    var tagsText: String = ""
    var photoPath: String?
    var photoPreviewData: Data?

    init() {}

    init(polish: Polish?) {
        guard let polish else { return }
        name = polish.name
        brandName = polish.brand?.name ?? ""
        colorFamily = polish.colorFamily
        tone = polish.tone
        finish = polish.finish
        notes = polish.notes
        tagsText = polish.tags.map(\.name).joined(separator: ", ")
        photoPath = polish.photoPath
    }

    var tagNames: [String] {
        tagsText
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct PolishFilters: Equatable {
    var query: String = ""
    var selectedBrandIDs: Set<UUID> = []
    var colorFamily: ColorFamily?
    var tone: PolishTone?
    var finish: PolishFinish?
    var selectedTagNames: Set<String> = []
    var sort: PolishSort = .recentFirst

    var isEmpty: Bool {
        query.isEmpty &&
        selectedBrandIDs.isEmpty &&
        colorFamily == nil &&
        tone == nil &&
        finish == nil &&
        selectedTagNames.isEmpty &&
        sort == .recentFirst
    }

    func apply(to polishes: [Polish]) -> [Polish] {
        let queryToken = query.normalizedForSearch

        return polishes
            .filter { polish in
                guard queryToken.isEmpty == false else { return true }
                return polish.normalizedName.contains(queryToken) ||
                    polish.brandDisplayName.normalizedForSearch.contains(queryToken)
            }
            .filter { polish in
                selectedBrandIDs.isEmpty || selectedBrandIDs.contains(polish.brand?.id ?? UUID())
            }
            .filter { polish in
                colorFamily == nil || polish.colorFamily == colorFamily
            }
            .filter { polish in
                tone == nil || polish.tone == tone
            }
            .filter { polish in
                finish == nil || polish.finish == finish
            }
            .filter { polish in
                selectedTagNames.isEmpty ||
                    Set(polish.tags.map { $0.normalizedName }).isSuperset(of: selectedTagNames)
            }
            .sorted(using: sort)
    }
}

extension Array where Element == Polish {
    fileprivate func sorted(using sort: PolishSort) -> [Polish] {
        switch sort {
        case .recentFirst:
            sorted { $0.createdAt > $1.createdAt }
        case .nameAscending:
            sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .brandAscending:
            sorted {
                $0.brandDisplayName.localizedCaseInsensitiveCompare($1.brandDisplayName) == .orderedAscending
            }
        }
    }
}

enum AuthPhase: Equatable {
    case checking
    case signedOut
    case emailSent(String)
    case signedIn(UserSession)
    case failed(String)
}

enum DataSourceMode: Equatable {
    case demo
    case supabaseLive(URL)
    case supabaseFallback(URL, reason: String)

    var title: String {
        switch self {
        case .demo: "Modo demo"
        case .supabaseLive: "Supabase live"
        case .supabaseFallback: "Supabase configurado com fallback"
        }
    }

    var subtitle: String {
        switch self {
        case .demo:
            "O app abre com dados mockados ate a integracao live ficar pronta."
        case .supabaseLive(let url):
            "Projeto apontando para \(url.host ?? url.absoluteString) com Auth, banco e Storage prontos para uso."
        case .supabaseFallback(let url, let reason):
            "Config encontrada para \(url.host ?? url.absoluteString), mas o app manteve fallback local: \(reason)"
        }
    }

    var usesDemoData: Bool {
        switch self {
        case .demo, .supabaseFallback:
            true
        case .supabaseLive:
            false
        }
    }
}

extension String {
    var normalizedForSearch: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
