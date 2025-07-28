//
//  ContentView.swift
//  TImeTracer
//
//  Created by Илья on 27.07.2025.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        AppTabView()
    }
}

#Preview {
    ContentView()
}
