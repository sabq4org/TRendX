//
//  SmartSignUpFlow.swift
//  TRENDX
//
//  AI-led conversational onboarding. Replaces the classic two-column
//  form with a chat-style flow where TRENDX AI introduces itself and
//  collects each piece of profile data through a focused, single-
//  purpose question + input control. Each answer becomes a user
//  bubble in the transcript; the next question fades in after a
//  short "typing…" indicator so it feels like talking to a person.
//
//  Order of questions (each step is independent so the order can be
//  reshuffled later without breaking the controller):
//
//    greeting → name → email → password → gender → birthDecade →
//    city → interests → voice (optional) → finishing
//

import SwiftUI

// MARK: - Step machine

enum SignUpStep: Equatable {
    case greeting
    case askName
    case askEmail
    case askPassword
    case askGender
    case askBirthDecade
    case askCity
    case askInterests
    case askVoice
    case finishing
    case done
}

// MARK: - Chat message model

struct ChatMessage: Identifiable, Equatable {
    enum Author { case ai, user }
    let id = UUID()
    let author: Author
    let text: String
}

// MARK: - Smart sign-up

struct SmartSignUpFlow: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let onSwitchToSignIn: () -> Void

    // collected values
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var gender: UserGender = .unspecified
    @State private var birthYear: Int? = nil
    @State private var city: String = ""
    @State private var interests: Set<String> = []
    @State private var voiceLine: String = ""

    // conversation state
    @State private var step: SignUpStep = .greeting
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false

    // current input scratchpad
    @State private var nameInput = ""
    @State private var emailInput = ""
    @State private var passwordInput = ""

    private let saudiCities = [
        "الرياض", "جدة", "مكة المكرمة", "المدينة المنورة", "الدمام",
        "الخبر", "الظهران", "الطائف", "أبها", "تبوك", "بريدة", "حائل",
        "الجبيل", "ينبع", "نجران", "الباحة", "جازان", "عرعر", "سكاكا",
    ]

    private let interestPool: [String] = [
        "السياسة", "الاقتصاد", "التقنية", "الذكاء الاصطناعي",
        "الرياضة", "الصحّة", "التعليم", "الترفيه", "السياحة",
        "الفنّ والثقافة", "البيئة", "الإعلام",
    ]

    private let decadeOptions: [(label: String, year: Int)] = [
        ("جيل 2000s", 2002),
        ("جيل 1990s", 1995),
        ("جيل 1980s", 1985),
        ("جيل 1970s", 1975),
        ("قبل 1970", 1965),
    ]

    var body: some View {
        ZStack {
            TrendXAmbientBackground()

            VStack(spacing: 0) {
                header

                // Conversation transcript
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity))
                            }

                            if isTyping {
                                TypingBubble()
                                    .id("typing")
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, 18)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            if let last = messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _, typing in
                        if typing {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Inline input area for the current step
                inputArea
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(TrendXTheme.tertiaryInk.opacity(0.1))
                            .frame(height: 0.5)
                    }
            }
        }
        .trendxRTL()
        .onAppear { Task { await runStep(.greeting) } }
        .onChange(of: store.appMessage) { _, value in
            // Surface API errors back into the conversation.
            if let value, !value.isEmpty {
                aiSay(value)
                store.appMessage = nil
                step = .askEmail
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 38, height: 38)
                    .shadow(color: TrendXTheme.primary.opacity(0.4), radius: 6, x: 0, y: 3)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("TRENDX AI")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                Text(isTyping ? "يكتب الآن…" : "مرشدك إلى ملفّك")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isTyping ? TrendXTheme.primary : TrendXTheme.tertiaryInk)
                    .animation(.easeInOut(duration: 0.2), value: isTyping)
            }
            Spacer()

            Button(action: onSwitchToSignIn) {
                Text("لديّ حساب")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(TrendXTheme.primary)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(TrendXTheme.primary.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Input area (per step)

    @ViewBuilder
    private var inputArea: some View {
        switch step {
        case .greeting, .finishing, .done:
            EmptyView()

        case .askName:
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundStyle(TrendXTheme.primary)
                TextField("اسمك الأول", text: $nameInput)
                    .submitLabel(.send)
                    .onSubmit { commitName() }
                    .textInputAutocapitalization(.words)
                primaryActionButton(enabled: !trimmed(nameInput).isEmpty) { commitName() }
            }
            .modifier(InputCardStyle())

        case .askEmail:
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(TrendXTheme.primary)
                TextField("بريدك الإلكتروني", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { commitEmail() }
                primaryActionButton(enabled: isValidEmail(emailInput)) { commitEmail() }
            }
            .modifier(InputCardStyle())

        case .askPassword:
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(TrendXTheme.primary)
                SecureField("كلمة مرور (٦ خانات على الأقل)", text: $passwordInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { commitPassword() }
                primaryActionButton(enabled: passwordInput.count >= 6) { commitPassword() }
            }
            .modifier(InputCardStyle())

        case .askGender:
            HStack(spacing: 8) {
                ForEach(UserGender.allCases.filter { $0 != .other }, id: \.self) { option in
                    OnboardChip(
                        label: option.displayName,
                        selected: false,
                        accent: TrendXTheme.primary
                    ) { commitGender(option) }
                }
            }

        case .askBirthDecade:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(decadeOptions, id: \.year) { d in
                        OnboardChip(
                            label: d.label,
                            selected: false,
                            accent: TrendXTheme.primary
                        ) { commitDecade(d.year) }
                    }
                    OnboardChip(
                        label: "أفضّل لا أقول",
                        selected: false,
                        accent: TrendXTheme.tertiaryInk
                    ) { commitDecade(nil) }
                }
            }

        case .askCity:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(saudiCities, id: \.self) { name in
                        OnboardChip(
                            label: name,
                            selected: false,
                            accent: TrendXTheme.primary
                        ) { commitCity(name) }
                    }
                }
            }

        case .askInterests:
            VStack(spacing: 10) {
                FlowLayout(spacing: 8) {
                    ForEach(interestPool, id: \.self) { topic in
                        OnboardChip(
                            label: topic,
                            selected: interests.contains(topic),
                            accent: TrendXTheme.primary
                        ) { toggleInterest(topic) }
                    }
                }
                Button(action: commitInterests) {
                    Text(interests.isEmpty ? "تخطّي" : "اعتمد \(interests.count) اهتماماً")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(interests.isEmpty ? AnyShapeStyle(TrendXTheme.tertiaryInk.opacity(0.6))
                                                        : AnyShapeStyle(TrendXTheme.primaryGradient))
                        )
                }
                .buttonStyle(.plain)
            }

        case .askVoice:
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(TrendXTheme.primary)
                    TextField("كلمة واحدة، اختياري", text: $voiceLine, axis: .vertical)
                        .lineLimit(2)
                }
                .modifier(InputCardStyle())

                HStack(spacing: 8) {
                    Button(action: { commitVoice("") }) {
                        Text("تخطّي")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TrendXTheme.softFill)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { commitVoice(voiceLine) }) {
                        Text("ابدأ TRENDX")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TrendXTheme.primaryGradient)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step controller

    @MainActor
    private func runStep(_ next: SignUpStep) async {
        step = next
        switch next {
        case .greeting:
            await aiTypeAndSay("أهلاً 👋 أنا TRENDX AI.")
            await aiTypeAndSay("سأبني ملفّك خلال دقيقتين عبر بضعة أسئلة بسيطة، وكل إجابة تجعل الرؤى التي أقدّمها لك أدقّ.")
            await runStep(.askName)

        case .askName:
            await aiTypeAndSay("لنبدأ — كيف تحبّ أن أناديك؟")

        case .askEmail:
            await aiTypeAndSay("أهلاً \(name) 🌟 — على أيّ بريد إلكتروني نُسجّلك؟")

        case .askPassword:
            await aiTypeAndSay("اختر كلمة مرور آمنة لك — ستحتاجها للدخول لاحقاً.")

        case .askGender:
            await aiTypeAndSay("لمَن أُخاطب الآن؟ هذا يساعدني أعرض لك بيانات ممثّلة.")

        case .askBirthDecade:
            await aiTypeAndSay("في أيّ جيل تنتمي؟ — هذا يربطك بمن يشاركونك السياق نفسه.")

        case .askCity:
            await aiTypeAndSay("من أيّ مدينة تتابعنا؟")

        case .askInterests:
            await aiTypeAndSay("اختر ما يحرّك فضولك (يمكن أكثر من واحد):")

        case .askVoice:
            await aiTypeAndSay("سؤال أخير — في كلمة واحدة، ما الذي يهمّك أكثر هذه السنة؟")

        case .finishing:
            await aiTypeAndSay("ممتاز \(name) — أُعدّ ملفّك الآن…")
            await registerOnBackend()

        case .done:
            // Layout swaps when AppStore.isAuthenticated flips in ContentView.
            break
        }
    }

    // MARK: - Commit handlers

    private func commitName() {
        let value = trimmed(nameInput)
        guard !value.isEmpty else { return }
        name = value
        userSay(value)
        nameInput = ""
        Task { await runStep(.askEmail) }
    }

    private func commitEmail() {
        let value = trimmed(emailInput)
        guard isValidEmail(value) else { return }
        email = value.lowercased()
        userSay(email)
        emailInput = ""
        Task { await runStep(.askPassword) }
    }

    private func commitPassword() {
        guard passwordInput.count >= 6 else { return }
        password = passwordInput
        userSay(String(repeating: "•", count: passwordInput.count))
        passwordInput = ""
        Task { await runStep(.askGender) }
    }

    private func commitGender(_ value: UserGender) {
        gender = value
        userSay(value.displayName)
        Task { await runStep(.askBirthDecade) }
    }

    private func commitDecade(_ year: Int?) {
        birthYear = year
        userSay(year != nil ? labelForYear(year!) : "أفضّل لا أقول")
        Task { await runStep(.askCity) }
    }

    private func commitCity(_ value: String) {
        city = value
        userSay(value)
        Task { await runStep(.askInterests) }
    }

    private func toggleInterest(_ topic: String) {
        if interests.contains(topic) { interests.remove(topic) }
        else { interests.insert(topic) }
    }

    private func commitInterests() {
        let summary = interests.isEmpty ? "تخطّيت" : interests.joined(separator: " · ")
        userSay(summary)
        Task { await runStep(.askVoice) }
    }

    private func commitVoice(_ value: String) {
        let trimmedValue = trimmed(value)
        voiceLine = trimmedValue
        if !trimmedValue.isEmpty {
            userSay("«\(trimmedValue)»")
        } else {
            userSay("تخطّيت")
        }
        Task { await runStep(.finishing) }
    }

    // MARK: - Backend

    @MainActor
    private func registerOnBackend() async {
        await store.signUp(
            name: name,
            email: email,
            password: password,
            gender: gender,
            birthYear: birthYear,
            city: city.isEmpty ? nil : city,
            region: nil
        )

        // Persist interests + voice locally onto the user record so they
        // survive sign-out/in cycles. Topics will be wired to /profile
        // when the backend grows a richer profile endpoint.
        if store.isAuthenticated {
            // Match user-provided interest names to real topics, when
            // possible; otherwise keep them as on-device tags.
            let matchedTopicIds: [UUID] = store.topics
                .filter { interests.contains($0.name) }
                .map(\.id)
            store.applyOnboardingExtras(
                followedTopics: matchedTopicIds,
                voiceLine: voiceLine
            )
            await aiTypeAndSay("جاهز ✨ ملفّك أصبح حيّاً، ولوحة TRENDX اليوم أصبحت موجّهة لاهتماماتك.")
            step = .done
        }
        // If signUp failed, the .onChange(appMessage) handler nudges
        // the user back to .askEmail so they can correct it.
    }

    // MARK: - Conversation primitives

    @MainActor
    private func aiTypeAndSay(_ text: String) async {
        isTyping = true
        // Slight humanising pause that scales with message length.
        let delayMs = min(1_400, 360 + text.count * 18)
        try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
        isTyping = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            messages.append(ChatMessage(author: .ai, text: text))
        }
    }

    private func aiSay(_ text: String) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            messages.append(ChatMessage(author: .ai, text: text))
        }
    }

    private func userSay(_ text: String) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            messages.append(ChatMessage(author: .user, text: text))
        }
    }

    // MARK: - Helpers

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ s: String) -> Bool {
        let trimmedStr = trimmed(s)
        return trimmedStr.contains("@") && trimmedStr.contains(".") && trimmedStr.count >= 5
    }

    private func labelForYear(_ year: Int) -> String {
        switch year {
        case 2000...: return "جيل 2000s"
        case 1990...1999: return "جيل 1990s"
        case 1980...1989: return "جيل 1980s"
        case 1970...1979: return "جيل 1970s"
        default: return "قبل 1970"
        }
    }

    @ViewBuilder
    private func primaryActionButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(enabled ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                         : AnyShapeStyle(TrendXTheme.tertiaryInk.opacity(0.4)))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Bubble views

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.author == .ai {
                aiAvatar
                aiContent
                Spacer(minLength: 32)
            } else {
                Spacer(minLength: 32)
                userContent
            }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(TrendXTheme.primaryGradient)
                .frame(width: 30, height: 30)
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.white)
        }
    }

    private var aiContent: some View {
        Text(message.text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(TrendXTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TrendXTheme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
            .frame(maxWidth: 280, alignment: .leading)
            .multilineTextAlignment(.leading)
    }

    private var userContent: some View {
        Text(message.text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TrendXTheme.primaryGradient)
                    .shadow(color: TrendXTheme.primary.opacity(0.30), radius: 8, x: 0, y: 4)
            )
            .frame(maxWidth: 280, alignment: .trailing)
            .multilineTextAlignment(.trailing)
    }
}

private struct TypingBubble: View {
    @State private var phase: Int = 0
    private let dotCount = 3

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 30, height: 30)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<dotCount, id: \.self) { i in
                    Circle()
                        .fill(TrendXTheme.primary.opacity(phase == i ? 1.0 : 0.3))
                        .frame(width: 7, height: 7)
                        .animation(.easeInOut(duration: 0.35), value: phase)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TrendXTheme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )

            Spacer(minLength: 32)
        }
        .onAppear {
            // Pulse loop
            Task {
                while !Task.isCancelled {
                    for i in 0..<dotCount {
                        await MainActor.run { phase = i }
                        try? await Task.sleep(nanoseconds: 350 * 1_000_000)
                    }
                }
            }
        }
    }
}

// MARK: - Inline chip + input style

private struct OnboardChip: View {
    let label: String
    let selected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selected ? .white : accent)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(selected ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                       : AnyShapeStyle(accent.opacity(0.10)))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct InputCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TrendXTheme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
    }
}

#Preview {
    SmartSignUpFlow(onSwitchToSignIn: {})
        .environmentObject(AppStore())
}
