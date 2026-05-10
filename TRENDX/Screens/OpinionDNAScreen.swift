//
//  OpinionDNAScreen.swift
//  TRENDX
//
//  Six-axis "opinion DNA" view, sharable as text. Shares JSON with the
//  web dashboard's /account/dna page so the user sees the same identity
//  on every surface.
//

import SwiftUI

struct OpinionDNAScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var dna: TrendXOpinionDNA?
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var refreshing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                if loading {
                    ProgressView()
                        .padding(40)
                } else if let dna {
                    archetypeCard(dna: dna)
                        .padding(.horizontal, 20)
                    axesGrid(axes: dna.axes)
                        .padding(.horizontal, 20)
                    shareCard(dna: dna)
                        .padding(.horizontal, 20)
                } else {
                    notReadyCard
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 120)
        }
        .trendxScreenBackground()
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Spacer()
                Text("OPINION DNA")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(TrendXTheme.aiViolet)
            }
            Text("هويّتك في الرأي")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
            Text("سِتّ محاور تكشف هويّتك الفكريّة من تصويتاتك على TRENDX.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func archetypeCard(dna: TrendXOpinionDNA) -> some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Spacer()
                Text("شخصيّتك في الرأي")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(TrendXTheme.aiViolet)
            }
            Text(dna.archetype.title)
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(TrendXTheme.aiViolet)
                .multilineTextAlignment(.trailing)
            Text(dna.archetype.blurb)
                .font(.system(size: 14))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(
            LinearGradient(
                colors: [TrendXTheme.aiViolet.opacity(0.08), TrendXTheme.aiCyan.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(TrendXTheme.cardRadius)
        .overlay(RoundedRectangle(cornerRadius: TrendXTheme.cardRadius).stroke(TrendXTheme.aiViolet.opacity(0.18), lineWidth: 1))
    }

    private func axesGrid(axes: [TrendXDNAAxis]) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(axes) { a in
                axisCard(a: a)
            }
        }
    }

    private func axisCard(a: TrendXDNAAxis) -> some View {
        let tilt = a.score - 50
        let label = tilt > 0 ? a.labelHigh : a.labelLow
        let intensity: String = abs(tilt) >= 25 ? "قوي" : abs(tilt) >= 10 ? "معتدل" : "متوازن"
        return VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("\(a.score)/100")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .monospacedDigit()
                Spacer()
                Text(intensity)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(TrendXTheme.aiViolet)
            }
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(TrendXTheme.ink)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Bipolar bar
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(TrendXTheme.paleFill)
                    if tilt >= 0 {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(TrendXTheme.aiViolet)
                            .frame(width: w * CGFloat(abs(tilt)) / 100)
                            .offset(x: w / 4)
                    } else {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(TrendXTheme.aiViolet)
                            .frame(width: w * CGFloat(abs(tilt)) / 100)
                            .offset(x: -w / 4)
                    }
                    Rectangle()
                        .fill(TrendXTheme.outline)
                        .frame(width: 1, height: 14)
                }
            }
            .frame(height: 10)

            HStack {
                Text(a.labelLow)
                    .font(.system(size: 9, weight: .medium))
                Spacer()
                Text(a.labelHigh)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .padding(14)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
    }

    private func shareCard(dna: TrendXOpinionDNA) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("جملة المشاركة")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(TrendXTheme.aiViolet)
            Text("«\(dna.shareCaption)»")
                .font(.system(size: 14))
                .foregroundStyle(TrendXTheme.ink)
                .multilineTextAlignment(.trailing)
            ShareLink(item: dna.shareCaption) {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                    Text("شارك على شبكاتك")
                        .font(.system(size: 13, weight: .heavy))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(TrendXTheme.aiViolet)
                .foregroundStyle(.white)
                .cornerRadius(TrendXTheme.buttonRadius)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(TrendXTheme.aiViolet.opacity(0.06))
        .cornerRadius(TrendXTheme.cardRadius)
    }

    private var notReadyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles.tv.fill")
                .font(.system(size: 36))
                .foregroundStyle(TrendXTheme.aiViolet)
            Text("لم تكتمل هويّتك بعد")
                .font(.system(size: 18, weight: .bold))
            Text("شارك في 3 استطلاعات أو نبضات يوميّة لنبني هويّتك الفكريّة الكاملة.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
    }

    // MARK: - Actions

    private func load() async {
        guard let token = store.accessToken else { loading = false; return }
        loading = true
        defer { loading = false }
        do {
            let res = try await store.apiClient.myOpinionDNA(accessToken: token)
            await MainActor.run { self.dna = res }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
