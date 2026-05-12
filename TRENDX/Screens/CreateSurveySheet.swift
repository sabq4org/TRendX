//
//  CreateSurveySheet.swift
//  TRENDX
//
//  Lets a publisher (or any signed-in user) author a multi-question
//  survey and POST it to /surveys/create. Mirrors the editorial tone
//  of CreatePollSheet but stays focused on the multi-question case.
//

import SwiftUI

struct CreateSurveySheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var coverStyle: PollCoverStyle = .generic
    @State private var rewardPoints: Int = 120
    @State private var durationDays: Int = 14
    @State private var drafts: [QuestionDraft] = [
        QuestionDraft(),
        QuestionDraft(),
    ]

    private let durationOptions: [Int] = [3, 7, 14, 30]
    private let rewardOptions: [Int] = [80, 120, 200, 300]

    private var canPublish: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let validQuestions = drafts.filter(\.isValid)
        return hasTitle && validQuestions.count >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Header tip
                    headerTip

                    // Survey meta
                    surveyMetaCard

                    // Questions list
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("الأسئلة")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(TrendXTheme.secondaryInk)
                            Spacer()
                            Text("\(drafts.filter(\.isValid).count) من \(drafts.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                        }

                        ForEach(drafts.indices, id: \.self) { index in
                            QuestionCard(
                                index: index,
                                draft: $drafts[index],
                                canRemove: drafts.count > 2
                            ) {
                                drafts.remove(at: index)
                            }
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                drafts.append(QuestionDraft())
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("إضافة سؤال")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(TrendXTheme.primary.opacity(0.4),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(TrendXTheme.background.ignoresSafeArea())
            .navigationTitle("استبيان جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إلغاء") { dismiss() }
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("نشر") { publish() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(canPublish ? TrendXTheme.primary : TrendXTheme.tertiaryInk)
                        .disabled(!canPublish)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Header tip

    private var headerTip: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.aiGradient)
                    .frame(width: 30, height: 30)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("ابنِ استبياناً متماسكاً")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(TrendXTheme.aiIndigo)
                Text("سؤالان على الأقل — كل سؤال يحتاج خيارين على الأقل لتصبح النتائج مقروءة.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TrendXTheme.aiGradientSoft)
        )
    }

    // MARK: - Survey meta

    private var surveyMetaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title
            FieldLabel("العنوان")
            TextField("مثال: نظرتنا إلى الذكاء الاصطناعي في 2026", text: $title)
                .font(.system(size: 15, weight: .semibold))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TrendXTheme.softFill)
                )

            // Description
            FieldLabel("وصف مختصر — اختياري")
            ZStack(alignment: .topTrailing) {
                TextEditor(text: $description)
                    .font(.system(size: 14))
                    .frame(minHeight: 64)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TrendXTheme.softFill)
                    )
                if description.isEmpty {
                    Text("ما الزاوية التي يستكشفها الاستبيان؟")
                        .font(.system(size: 13))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }

            // Cover style
            FieldLabel("نمط الغلاف")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PollCoverStyle.allCases, id: \.self) { style in
                        Button { coverStyle = style } label: {
                            HStack(spacing: 6) {
                                Image(systemName: style.glyph)
                                    .font(.system(size: 11, weight: .bold))
                                Text(style.label)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(coverStyle == style ? .white : style.tint)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(coverStyle == style ? AnyShapeStyle(style.tint) : AnyShapeStyle(style.wash))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Duration / reward
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    FieldLabel("المدّة")
                    Picker("", selection: $durationDays) {
                        ForEach(durationOptions, id: \.self) { d in
                            Text("\(d) يوم").tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    FieldLabel("المكافأة")
                    Picker("", selection: $rewardPoints) {
                        ForEach(rewardOptions, id: \.self) { r in
                            Text("\(r)").tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TrendXTheme.surface)
        )
    }

    // MARK: - Submit

    private func publish() {
        let validDrafts = drafts.filter(\.isValid)
        let perQuestionReward = max(20, rewardPoints / max(1, validDrafts.count))
        let questions: [SurveyQuestion] = validDrafts.enumerated().map { idx, draft in
            let opts = draft.cleanedOptions().map { PollOption(text: $0) }
            return SurveyQuestion(
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: .singleChoice,
                options: opts,
                displayOrder: idx,
                rewardPoints: perQuestionReward
            )
        }

        let createdAt = Date()
        let survey = Survey(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: store.currentUser.name,
            authorAvatar: store.currentUser.avatarInitial,
            authorAvatarUrl: store.currentUser.avatarUrl,
            authorIsVerified: store.currentUser.isVerified,
            authorAccountType: store.currentUser.accountType,
            authorHandle: store.currentUser.handle,
            publisherId: store.currentUser.id,
            coverStyle: coverStyle,
            questions: questions,
            topicName: nil,
            totalResponses: 0,
            completionRate: 0,
            avgCompletionSeconds: 180,
            status: .active,
            createdAt: createdAt,
            expiresAt: createdAt.addingTimeInterval(Double(durationDays) * 24 * 60 * 60),
            rewardPoints: rewardPoints
        )

        store.createSurvey(survey)
        dismiss()
    }
}

// MARK: - Question draft model

struct QuestionDraft: Identifiable {
    let id = UUID()
    var title: String = ""
    var options: [String] = ["", ""]

    func cleanedOptions() -> [String] {
        options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var isValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle && cleanedOptions().count >= 2
    }
}

// MARK: - Question editor card

private struct QuestionCard: View {
    let index: Int
    @Binding var draft: QuestionDraft
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(TrendXTheme.primary))
                Text("سؤال")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
                Spacer()
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(TrendXTheme.error)
                            .padding(7)
                            .background(Circle().fill(TrendXTheme.error.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("نصّ السؤال", text: $draft.title)
                .font(.system(size: 14, weight: .semibold))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(TrendXTheme.softFill)
                )

            VStack(spacing: 8) {
                ForEach(draft.options.indices, id: \.self) { idx in
                    HStack(spacing: 10) {
                        Image(systemName: "circle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                        TextField("الخيار \(idx + 1)", text: $draft.options[idx])
                            .font(.system(size: 13))
                            .padding(.vertical, 10).padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(TrendXTheme.softFill)
                            )

                        if draft.options.count > 2 {
                            Button {
                                draft.options.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(TrendXTheme.tertiaryInk)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if draft.options.count < 6 {
                    Button {
                        draft.options.append("")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("خيار آخر")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(TrendXTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TrendXTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(draft.isValid ? TrendXTheme.primary.opacity(0.25) : TrendXTheme.tertiaryInk.opacity(0.15),
                        lineWidth: 1)
        )
    }
}

// MARK: - Helpers

private struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(TrendXTheme.tertiaryInk)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

