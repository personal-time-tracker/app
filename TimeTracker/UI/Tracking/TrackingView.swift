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
    @Namespace private var animation
    
    @ObservationIgnored
    @Injected(\.alertManager) var alertManager

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Виджет текущего занятия
                CurrentActivityWidgetView(
                    namespace: animation,
                    currentActivity: vm.currentActivity,
                    isShowNewSessionSheet: $vm.isShowNewSessionSheet
                )
                .padding(.horizontal)
                
                if vm.currentActivity == nil {
                    // Виджет последнего занятия
                    PreviousActivityWidgetView(
                        previousActivity: vm.previousActivity,
                        namespace: animation
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.currentActivity)
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
