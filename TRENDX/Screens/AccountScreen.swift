//
//  AccountScreen.swift
//  TRENDX
//

import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject private var store: AppStore

    private var votedCount: Int { store.currentUser.completedPolls.count }
    private var followedCount: Int { store.currentUser.followedTopics.count }
    private var favoriteTopics: String {
        let names = store.topics.filter(\.isFollowing).map(\.name)
        return names.isEmpty ? "لم تحدد اهتمامات بعد" : names.prefix(3).joined(separator: "، ")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ProfileHeader(user: store.currentUser)

                StatsGrid(
                    points: store.currentUser.points,
                    coins: store.currentUser.coins,
                    voted: votedCount,
                    followed: followedCount
                )
                .padding(.horizontal, 20)

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
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    let user: TrendXUser

    private var membership: String {
        user.isPremium ? "عضو مميز" : "عضو TRENDX"
    }

    var body: some View {
        VStack(spacing: 14) {
            // Avatar — white disc with AI-tinted ring & edit pencil badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 92, height: 92)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 3)
                    )
                    .overlay(
                        Text(user.avatarInitial)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(TrendXTheme.primaryDeep)
                    )
                    .shadow(color: TrendXTheme.primaryDeep.opacity(0.28), radius: 14, x: 0, y: 8)

                // Edit pencil
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

            Button { } label: {
                HStack(spacing: 6) {
                    Text("الملف الشخصي")
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
