import Foundation

struct SupabaseConfiguration: Equatable {
    let projectURL: URL
    let anonKey: String
    let redirectURL: String

    static func fromBundle(_ bundle: Bundle = .main) -> SupabaseConfiguration? {
        let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        if let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let redirectURL = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_URL") as? String,
           urlString.hasPrefix("http"),
           urlString.contains("YOUR_") == false,
           let anonKey,
           anonKey.contains("YOUR_") == false,
           let projectURL = URL(string: urlString) {
            return SupabaseConfiguration(
                projectURL: projectURL,
                anonKey: anonKey,
                redirectURL: redirectURL
            )
        }

        guard
            let projectHost = bundle.object(forInfoDictionaryKey: "SUPABASE_PROJECT_HOST") as? String,
            let redirectScheme = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_SCHEME") as? String,
            let redirectHost = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_HOST") as? String,
            let anonKey,
            projectHost.contains("YOUR_") == false,
            redirectScheme.contains("YOUR_") == false,
            redirectHost.contains("YOUR_") == false,
            anonKey.contains("YOUR_") == false,
            let projectURL = URL(string: "https://\(projectHost)")
        else {
            return nil
        }

        return SupabaseConfiguration(
            projectURL: projectURL,
            anonKey: anonKey,
            redirectURL: "\(redirectScheme)://\(redirectHost)"
        )
    }
}

@MainActor
enum AppBootstrap {
    static func makeDefaultModel() -> AppModel {
        let configuration = SupabaseConfiguration.fromBundle()
        let demoAuthService = DemoAuthService()
        let demoRepository = InMemoryPolishRepository(seedPolishes: PreviewFixtures.seedPolishes())
        let demoPhotoStorage = InMemoryPhotoStorageService()

        let services = makeServices(configuration: configuration) ?? (
            authService: demoAuthService as any AuthServiceProtocol,
            repository: demoRepository as any PolishRepositoryProtocol,
            photoStorage: demoPhotoStorage as any PhotoStorageServiceProtocol,
            mode: configuration.map {
                DataSourceMode.supabaseFallback(
                    $0.projectURL,
                    reason: "SDK do Supabase ainda nao esta resolvido no projeto."
                )
            } ?? .demo
        )

        return AppModel(
            authService: services.authService,
            polishRepository: services.repository,
            photoStorageService: services.photoStorage,
            dataSourceMode: services.mode
        )
    }

    private static func makeServices(configuration: SupabaseConfiguration?) -> (
        authService: any AuthServiceProtocol,
        repository: any PolishRepositoryProtocol,
        photoStorage: any PhotoStorageServiceProtocol,
        mode: DataSourceMode
    )? {
#if canImport(Supabase)
        guard let configuration else { return nil }

        let liveServices = SupabaseServiceFactory.makeServices(configuration: configuration)
        return (
            authService: liveServices.authService,
            repository: liveServices.repository,
            photoStorage: liveServices.photoStorage,
            mode: .supabaseLive(configuration.projectURL)
        )
#else
        return nil
#endif
    }
}
