//
//  ContentView.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var calendarService = CalendarService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Главный экран с виджетом
            VStack(spacing: 20) {
                // Заголовок
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TimeTracer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Трекинг времени")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Кнопка настроек
                    Button(action: {
                        // TODO: Настройки
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Виджет текущего занятия
                CurrentActivityWidget(calendarService: calendarService)
                    .padding(.horizontal)
                
                // Быстрые действия
                QuickActionsView(calendarService: calendarService)
                    .padding(.horizontal)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .tabItem {
                Image(systemName: "clock.fill")
                Text("Трекинг")
            }
            .tag(0)
            
            // Экран аналитики
            AnalyticsView(calendarService: calendarService)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Аналитика")
                }
                .tag(1)
        }
        .onAppear {
            setupNotifications()
            // Обновляем текущую сессию при появлении экрана
            calendarService.loadCurrentSession()
        }
    }
    
    private func setupNotifications() {
        // Слушаем уведомления от Shortcuts
        NotificationCenter.default.addObserver(
            forName: .startTimeTracking,
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let activityTitle = userInfo["activityTitle"] as? String,
               let calendarId = userInfo["calendarId"] as? String {
                calendarService.startNewSession(title: activityTitle, calendarId: calendarId)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .endTimeTracking,
            object: nil,
            queue: .main
        ) { _ in
            calendarService.endCurrentSession()
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject var calendarService: CalendarService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Быстрые действия")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Завершить",
                    icon: "stop.fill",
                    color: .red
                ) {
                    calendarService.endCurrentSession()
                }
                
                QuickActionButton(
                    title: "Пауза",
                    icon: "pause.fill",
                    color: .orange
                ) {
                    // TODO: Реализовать паузу
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ContentView()
}
