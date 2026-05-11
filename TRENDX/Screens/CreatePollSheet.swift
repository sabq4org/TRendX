//
//  CreatePollSheet.swift
//  TRENDX
//

import SwiftUI

struct CreatePollSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var question = ""
    @State private var options: [String] = ["", ""]
    @State private var selectedType: PollType = .singleChoice
    @State private var selectedTopic: Topic?
    @State private var durationDays = 2
    @State private var addImage = false
    @State private var addVideo = false
    @State private var aiSuggestions: [String] = []
    @State private var aiRationale = ""
    @State private var isGeneratingAI = false
    
    private let durationOptions = [1, 2, 3, 7, 14, 30]
    
    private var canPublish: Bool {
        let hasQuestion = !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && question.count <= 500
        switch selectedType {
        case .singleChoice, .multipleChoice:
            return hasQuestion && choiceOptions.count >= 2
        case .rating, .linearScale:
            return hasQuestion
        }
    }

    private var clarityScore: Int {
        TrendXAI.clarityScore(question: question, options: publishableOptionTexts)
    }

    private var choiceOptions: [String] {
        options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var publishableOptionTexts: [String] {
        switch selectedType {
        case .singleChoice, .multipleChoice:
            return choiceOptions
        case .rating:
            return ["1", "2", "3", "4", "5"]
        case .linearScale:
            return (1...10).map(String.init)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // AI Assist tip
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(TrendXTheme.aiGradient)
                                .frame(width: 30, height: 30)
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("TRENDX AI يساعدك")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(TrendXTheme.aiIndigo)
                            Text("صِغ سؤالاً واضحاً بخيارات موزونة — أسئلة اليوم تصنع رؤى الغد.")
                                .font(.system(size: 12.5, weight: .medium))
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TrendXTheme.aiIndigo.opacity(0.14), lineWidth: 1)
                    )

                    AIAssistPanel(
                        score: clarityScore,
                        suggestions: aiSuggestions,
                        rationale: aiRationale,
                        isLoading: isGeneratingAI,
                        onGenerate: generateSuggestions,
                        onApply: applySuggestions
                    )

                    // Question Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("عنوان المنشور")
                            .font(.trendxCaption())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        
                        ZStack(alignment: .topTrailing) {
                            TextEditor(text: $question)
                                .font(.trendxBody())
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(TrendXTheme.softFill)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            
                            if question.isEmpty {
                                Text("اضف سؤالك هنا")
                                    .font(.trendxBody())
                                    .foregroundStyle(TrendXTheme.tertiaryInk)
                                    .padding(16)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(question.count)/500")
                                .font(.trendxSmall())
                                .foregroundStyle(TrendXTheme.tertiaryInk)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        MediaButton(icon: "photo", title: "صورة قريباً", isSelected: addImage, isDisabled: true) {}
                        MediaButton(icon: "video", title: "فيديو قريباً", isSelected: addVideo, isDisabled: true) {}
                    }
                    
                    Divider()
                    
                    // Poll Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("نوع السؤال")
                            .font(.trendxCaption())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        
                        // Type Selection
                        FlowLayout(spacing: 10) {
                            ForEach(PollType.allCases, id: \.self) { type in
                                PollTypeChip(type: type, isSelected: selectedType == type) {
                                    selectedType = type
                                    generateSuggestions()
                                }
                            }
                        }

                        Text(typeHelperText)
                            .font(.trendxSmall())
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Options Input (for choice types)
                    if selectedType == .singleChoice || selectedType == .multipleChoice {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("الخيارات")
                                .font(.trendxCaption())
                                .foregroundStyle(TrendXTheme.secondaryInk)
                            
                            ForEach(options.indices, id: \.self) { index in
                                HStack(spacing: 12) {
                                    TextField("الخيار \(index + 1)", text: $options[index])
                                        .font(.trendxBody())
                                        .padding(14)
                                        .background(TrendXTheme.softFill)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    
                                    if options.count > 2 {
                                        Button {
                                            options.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(TrendXTheme.error)
                                        }
                                    }
                                }
                            }
                            
                            // Add Option Button
                            Button {
                                if options.count < 6 {
                                    options.append("")
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("إضافة خيار")
                                }
                                .font(.trendxCaption())
                                .foregroundStyle(TrendXTheme.primary)
                            }
                            .disabled(options.count >= 6)
                        }
                    } else {
                        ScalePreview(type: selectedType)
                    }
                    
                    Divider()
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("مدة المنشور")
                            .font(.trendxCaption())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        
                        HStack(spacing: 12) {
                            // Number Input
                            HStack {
                                Spacer()
                                Text("\(durationDays)")
                                    .font(.trendxHeadline())
                                    .foregroundStyle(TrendXTheme.ink)
                                Spacer()
                            }
                            .frame(height: 50)
                            .background(TrendXTheme.softFill)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            // Unit Picker
                            Menu {
                                ForEach(durationOptions, id: \.self) { days in
                                    Button("\(days) يوم") {
                                        durationDays = days
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("يوم")
                                        .font(.trendxBody())
                                        .foregroundStyle(TrendXTheme.ink)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(TrendXTheme.tertiaryInk)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(TrendXTheme.softFill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    
                    // Topic Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("للمواضيع")
                            .font(.trendxCaption())
                            .foregroundStyle(TrendXTheme.secondaryInk)
                        
                        Menu {
                            ForEach(store.topics) { topic in
                                Button {
                                    selectedTopic = topic
                                } label: {
                                    Label(topic.name, systemImage: topic.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedTopic?.name ?? "اختر موضوعًا")
                                    .font(.trendxBody())
                                    .foregroundStyle(selectedTopic == nil ? TrendXTheme.tertiaryInk : TrendXTheme.ink)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundStyle(TrendXTheme.tertiaryInk)
                            }
                            .padding(14)
                            .background(TrendXTheme.softFill)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .trendxScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("منشور جديد")
                        .font(.trendxSubheadline())
                        .foregroundStyle(TrendXTheme.ink)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إلغاء") {
                        dismiss()
                    }
                    .foregroundStyle(TrendXTheme.error)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("نشر") {
                        publishPoll()
                    }
                    .font(.trendxBodyBold())
                    .foregroundStyle(canPublish ? TrendXTheme.primary : TrendXTheme.tertiaryInk)
                    .disabled(!canPublish)
                }
            }
        }
    }
    
    private func publishPoll() {
        let pollOptions = publishableOptionTexts.map { PollOption(text: $0) }

        let cover = PollCoverStyle.from(topicName: selectedTopic?.name)

        let poll = Poll(
            title: question.trimmingCharacters(in: .whitespacesAndNewlines),
            coverStyle: cover,
            options: pollOptions,
            topicId: selectedTopic?.id,
            topicName: selectedTopic?.name,
            type: selectedType,
            durationDays: durationDays,
            expiresAt: Date().addingTimeInterval(Double(durationDays) * 24 * 60 * 60)
        )

        store.createPoll(poll)
        dismiss()
    }

    private func generateSuggestions() {
        isGeneratingAI = true
        Task {
            let result = await store.composePoll(
                question: question,
                topicName: selectedTopic?.name,
                type: selectedType
            )
            aiSuggestions = result.options
            aiRationale = result.rationale
            isGeneratingAI = false
        }
    }

    private func applySuggestions() {
        if aiSuggestions.isEmpty {
            generateSuggestions()
            return
        }

        if question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !aiSuggestions.isEmpty {
            question = TrendXAI.suggestedQuestion(topicName: selectedTopic?.name, type: selectedType)
        }

        if selectedType == .singleChoice || selectedType == .multipleChoice {
            options = aiSuggestions
        }
    }

    private var typeHelperText: String {
        switch selectedType {
        case .singleChoice:
            return "يناسب سؤالاً له إجابة واحدة واضحة."
        case .multipleChoice:
            return "يسمح للمستخدم باختيار أكثر من إجابة في النسخ القادمة، ويحفظ حالياً كاستطلاع متعدد الخيارات."
        case .rating:
            return "سيتم إنشاء مقياس تقييم من 1 إلى 5 تلقائياً."
        case .linearScale:
            return "سيتم إنشاء مقياس خطي من 1 إلى 10 تلقائياً."
        }
    }
}

private struct AIAssistPanel: View {
    let score: Int
    let suggestions: [String]
    let rationale: String
    let isLoading: Bool
    let onGenerate: () -> Void
    let onApply: () -> Void

    private var tint: Color {
        if score >= 80 { return TrendXTheme.success }
        if score >= 60 { return TrendXTheme.warning }
        return TrendXTheme.aiIndigo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("درجة وضوح السؤال")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(TrendXTheme.aiInk)
                    Text("TRENDX AI يقيس الصياغة وعدد الخيارات وتوازنها.")
                        .font(.trendxSmall())
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }

                Spacer()

                Text("\(score)%")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(TrendXTheme.softFill)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(geo.size.width * CGFloat(score) / 100, 8))
                }
            }
            .frame(height: 7)

            if !suggestions.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TrendXTheme.aiInk)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(TrendXTheme.aiGradientSoft))
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: onGenerate) {
                    Label(isLoading ? "يفكر…" : "اقترح خيارات", systemImage: "sparkles")
                        .font(.trendxCaption())
                        .foregroundStyle(TrendXTheme.aiIndigo)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(TrendXTheme.aiIndigo.opacity(0.10)))
                }
                .disabled(isLoading)

                Button(action: onApply) {
                    Label("تطبيق", systemImage: "wand.and.stars")
                        .font(.trendxCaption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(TrendXTheme.primary))
                }
                .disabled(suggestions.isEmpty)
                .opacity(suggestions.isEmpty ? 0.45 : 1)
            }

            if !rationale.isEmpty {
                Text(rationale)
                    .font(.trendxSmall())
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(TrendXTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TrendXTheme.aiIndigo.opacity(0.16), lineWidth: 0.8)
        )
    }
}

struct MediaButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.trendxCaption())
            }
            .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? TrendXTheme.primary : TrendXTheme.softFill)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.58 : 1)
    }
}

private struct ScalePreview: View {
    let type: PollType

    private var labels: [String] {
        type == .rating ? ["1", "2", "3", "4", "5"] : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type == .rating ? "مقياس التقييم" : "المقياس الخطي")
                .font(.trendxCaption())
                .foregroundStyle(TrendXTheme.secondaryInk)

            FlowLayout(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(TrendXTheme.primary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                }
            }
        }
    }
}

struct PollTypeChip: View {
    let type: PollType
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch type {
        case .singleChoice: return "checkmark.circle"
        case .multipleChoice: return "checkmark.square"
        case .rating: return "star"
        case .linearScale: return "slider.horizontal.3"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 14))
                Text(type.displayName)
                    .font(.trendxCaption())
            }
            .foregroundStyle(isSelected ? .white : TrendXTheme.secondaryInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? TrendXTheme.primary : TrendXTheme.softFill)
            )
        }
        .buttonStyle(.plain)
    }
}

// Simple Flow Layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        let containerWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }
        
        return (positions, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

#Preview {
    CreatePollSheet()
        .environmentObject(AppStore())
        .trendxRTL()
}
