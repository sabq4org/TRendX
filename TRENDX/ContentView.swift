//
//  ContentView.swift
//  TRENDX
//
//  Created by Ali Alhazmi on 16/04/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.showWelcomeAfterSignUp {
                // Welcome wins over both the tab interface and the login
                // screen so the signup → welcome transition never flashes
                // through anything else.
                WelcomeAfterSignUpScreen(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        store.showWelcomeAfterSignUp = false
                    }
                })
                .transition(.opacity)
            } else if store.isAuthenticated {
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
                        BetaStatusBanner(message: message) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                store.appMessage = nil
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                // Only the authed shell ignores the keyboard so the
                // tab bar doesn't bounce when typing in a sheet. The
                // unauthenticated sign-up flow needs full keyboard
                // avoidance, so we keep this scoped to authed.
                .ignoresSafeArea(.keyboard)
            } else {
                LoginScreen()
            }
        }
        .environmentObject(store)
        .trendxRTL()
        .sheet(isPresented: $store.showCreatePoll) {
            CreatePollSheet()
                .environmentObject(store)
                .trendxRTL()
        }
        .sheet(isPresented: $store.showLoginSheet) {
            LoginScreen()
                .environmentObject(store)
                .trendxRTL()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // When the user brings the app back to the foreground, pull
            // the latest polls / surveys / pulse so anything published
            // from the dashboard shows up without needing pull-to-refresh.
            guard newPhase == .active, store.isAuthenticated else { return }
            Task { await store.refreshBootstrap() }
        }
    }
}

private struct BetaStatusBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 12, weight: .bold))
            Text(message)
                .font(.trendxSmall())
                .lineLimit(2)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primaryDeep.opacity(0.7))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.white.opacity(0.6)))
            }
            .buttonStyle(.plain)
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
        .onTapGesture(perform: onDismiss)
    }
}

#Preview {
    ContentView()
}
