//
//  MainViewTab.swift
//  TimeTracker
//
//  Created by Илья on 28.07.2025.
//

import SwiftUI

enum TrackingTabListRoute: Hashable {
    case settings
}

struct TrackingTab: View {
    
    @State var path = PathSharedState()
    
    var body: some View {
        NavigationStack(path: $path.path) {
            TrackingView()
                .navigationDestination(for: TrackingTabListRoute.self) { screen in
                    switch screen {
                    case .settings: SettingsView()
                    }
                }
        }
        .environment(path)
    }
}

#Preview {
    TrackingTab()
}
