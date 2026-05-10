//
//  LoginScreen.swift
//  TRENDX
//

import SwiftUI

/// Entry point for unauthenticated users.
///
/// - For new users we present `SmartSignUpFlow`, an AI-led, conversational
///   onboarding that collects profile data one question at a time.
/// - For returning users we keep a focused, two-field sign-in card. Adding
///   chat scaffolding around a sign-in would be theatrical, not helpful.
struct LoginScreen: View {
    @State private var mode: Mode = .signUp

    enum Mode { case signUp, signIn }

    var body: some View {
        Group {
            switch mode {
            case .signUp:
                SmartSignUpFlow(onSwitchToSignIn: { mode = .signIn })
            case .signIn:
                SignInCard(onSwitchToSignUp: { mode = .signUp })
            }
        }
    }
}

// MARK: - Sign-in card (returning users)

private struct SignInCard: View {
    @EnvironmentObject private var store: AppStore
    let onSwitchToSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            TrendXAmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Text("TRENDX")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(TrendXTheme.primaryDeep)

                        Text("مرحباً مرة أخرى — لوحتك تنتظرك")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                    .padding(.top, 70)

                    VStack(alignment: .leading, spacing: 14) {
                        AuthField(title: "البريد", text: $email, icon: "envelope.fill", keyboard: .emailAddress)
                        AuthSecureField(title: "كلمة المرور", text: $password)

                        if let message = store.appMessage {
                            Text(message)
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            Task { await store.signIn(email: email, password: password) }
                        } label: {
                            HStack {
                                if store.isLoading {
                                    ProgressView().tint(.white)
                                }
                                Text("دخول").font(.trendxBodyBold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(TrendXTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(store.isLoading || email.isEmpty || password.count < 6)
                        .opacity(email.isEmpty || password.count < 6 ? 0.55 : 1)

                        Button(action: onSwitchToSignUp) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("جديد على TRENDX؟ سجّل بأسلوب AI")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(TrendXTheme.primary.opacity(0.10))
                            )
                        }
                        .buttonStyle(.plain)

                        Text(store.isRemoteEnabled ? "متصل بـ TRENDX API" : "وضع محلي احتياطي حتى تضيف رابط API")
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .surfaceCard(padding: 18, radius: 22)
                    .padding(.horizontal, 22)
                }
                .padding(.bottom, 60)
            }
        }
        .trendxRTL()
    }
}

// MARK: - Reusable inputs

private struct AuthField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(TrendXTheme.primary)
                .frame(width: 22)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(14)
        .background(TrendXTheme.softFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(TrendXTheme.primary)
                .frame(width: 22)
            SecureField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(14)
        .background(TrendXTheme.softFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    LoginScreen().environmentObject(AppStore())
}
