//
//  TrackingView.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import SwiftUI
import Factory

struct TrackingView: View {
    
    @State private var vm = TrackingViewModel()
    
    @ObservationIgnored
    @Injected(\.alertManager) var alertManager

    var body: some View {
        VStack(spacing: 5) {
            // Виджет текущего занятия
            CurrentActivityWidgetView(
                currentActivity: $vm.currentActivity,
                isShowNewSessionSheet: $vm.isShowNewSessionSheet
            )
            .padding(.horizontal)
            
            if vm.currentActivity == nil {
                // Виджет последнего занятия
                PreviousActivityWidgetView(
                    previousActivity: $vm.previousActivity
                )
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Учет времени")
        .toolbar{
            ToolbarItem {
                NavigationLink(value: TrackingTabListRoute.settings) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .task {
            do {
                // Обновляем текущую сессию при появлении экрана
                try await vm.load()
            } catch {
                alertManager.error(error)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $vm.isShowNewSessionSheet) {
            CreateActivityView()
        }
    }
}


#Preview {
    TrackingView()
}
