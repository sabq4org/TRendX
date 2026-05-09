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
    @State private var gender: UserGender = .unspecified
    @State private var birthYearText = ""
    @State private var city = ""

    private static let saudiCities = [
        "الرياض", "جدة", "مكة المكرمة", "المدينة المنورة", "الدمام",
        "الخبر", "الظهران", "الطائف", "أبها", "تبوك", "بريدة", "حائل",
        "الجبيل", "ينبع", "نجران", "الباحة", "جازان", "عرعر", "سكاكا"
    ]

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

                        if isSignUp {
                            DemographicsBlock(
                                gender: $gender,
                                birthYearText: $birthYearText,
                                city: $city,
                                cities: Self.saudiCities
                            )
                        }

                        if let message = store.appMessage {
                            Text(message)
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            Task {
                                if isSignUp {
                                    let parsedYear = Int(birthYearText.trimmingCharacters(in: .whitespaces))
                                    let trimmedCity = city.trimmingCharacters(in: .whitespaces)
                                    await store.signUp(
                                        name: name,
                                        email: email,
                                        password: password,
                                        gender: gender,
                                        birthYear: parsedYear,
                                        city: trimmedCity.isEmpty ? nil : trimmedCity
                                    )
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

private struct DemographicsBlock: View {
    @Binding var gender: UserGender
    @Binding var birthYearText: String
    @Binding var city: String
    let cities: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("بياناتك الديموغرافية تساعد TRENDX يقيس النبض الحقيقي")
                .font(.trendxSmall())
                .foregroundStyle(TrendXTheme.tertiaryInk)
                .padding(.top, 4)

            HStack(spacing: 8) {
                ForEach(UserGender.allCases.filter { $0 != .other }, id: \.self) { option in
                    GenderChip(option: option, selected: gender == option) {
                        gender = option
                    }
                }
            }

            HStack(spacing: 10) {
                AuthField(
                    title: "سنة الميلاد",
                    text: $birthYearText,
                    icon: "calendar",
                    keyboard: .numberPad
                )

                Menu {
                    ForEach(cities, id: \.self) { name in
                        Button(name) { city = name }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(width: 20)
                        Text(city.isEmpty ? "المدينة" : city)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(city.isEmpty ? TrendXTheme.tertiaryInk : TrendXTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    .padding(14)
                    .background(TrendXTheme.softFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

private struct GenderChip: View {
    let option: UserGender
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? .white : TrendXTheme.secondaryInk)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(selected ? AnyShapeStyle(TrendXTheme.primaryGradient) : AnyShapeStyle(TrendXTheme.softFill))
                )
        }
        .buttonStyle(.plain)
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
