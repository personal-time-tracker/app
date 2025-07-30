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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Виджет текущего занятия
                CurrentActivityWidgetView(
                    vm: vm,
                    namespace: animation
                )
                .padding(.horizontal)
                
                // Виджет последнего занятия
                PreviousActivityWidgetView(
                    namespace: animation,
                    vm: vm
                )
                .padding(.horizontal)
                
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
                EditActivityView()
            }
            .alert(item: $vm.alert) { $0.asAlert }
        }
        .background(Color(.systemGroupedBackground))
    }
}


#Preview {
    TrackingView()
}
