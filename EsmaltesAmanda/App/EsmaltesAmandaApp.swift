import SwiftUI

@main
struct EsmaltesAmandaApp: App {
    @State private var appModel = AppBootstrap.makeDefaultModel()
    @State private var tabRouter = TabRouter()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(appModel)
                .environment(tabRouter)
                .task {
                    await appModel.bootstrap()
                }
                .onOpenURL { url in
                    Task {
                        await appModel.handleOpenURL(url)
                    }
                }
        }
    }
}
