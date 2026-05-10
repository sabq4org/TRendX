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
        Group {
            if store.isAuthenticated {
                ZStack(alignment: .bottom) {
                    // Main Content
                    TabView(selection: $store.selectedTab) {
                        NavigationStack { HomeScreen() }
                            .tag(TabItem.home)

                        NavigationStack { PollsScreen() }
                            .tag(TabItem.polls)

                        NavigationStack { GiftsScreen() }
                            .tag(TabItem.gifts)

                        NavigationStack { AccountScreen() }
                            .tag(TabItem.account)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    TrendXTabBar(selectedTab: $store.selectedTab)

                    if let message = store.appMessage {
                        BetaStatusBanner(message: message)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
            } else {
                LoginScreen()
            }
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

private struct BetaStatusBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 12, weight: .bold))
            Text(message)
                .font(.trendxSmall())
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundStyle(TrendXTheme.primaryDeep)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TrendXTheme.primary.opacity(0.16), lineWidth: 0.8)
        )
    }
}

#Preview {
    ContentView()
}
