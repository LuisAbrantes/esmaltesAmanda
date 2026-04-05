import Observation
import SwiftUI

enum AppRoute: Hashable {
    case polishDetail(UUID)
}

@MainActor
@Observable
final class TabRouter {
    private var paths: [AppTab: [AppRoute]] = Dictionary(
        uniqueKeysWithValues: AppTab.allCases.map { ($0, []) }
    )

    func binding(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.paths[tab, default: []] },
            set: { self.paths[tab] = $0 }
        )
    }

    func push(_ route: AppRoute, on tab: AppTab) {
        paths[tab, default: []].append(route)
    }

    func replacePath(for tab: AppTab, with routes: [AppRoute]) {
        paths[tab] = routes
    }

    func reset(_ tab: AppTab? = nil) {
        if let tab {
            paths[tab] = []
            return
        }

        for tab in AppTab.allCases {
            paths[tab] = []
        }
    }
}

