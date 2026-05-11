//
//  SurveyTakingSheet.swift
//  TRENDX
//
//  Question-by-question survey runner. Stores the user's choices in
//  memory while they progress and POSTs them to /surveys/:id/respond
//  on completion. Falls back gracefully when offline (the AppStore
//  persists the response locally and bumps the counter optimistically).
//

import SwiftUI
import UIKit

struct SurveyTakingSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let survey: Survey

    @State private var currentIndex = 0
    @State private var answers: [UUID: UUID] = [:]            // questionId → optionId
    @State private var startedAt = Date()
    @State private var didSubmit = false

    private var question: SurveyQuestion? {
        guard currentIndex < survey.questions.count else { return nil }
        return survey.questions[currentIndex]
    }

    private var progress: Double {
        guard !survey.questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(survey.questions.count)
    }

    private var isLastQuestion: Bool {
        currentIndex == survey.questions.count - 1
    }

    private var canAdvance: Bool {
        guard let q = question else { return false }
        return answers[q.id] != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TrendXTheme.background.ignoresSafeArea()

                if didSubmit {
                    completionView
                } else if let q = question {
                    questionView(q)
                } else {
                    // No questions at all — defensive
                    VStack(spacing: 12) {
                        Image(systemName: "doc.questionmark")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        Text("لا توجد أسئلة في هذا الاستبيان")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }
                }
            }
            .navigationTitle(didSubmit ? "تمّت المشاركة" : survey.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(TrendXTheme.primary)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Question screen

    @ViewBuilder
    private func questionView(_ q: SurveyQuestion) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("سؤال \(currentIndex + 1) من \(survey.questions.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                    Spacer()
                    Text("+\(q.rewardPoints) نقطة")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(TrendXTheme.primary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(TrendXTheme.primary.opacity(0.10)))
                }
                ProgressView(value: progress)
                    .tint(TrendXTheme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text(q.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(TrendXTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    if let description = q.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                    }

                    VStack(spacing: 10) {
                        ForEach(q.options) { option in
                            optionRow(question: q, option: option)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            // Footer CTA
            VStack(spacing: 0) {
                Divider().opacity(0.4)
                HStack(spacing: 12) {
                    if currentIndex > 0 {
                        Button {
                            currentIndex -= 1
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.right")
                                Text("السابق")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(TrendXTheme.secondaryInk)
                            .padding(.vertical, 14).padding(.horizontal, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(TrendXTheme.surface)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        if isLastQuestion {
                            submit()
                        } else {
                            currentIndex += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(isLastQuestion ? "إرسال الإجابات" : "التالي")
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: isLastQuestion ? "checkmark" : "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canAdvance ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                                 : AnyShapeStyle(TrendXTheme.tertiaryInk.opacity(0.4)))
                        )
                        .shadow(
                            color: canAdvance ? TrendXTheme.primary.opacity(0.25) : .clear,
                            radius: 10, x: 0, y: 5
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAdvance)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(TrendXTheme.background)
            }
        }
    }

    private func optionRow(question q: SurveyQuestion, option: PollOption) -> some View {
        let selected = answers[q.id] == option.id

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                answers[q.id] = option.id
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(selected ? TrendXTheme.primary : TrendXTheme.tertiaryInk.opacity(0.5),
                                lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(TrendXTheme.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(option.text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? TrendXTheme.ink : TrendXTheme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? TrendXTheme.primary.opacity(0.08) : TrendXTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? TrendXTheme.primary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion screen

    @ViewBuilder
    private var completionView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TrendXTheme.background,
                    TrendXTheme.primary.opacity(0.08),
                    TrendXTheme.accent.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TrendXConfetti()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    completionSeal
                        .padding(.top, 24)

                    completionHeadline

                    completionStats

                    completionTier

                    completionActions
                        .padding(.top, 6)

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 22)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private var completionSeal: some View {
        ZStack {
            Circle()
                .fill(TrendXTheme.primary.opacity(0.10))
                .frame(width: 148, height: 148)
            Circle()
                .stroke(TrendXTheme.primary.opacity(0.28), lineWidth: 2)
                .frame(width: 120, height: 120)
            Circle()
                .fill(TrendXTheme.primaryGradient)
                .frame(width: 96, height: 96)
                .shadow(color: TrendXTheme.primary.opacity(0.45), radius: 22, x: 0, y: 12)
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.white)
        }
    }

    private var completionHeadline: some View {
        VStack(spacing: 6) {
            Text("صوتك سُجّل ✨")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text("جاوبت على \(survey.questions.count) سؤال — رأيك جزء من نبض الرأي السعودي.")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(TrendXTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
    }

    private var completionStats: some View {
        HStack(spacing: 12) {
            statTile(
                icon: "star.circle.fill",
                value: "+\(survey.rewardPoints)",
                label: "نقطة جديدة",
                tint: TrendXTheme.accent
            )
            statTile(
                icon: "questionmark.circle.fill",
                value: "\(survey.questions.count)",
                label: "إجابة",
                tint: TrendXTheme.primary
            )
            statTile(
                icon: "clock.fill",
                value: timeLabel,
                label: "الوقت",
                tint: TrendXTheme.aiIndigo
            )
        }
    }

    private func statTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(TrendXTheme.ink)
            Text(label)
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundStyle(TrendXTheme.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(tint.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var completionTier: some View {
        let pointsAfter = store.currentUser.points
        let tier = MemberTier.from(points: pointsAfter)
        let pointsToNext = tier.pointsToNext(points: pointsAfter)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tier.gradient)
                    .frame(width: 42, height: 42)
                Image(systemName: tier.icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("مستواك:")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                    Text(tier.label)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(TrendXTheme.ink)
                }
                if let next = tier.next, pointsToNext > 0 {
                    Text("يبقى \(pointsToNext) نقطة للوصول إلى \(next.label)")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                } else {
                    Text("وصلت لأعلى مستوى — ✦")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(tier.tint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(tier.tint.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var completionActions: some View {
        VStack(spacing: 10) {
            Button {
                let text = "شاركت في «\(survey.title)» على TRENDX وحصلت على \(survey.rewardPoints) نقطة. شاركني رأيك!"
                let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                presentSheet(av)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("شارك مع صديق")
                        .font(.system(size: 14, weight: .heavy))
                }
                .foregroundStyle(TrendXTheme.primaryDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(TrendXTheme.primary.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text("استكشف استبيانات أخرى")
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
    }

    private var timeLabel: String {
        let s = max(1, Int(Date().timeIntervalSince(startedAt)))
        return s >= 60 ? "\(s / 60)د \(s % 60)ث" : "\(s)ث"
    }

    private func presentSheet(_ vc: UIViewController) {
        let scenes = UIApplication.shared.connectedScenes
        guard let scene = scenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        presenter.present(vc, animated: true)
    }

    // MARK: - Submit

    private func submit() {
        let inputs = answers.map { (questionId, optionId) in
            SurveyAnswerInput(questionId: questionId, optionId: optionId, seconds: nil)
        }
        let elapsed = max(1, Int(Date().timeIntervalSince(startedAt)))
        store.submitSurveyResponse(
            surveyId: survey.id,
            answers: inputs,
            completionSeconds: elapsed
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            didSubmit = true
        }
    }
}
