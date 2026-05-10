//
//  TrendXIndexScreen.swift
//  TRENDX
//
//  Public TRENDX Index — same JSON the dashboard /trendx-index page reads.
//  Six daily indicators of national mood, normalised to 0..100.
//

import SwiftUI

struct TrendXIndexScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var index: TrendXIndex?
    @State private var loading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                if loading {
                    ProgressView()
                        .padding(40)
                } else if let index {
                    composite(index: index)
                        .padding(.horizontal, 20)
                    metricsList(metrics: index.metrics)
                        .padding(.horizontal, 20)
                    footer
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Text("تعذّر تحميل المؤشّر")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        Button(action: { Task { await load() } }) {
                            Text("إعادة المحاولة")
                                .font(.system(size: 13, weight: .heavy))
                                .padding(.horizontal, 18).padding(.vertical, 9)
                                .background(TrendXTheme.primaryGradient)
                                .foregroundStyle(.white)
                                .cornerRadius(99)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
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
                Text("TRENDX INDEX")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(TrendXTheme.primary)
            }
            Text("نبض السعودية")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(TrendXTheme.ink)
            Text("لقطة يوميّة لاتجاهات الرأي في ست محاور رئيسية.")
                .font(.system(size: 13))
                .foregroundStyle(TrendXTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func composite(index: TrendXIndex) -> some View {
        let dirSymbol = index.compositeChange24h > 0 ? "arrow.up.right" : index.compositeChange24h < 0 ? "arrow.down.right" : "minus"
        let dirColor: Color = index.compositeChange24h > 0 ? TrendXTheme.success : index.compositeChange24h < 0 ? TrendXTheme.error : TrendXTheme.tertiaryInk
        return VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Spacer()
                Text("المؤشّر المركّب")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(TrendXTheme.primary)
            }
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                Text("/ 100")
                    .font(.system(size: 18))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Text("\(index.composite)")
                    .font(.system(size: 84, weight: .black))
                    .foregroundStyle(TrendXTheme.primary)
                    .monospacedDigit()
            }
            HStack(spacing: 6) {
                Spacer()
                Image(systemName: dirSymbol)
                    .foregroundStyle(dirColor)
                Text("\(index.compositeChange24h > 0 ? "+" : "")\(index.compositeChange24h) عن الأمس")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(dirColor)
            }
            HStack {
                Spacer()
                Text("استناداً إلى \(index.totalResponses) إجابة في آخر 7 أيام")
                    .font(.system(size: 11))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
            }
        }
        .padding(20)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 16, x: 0, y: 6)
    }

    private func metricsList(metrics: [TrendXIndexMetric]) -> some View {
        VStack(spacing: 12) {
            ForEach(metrics) { m in
                metricCard(m: m)
            }
        }
    }

    private func metricCard(m: TrendXIndexMetric) -> some View {
        let dirSymbol = m.direction == "up" ? "arrow.up.right" : m.direction == "down" ? "arrow.down.right" : "minus"
        let dirColor: Color = m.direction == "up" ? TrendXTheme.success : m.direction == "down" ? TrendXTheme.error : TrendXTheme.tertiaryInk
        return VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Image(systemName: dirSymbol)
                    .foregroundStyle(dirColor)
                Spacer()
                Text(m.name)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                Text("/100")
                    .font(.system(size: 14))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Text("\(m.value)")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(TrendXTheme.ink)
                    .monospacedDigit()
            }
            HStack {
                Spacer()
                Text("\(m.sampleSize) إجابة")
                    .font(.system(size: 11))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .monospacedDigit()
                Text("·")
                Text("\(m.change24h > 0 ? "+" : "")\(m.change24h)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(dirColor)
            }
            Text(m.blurb)
                .font(.system(size: 12))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            // Sparkbar
            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(TrendXTheme.paleFill)
                    RoundedRectangle(cornerRadius: 99)
                        .fill(TrendXTheme.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(m.value) / 100)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(TrendXTheme.surface)
        .cornerRadius(TrendXTheme.cardRadius)
        .shadow(color: TrendXTheme.shadow, radius: 10, x: 0, y: 3)
    }

    private var footer: some View {
        Text("البيانات مفتوحة للاستشهاد بشرط ذكر TRENDX كمصدر")
            .font(.system(size: 11))
            .foregroundStyle(TrendXTheme.tertiaryInk)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let res = try await store.apiClient.trendxIndex()
            await MainActor.run { self.index = res }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
