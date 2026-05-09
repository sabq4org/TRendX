//
//  ContentView.swift
//  TRENDX
//
//  Created by Ali Alhazmi on 16/04/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            TabView(selection: $store.selectedTab) {
                HomeScreen()
                    .tag(TabItem.home)
                
                PollsScreen()
                    .tag(TabItem.polls)
                
                GiftsScreen()
                    .tag(TabItem.gifts)
                
                AccountScreen()
                    .tag(TabItem.account)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            TrendXTabBar(selectedTab: $store.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(store)
        .trendxRTL()
        .sheet(isPresented: $store.showCreatePoll) {
            CreatePollSheet()
                .environmentObject(store)
                .trendxRTL()
        }
    }
}

#Preview {
    ContentView()
}
