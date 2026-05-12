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
import PhotosUI

struct ProfileEditScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var email: String
    @State private var avatarUrl: String
    @State private var bannerUrl: String
    @State private var handle: String
    @State private var bio: String
    @State private var city: String
    @State private var country: String
    @State private var gender: UserGender
    @State private var birthYear: Int
    @State private var accountType: AccountType

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessToast = false
    @State private var handleHint: String?

    /// Photo picker selections. We immediately transcode the selection
    /// into a compressed base64 data-URL and stuff it into avatarUrl /
    /// bannerUrl, so the next "Save" round-trips it through the existing
    /// `/profile` endpoint without needing a separate upload pipeline.
    @State private var avatarItem: PhotosPickerItem?
    @State private var bannerItem: PhotosPickerItem?
    @State private var isProcessingImage = false

    private let originalUser: TrendXUser

    init(user: TrendXUser) {
        self.originalUser = user
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _avatarUrl = State(initialValue: user.avatarUrl ?? "")
        _bannerUrl = State(initialValue: user.bannerUrl ?? "")
        _handle = State(initialValue: user.handle ?? "")
        _bio = State(initialValue: user.bio ?? "")
        _city = State(initialValue: user.city ?? "")
        // The country picker mirrors `user.country` (ISO-2 code, e.g.
        // "SA"). Falls back to Saudi Arabia for fresh accounts so the
        // form starts at the most likely choice rather than empty.
        _country = State(initialValue: user.country.isEmpty ? "SA" : user.country)
        _gender = State(initialValue: user.gender)
        _birthYear = State(initialValue: user.birthYear ?? 2000)
        _accountType = State(initialValue: user.accountType)
    }

    private var hasChanges: Bool {
        name != originalUser.name
            || email != originalUser.email
            || (avatarUrl.isEmpty ? nil : avatarUrl) != originalUser.avatarUrl
            || (bannerUrl.isEmpty ? nil : bannerUrl) != originalUser.bannerUrl
            || (handle.isEmpty ? nil : handle) != originalUser.handle
            || (bio.isEmpty ? nil : bio) != originalUser.bio
            || (city.isEmpty ? nil : city) != originalUser.city
            || country != (originalUser.country.isEmpty ? "SA" : originalUser.country)
            || gender != originalUser.gender
            || birthYear != (originalUser.birthYear ?? 2000)
            || accountType != originalUser.accountType
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
            // Banner picker — only meaningful for organizations and
            // government accounts that want a branded header on their
            // public profile. Individuals can still set one if they like.
            bannerStrip

            // Avatar circle + camera badge. The PhotosPicker is hosted
            // via `.overlay(alignment:)` rather than as a ZStack child
            // so its hit region isn't shadowed by the avatar image
            // sitting in the same ZStack. This was the root cause of
            // the camera badge looking right but never opening the
            // picker on tap.
            ZStack {
                Circle()
                    .fill(TrendXTheme.primaryGradient)
                    .frame(width: 110, height: 110)
                    .shadow(color: TrendXTheme.primary.opacity(0.35), radius: 18, x: 0, y: 10)

                TrendXProfileImage(urlString: avatarUrl)
                    .frame(width: 104, height: 104)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            }
            .frame(width: 110, height: 110)
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $avatarItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(TrendXTheme.accent)
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(.white, lineWidth: 2.5))
                            .shadow(color: TrendXTheme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                        Image(systemName: isProcessingImage ? "hourglass" : "camera.fill")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .contentShape(Circle())
                }
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
        .onChange(of: avatarItem) { _, newValue in
            Task { await loadPickedImage(newValue, target: .avatar) }
        }
        .onChange(of: bannerItem) { _, newValue in
            Task { await loadPickedImage(newValue, target: .banner) }
        }
    }

    private var bannerStrip: some View {
        // Banner preview + picker, with the picker hosted as a
        // `.overlay` so its hit area isn't intercepted by the image
        // beneath it (same fix as the avatar camera badge below).
        TrendXProfileImage(urlString: bannerUrl) {
            ZStack {
                LinearGradient(
                    colors: [
                        TrendXTheme.primary.opacity(0.20),
                        TrendXTheme.aiViolet.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 4) {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(TrendXTheme.primary.opacity(0.7))
                    Text("غلاف الصفحة العامة")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(TrendXTheme.secondaryInk)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TrendXTheme.outline, lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .overlay(alignment: .bottomLeading) {
            PhotosPicker(selection: $bannerItem, matching: .images) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 10, weight: .heavy))
                    Text(bannerUrl.isEmpty ? "اختر الغلاف" : "تغيير الغلاف")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(.black.opacity(0.55)))
                .contentShape(Capsule())
            }
            .padding(8)
        }
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
            FieldRow(icon: "at", label: "المعرّف", placeholder: "username بدون @", text: $handle, keyboard: .asciiCapable, autocap: false)
            if let handleHint {
                Text(handleHint)
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundStyle(TrendXTheme.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            divider
            FieldRow(icon: "envelope.fill", label: "البريد", placeholder: "you@example.com", text: $email, keyboard: .emailAddress)
            divider
            FieldRow(icon: "text.alignright", label: "نبذة", placeholder: "وصف قصير عنك أو عن حسابك", text: $bio)
            divider
            FieldRow(icon: "mappin.and.ellipse", label: "المدينة", placeholder: "الرياض، جدة، …", text: $city)
            divider

            // Country picker — replaces the older free-text "المنطقة"
            // field. ISO-2 codes go to the backend; the menu shows the
            // Arabic name. Saudi Arabia leads the list as the default
            // for TRENDX's primary market.
            HStack(spacing: 12) {
                fieldIcon("globe")
                Text("الدولة")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TrendXTheme.tertiaryInk)
                    .frame(width: 70, alignment: .leading)
                Spacer(minLength: 0)
                Menu {
                    ForEach(TrendXCountryList.countries, id: \.code) { option in
                        Button {
                            country = option.code
                        } label: {
                            HStack {
                                Text("\(option.flag) \(option.name)")
                                if country == option.code {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(TrendXCountryList.displayName(forCode: country))
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(TrendXTheme.ink)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(TrendXTheme.tertiaryInk)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(TrendXTheme.softFill))
                    .contentShape(Capsule())
                }
                .menuStyle(.button)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            divider

            // Account type — individual or organization. Government is
            // promoted only by admin operations, so we exclude it here.
            if accountType != .government {
                HStack(spacing: 12) {
                    fieldIcon("building.2.fill")
                    Text("نوع الحساب")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(TrendXTheme.tertiaryInk)
                        .frame(width: 84, alignment: .leading)
                    Picker("نوع الحساب", selection: $accountType) {
                        Text("فرد").tag(AccountType.individual)
                        Text("منظّمة").tag(AccountType.organization)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                divider
            }

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

    // MARK: - Image picker handling

    private enum ImageTarget { case avatar, banner }

    /// Load a `PhotosPickerItem`, resize + JPEG-compress it, then encode
    /// as a base64 `data:` URL we can ship through the existing
    /// `/profile` endpoint. Avatars are limited to ~512px and banners to
    /// ~1024px so the resulting payload stays small (typically <120KB).
    private func loadPickedImage(_ item: PhotosPickerItem?, target: ImageTarget) async {
        guard let item else { return }
        isProcessingImage = true
        defer { isProcessingImage = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "تعذّر قراءة الصورة، حاول اختيار صورة أخرى."
            return
        }
        guard let original = UIImage(data: data) else {
            errorMessage = "صيغة الصورة غير مدعومة."
            return
        }

        // Avatars: smaller (max 480px) and tighter compression (0.6).
        // Banners: stay a touch larger (max 960px) at 0.55. Both
        // budgets keep the base64-encoded payload comfortably under
        // 80KB for typical photos, down from ~150KB at quality 0.72,
        // which the perf audit identified as the biggest contributor
        // to slow polls-feed rendering on profile pages.
        let maxDim: CGFloat = target == .avatar ? 480 : 960
        let quality: CGFloat = target == .avatar ? 0.6 : 0.55
        let resized = original.trendxResized(maxDimension: maxDim)
        guard let jpeg = resized.jpegData(compressionQuality: quality) else {
            errorMessage = "فشل ضغط الصورة."
            return
        }

        let dataURL = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        switch target {
        case .avatar: avatarUrl = dataURL
        case .banner: bannerUrl = dataURL
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await store.updateProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                handle: handle.isEmpty ? nil : handle.replacingOccurrences(of: "@", with: ""),
                bio: bio.isEmpty ? nil : bio,
                avatarInitial: String(name.trimmingCharacters(in: .whitespaces).prefix(1)),
                avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl,
                bannerUrl: bannerUrl.isEmpty ? nil : bannerUrl,
                accountType: accountType == .government ? nil : accountType,
                gender: gender.rawValue,
                birthYear: birthYear,
                city: city.isEmpty ? nil : city,
                country: country
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

// MARK: - Image helper used by the profile preview hero
//
// Centralizes the "render a URL string that might be a remote http URL
// or an inline base64 data-URL" dance. AsyncImage can't decode `data:`
// URLs reliably, so we sniff the scheme and route accordingly.

struct TrendXProfileImage<Placeholder: View>: View {
    let urlString: String?
    @ViewBuilder var placeholder: () -> Placeholder

    init(urlString: String?, @ViewBuilder placeholder: @escaping () -> Placeholder = { EmptyView() }) {
        self.urlString = urlString
        self.placeholder = placeholder
    }

    var body: some View {
        if let raw = urlString, !raw.isEmpty {
            if raw.hasPrefix("data:") {
                // Cached path — data: URLs are content-addressable so we
                // can key by the URL string. Decoding 100KB+ base64
                // images on every SwiftUI body re-evaluation was a
                // major source of UI jank on profile screens that show
                // the same logo dozens of times (each poll card).
                if let ui = TrendXImageCache.shared.image(for: raw) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    placeholder()
                }
            } else if let url = URL(string: raw) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        placeholder()
                    case .failure:
                        placeholder()
                    @unknown default:
                        placeholder()
                    }
                }
            } else {
                placeholder()
            }
        } else {
            placeholder()
        }
    }
}

// MARK: - Image cache

/// Lightweight singleton wrapper around `NSCache<NSString, UIImage>`
/// to keep decoded `data:` URLs in memory. The whole point is that
/// each base64-encoded logo (typically 80-150KB encoded, ~250KB
/// decoded) only gets decoded once per process. Cleared automatically
/// under memory pressure by NSCache.
final class TrendXImageCache {
    static let shared = TrendXImageCache()
    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 80
        c.totalCostLimit = 32 * 1024 * 1024 // ~32 MB of decoded image data
        return c
    }()

    private init() {}

    func image(for urlString: String) -> UIImage? {
        let key = urlString as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = Self.decodeDataURL(urlString),
              let image = UIImage(data: data) else { return nil }
        // Cost ≈ pixel bytes (width × height × 4). Falls back to
        // encoded data size when the image is opaque or has weird CG
        // backing — close enough for our LRU budget.
        let cost = image.cgImage.map { $0.width * $0.height * 4 } ?? data.count
        cache.setObject(image, forKey: key, cost: cost)
        return image
    }

    private static func decodeDataURL(_ raw: String) -> Data? {
        guard let comma = raw.firstIndex(of: ",") else { return nil }
        let base64Part = String(raw[raw.index(after: comma)...])
        return Data(base64Encoded: base64Part)
    }
}

extension UIImage {
    /// Returns a copy scaled so the longest edge is `maxDimension` while
    /// preserving aspect ratio. Used to keep base64-encoded avatars and
    /// banners under ~120KB without burning device cycles re-encoding
    /// images that are already small enough.
    func trendxResized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Country list
//
// Short curated list focused on Arab markets — Saudi Arabia first since
// that is TRENDX's primary launch market. ISO-3166 alpha-2 codes go to
// the backend; the menu shows the Arabic name and a flag emoji so the
// picker reads as a brand-y "where are you" rather than a dropdown of
// 195 obscure entries. "—" code is reserved for "other" (no country
// override).

enum TrendXCountryList {
    struct Country {
        let code: String
        let name: String
        let flag: String
    }

    static let countries: [Country] = [
        .init(code: "SA", name: "السعودية",   flag: "🇸🇦"),
        .init(code: "AE", name: "الإمارات",   flag: "🇦🇪"),
        .init(code: "KW", name: "الكويت",     flag: "🇰🇼"),
        .init(code: "QA", name: "قطر",        flag: "🇶🇦"),
        .init(code: "BH", name: "البحرين",    flag: "🇧🇭"),
        .init(code: "OM", name: "عُمان",       flag: "🇴🇲"),
        .init(code: "YE", name: "اليمن",      flag: "🇾🇪"),
        .init(code: "EG", name: "مصر",         flag: "🇪🇬"),
        .init(code: "JO", name: "الأردن",     flag: "🇯🇴"),
        .init(code: "IQ", name: "العراق",     flag: "🇮🇶"),
        .init(code: "LB", name: "لبنان",      flag: "🇱🇧"),
        .init(code: "SY", name: "سوريا",      flag: "🇸🇾"),
        .init(code: "PS", name: "فلسطين",     flag: "🇵🇸"),
        .init(code: "LY", name: "ليبيا",      flag: "🇱🇾"),
        .init(code: "TN", name: "تونس",       flag: "🇹🇳"),
        .init(code: "DZ", name: "الجزائر",    flag: "🇩🇿"),
        .init(code: "MA", name: "المغرب",     flag: "🇲🇦"),
        .init(code: "SD", name: "السودان",    flag: "🇸🇩"),
        .init(code: "MR", name: "موريتانيا",  flag: "🇲🇷"),
        .init(code: "DJ", name: "جيبوتي",     flag: "🇩🇯"),
        .init(code: "SO", name: "الصومال",    flag: "🇸🇴"),
        .init(code: "KM", name: "جزر القمر",  flag: "🇰🇲"),
        .init(code: "XX", name: "أخرى",        flag: "🌍"),
    ]

    static func displayName(forCode code: String) -> String {
        guard let match = countries.first(where: { $0.code == code }) else {
            return "🇸🇦 السعودية"
        }
        return "\(match.flag) \(match.name)"
    }
}
