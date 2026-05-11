//
//  ProfileEditScreen.swift
//  TRENDX
//
//  Profile edit form, designed to feel like the rest of the app's
//  AI-tinted brand language. All saves go through AppStore.updateProfile
//  which round-trips /profile and refreshes currentUser, so the change
//  is reflected everywhere on success.
//

import SwiftUI
import UIKit

struct ProfileEditScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var email: String
    @State private var avatarUrl: String
    @State private var city: String
    @State private var region: String
    @State private var gender: UserGender
    @State private var birthYear: Int

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessToast = false

    private let originalUser: TrendXUser

    init(user: TrendXUser) {
        self.originalUser = user
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _avatarUrl = State(initialValue: user.avatarUrl ?? "")
        _city = State(initialValue: user.city ?? "")
        _region = State(initialValue: user.region ?? "")
        _gender = State(initialValue: user.gender)
        _birthYear = State(initialValue: user.birthYear ?? 2000)
    }

    private var hasChanges: Bool {
        name != originalUser.name
            || email != originalUser.email
            || (avatarUrl.isEmpty ? nil : avatarUrl) != originalUser.avatarUrl
            || (city.isEmpty ? nil : city) != originalUser.city
            || (region.isEmpty ? nil : region) != originalUser.region
            || gender != originalUser.gender
            || birthYear != (originalUser.birthYear ?? 2000)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    avatarHero
                        .padding(.top, 4)

                    formCard

                    saveButton
                        .padding(.top, 4)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(TrendXTheme.warning)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TrendXTheme.warning.opacity(0.10))
                            )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }

            if showSuccessToast {
                successToast
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("الملف الشخصي")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var canSave: Bool { hasChanges && isValid && !isSaving }

    // MARK: - Hero

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                TrendXTheme.background,
                TrendXTheme.primary.opacity(0.06),
                TrendXTheme.aiViolet.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var avatarHero: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 110, height: 110)
                    .shadow(color: TrendXTheme.primary.opacity(0.35), radius: 18, x: 0, y: 10)

                if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            avatarInitialView
                        }
                    }
                    .frame(width: 104, height: 104)
                    .clipShape(Circle())
                } else {
                    avatarInitialView
                }

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(TrendXTheme.accent))
                    .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    .shadow(color: TrendXTheme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                    .offset(x: 4, y: 4)
            }

            VStack(spacing: 4) {
                Text(name.isEmpty ? "اسمك" : name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(TrendXTheme.ink)
                MemberTierBadge(tier: MemberTier.from(points: store.currentUser.points), compact: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var avatarInitialView: some View {
        Text(String(name.prefix(1)))
            .font(.system(size: 44, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 0) {
            FieldRow(icon: "person.fill", label: "الاسم", placeholder: "اسمك الكامل", text: $name)
            divider
            FieldRow(icon: "envelope.fill", label: "البريد", placeholder: "you@example.com", text: $email, keyboard: .emailAddress)
            divider
            FieldRow(icon: "photo.fill", label: "رابط الصورة", placeholder: "URL اختياري", text: $avatarUrl, keyboard: .URL, autocap: false)
            divider
            FieldRow(icon: "mappin.and.ellipse", label: "المدينة", placeholder: "الرياض، جدة، …", text: $city)
            divider
            FieldRow(icon: "map.fill", label: "المنطقة", placeholder: "اختياري", text: $region)
            divider

            // Gender picker
            HStack(spacing: 12) {
                fieldIcon("figure.dress.line.vertical.figure")
                Text("الجنس")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .frame(width: 70, alignment: .leading)
                Picker("الجنس", selection: $gender) {
                    Text("ذكر").tag(UserGender.male)
                    Text("أنثى").tag(UserGender.female)
                    Text("غير محدد").tag(UserGender.unspecified)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            divider

            // Birth year stepper
            HStack(spacing: 12) {
                fieldIcon("birthday.cake.fill")
                Text("سنة الميلاد")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                Spacer()
                HStack(spacing: 8) {
                    Button { if birthYear > 1940 { birthYear -= 1 } } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    Text("\(String(birthYear))")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(TrendXTheme.ink)
                        .frame(minWidth: 50)
                    Button { if birthYear < Calendar.current.component(.year, from: Date()) { birthYear += 1 } } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(TrendXTheme.primary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(TrendXTheme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(TrendXTheme.surface)
                .shadow(color: TrendXTheme.shadow, radius: 12, x: 0, y: 4)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(TrendXTheme.outline.opacity(0.4))
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }

    private func fieldIcon(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(TrendXTheme.primary.opacity(0.10))
                .frame(width: 28, height: 28)
            Image(systemName: name)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(TrendXTheme.primary)
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white).scaleEffect(0.85)
                }
                Text(isSaving ? "جاري الحفظ…" : "حفظ التغييرات")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                if !isSaving {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(canSave ? AnyShapeStyle(TrendXTheme.primaryGradient)
                                  : AnyShapeStyle(TrendXTheme.tertiaryInk.opacity(0.4)))
            )
            .shadow(color: canSave ? TrendXTheme.primary.opacity(0.35) : .clear,
                    radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await store.updateProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                avatarInitial: String(name.trimmingCharacters(in: .whitespaces).prefix(1)),
                avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl,
                gender: gender.rawValue,
                birthYear: birthYear,
                city: city.isEmpty ? nil : city,
                region: region.isEmpty ? nil : region
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                showSuccessToast = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Toast

    private var successToast: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.success.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(TrendXTheme.success)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("تم حفظ ملفّك")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(TrendXTheme.ink)
                Text("ستظهر التغييرات في كل أنحاء التطبيق")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TrendXTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(TrendXTheme.success.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: TrendXTheme.success.opacity(0.15), radius: 14, x: 0, y: 6)
        )
    }
}

// MARK: - FieldRow

private struct FieldRow: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TrendXTheme.primary.opacity(0.10))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(TrendXTheme.primary)
            }
            Text(label)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(TrendXTheme.tertiaryInk)
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TrendXTheme.ink)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap ? .sentences : .never)
                .autocorrectionDisabled(!autocap)
                .multilineTextAlignment(.leading)
                .submitLabel(.next)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
