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

struct SurveyTakingSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let survey: Survey

    @State private var currentIndex = 0
    @State private var answers: [UUID: UUID] = [:]            // questionId → optionId
    @State private var startedAt = Date()
    @State private var didSubmit = false

    private var question: Poll? {
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
    private func questionView(_ q: Poll) -> some View {
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
                        .multilineTextAlignment(.trailing)

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

    private func optionRow(question q: Poll, option: PollOption) -> some View {
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
                    .multilineTextAlignment(.trailing)
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

    private var completionView: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: TrendXTheme.primary.opacity(0.25), radius: 18, x: 0, y: 10)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("شكراً لمشاركتك ✨")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(TrendXTheme.ink)
                Text("سُجّلت إجاباتك. حصلت على \(survey.rewardPoints) نقطة جديدة.")
                    .font(.system(size: 14))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("العودة")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(TrendXTheme.primaryGradient)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding(.top, 60)
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
