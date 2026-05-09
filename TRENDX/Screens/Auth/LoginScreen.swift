//
//  LoginScreen.swift
//  TRENDX
//

import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var name = "علي"
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true

    var body: some View {
        ZStack {
            TrendXAmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Text("TRENDX")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(TrendXTheme.primaryDeep)

                        Text("نسخة Beta بصوت حقيقي ورؤى ذكية")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                    .padding(.top, 70)

                    VStack(alignment: .leading, spacing: 14) {
                        Picker("", selection: $isSignUp) {
                            Text("حساب جديد").tag(true)
                            Text("دخول").tag(false)
                        }
                        .pickerStyle(.segmented)

                        if isSignUp {
                            AuthField(title: "الاسم", text: $name, icon: "person.fill")
                        }

                        AuthField(title: "البريد", text: $email, icon: "envelope.fill", keyboard: .emailAddress)
                        AuthSecureField(title: "كلمة المرور", text: $password)

                        if let message = store.appMessage {
                            Text(message)
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            Task {
                                if isSignUp {
                                    await store.signUp(name: name, email: email, password: password)
                                } else {
                                    await store.signIn(email: email, password: password)
                                }
                            }
                        } label: {
                            HStack {
                                if store.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(isSignUp ? "ابدأ Beta" : "دخول")
                                    .font(.trendxBodyBold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(TrendXTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(store.isLoading || email.isEmpty || password.count < 6 || (isSignUp && name.isEmpty))
                        .opacity(email.isEmpty || password.count < 6 || (isSignUp && name.isEmpty) ? 0.55 : 1)

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
    LoginScreen()
        .environmentObject(AppStore())
}
