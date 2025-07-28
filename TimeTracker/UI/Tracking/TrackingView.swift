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
    @Environment(PathSharedState.self) private var path
    
    @ObservationIgnored
    @Injected(\.alertManager) var alertManager

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Виджет текущего занятия
                CurrentActivityWidgetView(
                    currentActivity: vm.currentActivity,
                    isShowNewSessionSheet: $vm.isShowNewSessionSheet
                )
                .padding(.horizontal)
                
                if vm.currentActivity == nil {
                    // Виджет последнего занятия
                    PreviousActivityWidgetView(
                        previousActivity: vm.previousActivity
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
            .sheet(isPresented: $vm.isShowNewSessionSheet) {
                CreateActivityView()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}


#Preview {
    TrackingView()
}
