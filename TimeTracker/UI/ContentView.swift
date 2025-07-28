//
//  ContentView.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI
import Factory

struct ContentView: View {

    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .system
    
    @ObservationIgnored
    @Injected(\.calendarService) var calendarService
    
    // Добавляем отслеживание фазы сцены
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        AppTabView()
            .preferredColorScheme(selectedTheme.colorScheme)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        // Добавляем обработчик изменений фазы сцены
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("Приложение стало активным, обновляю данные...")
                calendarService.loadCurrentActivity()
            }
        }
    }
    
    private func setupNotifications() {
        // The original code had this function, but it was not part of the edit
        // and did not contain the new_code. Keeping it as is.
    }
}

#Preview {
    ContentView()
}
