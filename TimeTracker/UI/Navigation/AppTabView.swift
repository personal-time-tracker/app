//
//  AppTabView.swift
//  TimeTracker
//
//  Created by Илья on 28.07.2025.
//

import SwiftUI

@Observable
final class PathSharedState {
    var path = NavigationPath()
}

struct AppTabView: View {
    
    @State var selectionTab = 1
    @AppStorage("isDeveloperMode") var isDevMode = false
    
    var body: some View {
        TabView(selection: $selectionTab) {
            
            TrackingTab()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Трекинг")
                }
                .tag(1)
            
            // Экран аналитики
            AnalyticsTab()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Аналитика")
                }
                .tag(2)
            
            HistoryTab()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("История")
                }
                .tag(3)
        }
    }
    
}

#Preview {
    AppTabView()
}
