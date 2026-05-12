//
//  AccountScreen.swift
//  TRENDX
//

import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var showProfileEdit = false
    @State private var showPublicProfile = false

    private var votedCount: Int { store.currentUser.completedPolls.count }
    private var followedCount: Int { store.currentUser.followedTopics.count }
    private var favoriteTopics: String {
        let names = store.topics.filter(\.isFollowing).map(\.name)
        return names.isEmpty ? "لم تحدد اهتمامات بعد" : names.prefix(3).joined(separator: "، ")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if store.isGuest {
                    GuestAccountHero {
                        store.showLoginSheet = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                } else {
                    ProfileHeader(user: store.currentUser) {
                        showProfileEdit = true
                    }
                }

                StatsGrid(
                    points: store.currentUser.points,
                    coins: store.currentUser.coins,
                    voted: votedCount,
                    followed: followedCount
                )
                .padding(.horizontal, 20)

                MemberTierProgressCard(points: store.currentUser.points)
                    .padding(.horizontal, 20)

                // Social graph entry — followers + following lists.
                if !store.isGuest {
                    NavigationLink {
                        MyNetworkScreen(store: store)
                            .environmentObject(store)
                            .trendxRTL()
                    } label: {
                        MyNetworkEntryCard(
                            following: store.currentUser.followingCount,
                            followers: store.currentUser.followersCount
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }

                // NEW: Opinion DNA — direct entry to identity screen
                NavigationLink {
                    OpinionDNAScreen()
                        .environmentObject(store)
                        .trendxRTL()
                } label: {
                    OpinionDNAEntryCard()
                        .environmentObject(store)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // NEW: National TRENDX Index entry
                NavigationLink {
                    TrendXIndexScreen()
                        .environmentObject(store)
                        .trendxRTL()
                } label: {
                    TrendXIndexHomeCard()
                        .environmentObject(store)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // NEW: Predictive Accuracy
                NavigationLink {
                    PredictionAccuracyScreen()
                        .environmentObject(store)
                        .trendxRTL()
                } label: {
                    AccuracyEntryCard()
                        .environmentObject(store)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                AIInsightChip(
                    text: "رادارك الحالي يركز على: \(favoriteTopics). شاركت في \(votedCount) استطلاع واستبدلت \(store.redemptions.count) هدية حتى الآن.",
                    label: "ملخص TRENDX AI"
                )
                .padding(.horizontal, 20)

                AccountSection(title: "عام") {
                    SettingsRow(
                        icon: "gift.fill",
                        iconColor: .purple,
                        title: "الهدايا المكتسبة",
                        subtitle: store.redemptions.first?.code ?? "سيظهر آخر كود استبدال هنا",
                        trailingText: "\(store.redemptions.count)"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon: "star.fill",
                        iconColor: TrendXTheme.accent,
                        title: "النقاط",
                        trailingText: "\(store.currentUser.points)"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: TrendXTheme.success,
                        title: "استطلاعاتي المصوّت عليها",
                        trailingText: "\(votedCount)"
                    )
                    SettingsDivider()
                    SettingsRow(
                        icon: "gearshape.fill",
                        iconColor: TrendXTheme.primary,
                        title: "اهتماماتي",
                        subtitle: favoriteTopics
                    )
                }

                AccountSection(title: "المساعدة والدعم") {
                    SettingsRow(icon: "book.fill", iconColor: TrendXTheme.primary, title: "دليل المجتمع", subtitle: "احترام، وضوح، وعدم تكرار الأسئلة")
                    SettingsDivider()
                    SettingsRow(icon: "info.circle.fill", iconColor: TrendXTheme.info, title: "من نحن", subtitle: "TRENDX يجمع الرأي، المكافآت، والرؤى المحلية")
                    SettingsDivider()
                    SettingsRow(icon: "questionmark.circle.fill", iconColor: TrendXTheme.accent, title: "الأسئلة الشائعة", subtitle: "التصويت يمنح نقاطاً، والهدايا تخصم من رصيدك")
                    SettingsDivider()
                    SettingsRow(icon: "bubble.left.and.bubble.right.fill", iconColor: TrendXTheme.info, title: "الشكاوى والمقترحات", subtitle: "قريباً: نموذج تواصل داخل التطبيق")
                }

                AccountSection(title: "القوانين") {
                    SettingsRow(icon: "lock.shield.fill", iconColor: TrendXTheme.success, title: "سياسة الخصوصية", subtitle: "البيانات محفوظة محلياً على هذا الجهاز")
                    SettingsDivider()
                    SettingsRow(icon: "doc.text.fill", iconColor: TrendXTheme.primary, title: "الشروط والأحكام", subtitle: "نسخة أولية لتجربة TRENDX")
                }

                Button {
                    if store.isRemoteEnabled {
                        store.signOut()
                    } else {
                        store.selectedTab = .home
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text(store.isRemoteEnabled ? "تسجيل الخروج" : "العودة للرادار")
                            .font(.trendxBodyBold())
                    }
                    .foregroundStyle(TrendXTheme.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(TrendXTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(TrendXTheme.outline, lineWidth: 0.8)
                    )
                }
                .padding(.horizontal, 20)

                VStack(spacing: 4) {
                    Text("TRENDX")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                    Text("الإصدار 1.0.0")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                }
                .padding(.top, 4)
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .trendxScreenBackground()
        .sheet(isPresented: $showProfileEdit) {
            NavigationStack {
                ProfileEditScreen(user: store.currentUser)
                    .environmentObject(store)
            }
            .trendxRTL()
        }
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    let user: TrendXUser
    var onEdit: () -> Void = {}

    private var membership: String {
        user.isPremium ? "عضو مميز" : "عضو TRENDX"
    }

    var body: some View {
        VStack(spacing: 14) {
            // Avatar — remote image when available, otherwise initial disc
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 92, height: 92)
                    if let urlString = user.avatarUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Text(user.avatarInitial)
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundStyle(TrendXTheme.primaryDeep)
                            }
                        }
                        .frame(width: 86, height: 86)
                        .clipShape(Circle())
                    } else {
                        Text(user.avatarInitial)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(TrendXTheme.primaryDeep)
                    }
                }
                .frame(width: 92, height: 92)
                .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 3))
                .shadow(color: TrendXTheme.primaryDeep.opacity(0.28), radius: 14, x: 0, y: 8)

                // Edit pencil
                Button(action: onEdit) {
                    Circle()
                        .fill(TrendXTheme.accent)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: TrendXTheme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: 4)
            }

            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: user.isPremium ? "crown.fill" : "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(membership)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(0.3)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.22)))
                .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.6))
            }

            Button(action: onEdit) {
                HStack(spacing: 6) {
                    Text("تعديل الملف الشخصي")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .heavy))
                }
                .foregroundStyle(TrendXTheme.primaryDeep)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white))
                .shadow(color: TrendXTheme.primaryDeep.opacity(0.22), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        TrendXTheme.primaryDeep,
                        TrendXTheme.primary,
                        TrendXTheme.primaryLight
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Ambient soft blobs
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 220)
                    .blur(radius: 40)
                    .offset(x: -130, y: -90)

                Circle()
                    .fill(TrendXTheme.primaryLight.opacity(0.30))
                    .frame(width: 180)
                    .blur(radius: 45)
                    .offset(x: 140, y: 100)

                // Sparkle texture
                HStack(spacing: 30) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .offset(y: -40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .offset(y: 60)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.20))
                        .offset(y: -30)
                }
                .padding(.horizontal, 30)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: TrendXTheme.primary.opacity(0.28), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let points: Int
    let coins: Double
    let voted: Int
    let followed: Int

    var body: some View {
        HStack(spacing: 10) {
            StatPill(
                icon: "star.circle.fill",
                value: "\(points)",
                label: "نقطة",
                tint: TrendXTheme.accent
            )
            StatPill(
                icon: "dollarsign.circle.fill",
                value: String(format: "%.1f", coins),
                label: "ريال",
                tint: TrendXTheme.success
            )
            StatPill(
                icon: "checkmark.circle.fill",
                value: "\(voted)",
                label: "تصويت",
                tint: TrendXTheme.primary
            )
            StatPill(
                icon: "heart.circle.fill",
                value: "\(followed)",
                label: "اهتمام",
                tint: .purple
            )
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(TrendXTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TrendXTheme.outline, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: TrendXTheme.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - Section Container

struct AccountSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                content()
            }
            .background(TrendXTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TrendXTheme.outline, lineWidth: 0.8)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(TrendXTheme.outline)
            .frame(height: 1)
            .padding(.leading, 64)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = TrendXTheme.primary
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var showBadge: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(iconColor.opacity(0.10))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(TrendXTheme.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .monospacedDigit()
            }

            if showBadge {
                Circle()
                    .fill(TrendXTheme.error)
                    .frame(width: 8, height: 8)
            }

            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TrendXTheme.tertiaryInk.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    AccountScreen()
        .environmentObject(AppStore())
        .trendxRTL()
}

// MARK: - Guest hero (shown when there is no real session)

private struct GuestAccountHero: View {
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.primary.opacity(0.10))
                    .frame(width: 132, height: 132)
                Circle()
                    .stroke(TrendXTheme.primary.opacity(0.18), lineWidth: 1.5)
                    .frame(width: 108, height: 108)
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: TrendXTheme.primary.opacity(0.45), radius: 18, x: 0, y: 10)
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("ابدأ رحلتك مع TRENDX")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                Text("سجّل دخولك للمشاركة في الاستطلاعات، جمع النقاط، واستبدال الهدايا.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
            }

            HStack(spacing: 16) {
                pitchTile(icon: "star.circle.fill", title: "اربح نقاط", tint: TrendXTheme.accent)
                pitchTile(icon: "gift.fill", title: "استبدل هدايا", tint: TrendXTheme.success)
                pitchTile(icon: "waveform.path.ecg", title: "صوّت يومياً", tint: TrendXTheme.primary)
            }
            .padding(.horizontal, 10)

            Button(action: onSignIn) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .heavy))
                    Text("سجّل دخولك الآن")
                        .font(.system(size: 15, weight: .heavy))
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TrendXTheme.primaryGradient)
                )
                .shadow(color: TrendXTheme.primary.opacity(0.35), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TrendXTheme.surface)
                .shadow(color: TrendXTheme.shadow, radius: 18, x: 0, y: 6)
        )
    }

    private func pitchTile(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Network entry on Account

private struct MyNetworkEntryCard: View {
    let following: Int
    let followers: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [TrendXTheme.aiIndigo, TrendXTheme.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 46, height: 46)
                    .shadow(color: TrendXTheme.primary.opacity(0.30), radius: 10, x: 0, y: 5)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("شبكتي")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                HStack(spacing: 10) {
                    Label("\(following) يتابعهم", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                    Label("\(followers) متابعونك", systemImage: "person.2")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(TrendXTheme.primary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(TrendXTheme.primary.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: TrendXTheme.shadow, radius: 10, x: 0, y: 4)
        )
    }
}
