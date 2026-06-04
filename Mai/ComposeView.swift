import SwiftUI

struct ComposeView: View {
    @Environment(AppStore.self) var store
    @Environment(\.colors) var c
    var onClose: () -> Void
    var onCreate: (Letter) -> Void

    @State private var step = 0
    @State private var phase: Phase = .form
    @State private var toSelf = true
    @State private var otherName = ""
    @State private var title = ""
    @State private var letterBody = ""
    @State private var attachTypes: Set<AttachKind> = []
    @State private var whenKind: WhenKind = .year
    @State private var customDate = ""

    enum Phase { case form, sealing, done }
    enum AttachKind: String, CaseIterable, Hashable {
        case photo = "photo", voice = "voice", file = "file"
        var label: String { switch self { case .photo: "Ảnh"; case .voice: "Ghi âm"; case .file: "Tệp" } }
        var icon: String { switch self { case .photo: "photo.fill"; case .voice: "waveform"; case .file: "doc.fill" } }
    }
    enum WhenKind: Hashable { case year, birthday, tet, custom }

    private var now: Date { Date() }

    private var openISO: String {
        switch whenKind {
        case .year:     return toISO(Calendar.current.date(byAdding: .day, value: 365, to: now)!)
        case .birthday: return toISO(nextBirthday(birthISO: store.profile.birthISO, from: now))
        case .tet:      return nextTet(from: now).iso
        case .custom:
            if let d = parseISO(customDate) { return toISO(d) }
            return toISO(Calendar.current.date(byAdding: .day, value: 365, to: now)!)
        }
    }

    private var canNext: Bool {
        switch step {
        case 0: return toSelf || !otherName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !title.trimmingCharacters(in: .whitespaces).isEmpty && !letterBody.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return whenKind != .custom || !customDate.isEmpty
        default: return true
        }
    }

    private var sealChar: String {
        String((store.profile.name.isEmpty ? "M" : store.profile.name).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            c.bg.ignoresSafeArea()
            StarField(count: 26)

            if phase != .form {
                sealingOverlay
            } else {
                formContent
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sealing / done overlay

    var sealingOverlay: some View {
        VStack(spacing: 0) {
            ZStack {
                EnvelopeView(width: 250, open: false, broken: false, seal: sealChar)
                if phase == .sealing {
                    WaxSeal(size: 64, label: sealChar)
                        .offset(y: -10)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity))
                        .animation(.spring(response: 0.85, dampingFraction: 0.6), value: phase)
                }
            }
            .padding(.top, 80)

            if phase == .done {
                VStack(spacing: 0) {
                    Text("Đã niêm phong")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(c.text)
                        .padding(.top, 36)
                    (Text("Bức thư ")
                        .foregroundColor(c.muted)
                        + Text("\"\(title.trimmingCharacters(in: .whitespaces))\"")
                            .fontWeight(.semibold)
                            .foregroundColor(c.text)
                        + Text(" sẽ mở vào")
                            .foregroundColor(c.muted))
                        .font(.maiBody)
                    if let openDate = parseISO(openISO) {
                        Text(fmtDate(openDate))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(c.accent)
                            .padding(.top, 10)
                        let dp = diffParts(target: openDate, from: now)
                        Text("còn \(dp.d) ngày · không thể đọc trước đó")
                            .font(.system(size: 13))
                            .foregroundColor(c.muted)
                            .padding(.top, 4)
                    }
                    PrimaryButton(label: "Xong", fullWidth: false, action: finish)
                        .padding(.top, 32)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .transition(.opacity)
            } else {
                Text("Đang niêm phong…")
                    .font(.maiBody)
                    .foregroundColor(c.muted)
                    .padding(.top, 36)
            }
            Spacer()
        }
        .onAppear {
            if phase == .sealing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { phase = .done }
                }
            }
        }
    }

    // MARK: - Form

    var formContent: some View {
        VStack(spacing: 0) {
            OverlayHeader(
                onBack: { if step > 0 { step -= 1 } else { onClose() } },
                onClose: onClose,
                title: "Thư mới",
                step: step,
                totalSteps: 5
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    stepContent
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }

            // Footer
            VStack(spacing: 0) {
                if step < 4 {
                    PrimaryButton(label: "Tiếp tục", icon: "arrow.right", fullWidth: true) {
                        withAnimation { step += 1 }
                    }
                    .disabled(!canNext)
                    .opacity(canNext ? 1 : 0.4)
                } else {
                    PrimaryButton(label: "Niêm phong & gửi đi", icon: "lock.fill", fullWidth: true) {
                        withAnimation { phase = .sealing }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
            .background(
                LinearGradient(colors: [.clear, c.bg], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                    .allowsHitTesting(false),
                alignment: .top
            )
        }
    }

    @ViewBuilder var stepContent: some View {
        switch step {
        case 0: recipientStep
        case 1: writeStep
        case 2: attachStep
        case 3: whenStep
        default: reviewStep
        }
    }

    // MARK: Steps

    var recipientStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Gửi cho ai?").font(.system(size: 26, weight: .semibold)).foregroundColor(c.text).padding(.top, 10)
            VStack(spacing: 12) {
                PickCard(
                    selected: toSelf,
                    leading: { WaxSeal(size: 42, label: sealChar) },
                    title: "Chính mình của tương lai",
                    sub: "Một lời nhắn cho chính bạn",
                    action: { toSelf = true }
                )
                PickCard(
                    selected: !toSelf,
                    leading: {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 22))
                            .foregroundColor(c.muted)
                            .frame(width: 42, height: 42)
                            .background(c.surface2.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    },
                    title: "Một người khác",
                    sub: "Người thân, bạn bè, con cái…",
                    action: { toSelf = false }
                )
            }
            .padding(.top, 22)
            if !toSelf {
                TextField("Tên người nhận", text: $otherName)
                    .textFieldStyle(MaiFieldStyle())
                    .padding(.top, 14)
            }
        }
    }

    var writeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Viết thư").font(.system(size: 26, weight: .semibold)).foregroundColor(c.text).padding(.top, 10)
            TextField("Tiêu đề", text: $title)
                .font(.system(size: 18, weight: .semibold))
                .textFieldStyle(MaiFieldStyle())
                .padding(.top, 20)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $letterBody)
                    .font(.system(size: 15))
                    .foregroundColor(c.text)
                    .frame(minHeight: 240)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(c.surface.opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(c.hair, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .scrollContentBackground(.hidden)
                if letterBody.isEmpty {
                    Text("Gửi tới một ngày nào đó… bạn muốn nói gì?")
                        .font(.system(size: 15))
                        .foregroundColor(c.faint)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 12)
            Text("\(letterBody.count) ký tự")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(c.faint)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
        }
    }

    var attachStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Đính kèm").font(.system(size: 26, weight: .semibold)).foregroundColor(c.text).padding(.top, 10)
            Text("Gói thêm một mảnh ký ức (tuỳ chọn).")
                .font(.maiBody).foregroundColor(c.muted).padding(.top, 8)
            HStack(spacing: 10) {
                ForEach(AttachKind.allCases, id: \.self) { kind in
                    let on = attachTypes.contains(kind)
                    Button { if on { attachTypes.remove(kind) } else { attachTypes.insert(kind) } } label: {
                        HStack(spacing: 7) {
                            Image(systemName: kind.icon).font(.system(size: 14))
                            Text(kind.label).font(.system(size: 15, weight: .semibold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .foregroundColor(on ? c.onAccent : c.muted)
                        .background(on ? c.accent : c.surface.opacity(0.5))
                        .overlay(!on ? RoundedRectangle(cornerRadius: 999).stroke(c.hair, lineWidth: 1) : nil)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.top, 22)
            if !attachTypes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    EyebrowText(text: "sẽ gói cùng thư").padding(.bottom, 2)
                    ForEach(Array(attachTypes), id: \.self) { kind in
                        HStack(spacing: 10) {
                            Image(systemName: "paperclip").foregroundColor(c.accent)
                            Text(kind == .photo ? "ảnh_đính_kèm.jpg" : kind == .file ? "tệp.pdf" : "ghi_âm.m4a")
                                .font(.system(size: 14)).foregroundColor(c.muted)
                        }
                    }
                }
                .padding(16)
                .glassCard(radius: 18)
                .padding(.top, 18)
            }
        }
    }

    var whenStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Khi nào mở?").font(.system(size: 26, weight: .semibold)).foregroundColor(c.text).padding(.top, 10)
            Text("Thư sẽ bị khoá tới đúng ngày này.")
                .font(.maiBody).foregroundColor(c.muted).padding(.top, 8)
            VStack(spacing: 10) {
                WhenOption(id: .year,     label: "Một năm nữa",
                           sub: dateLabel(toISO(Calendar.current.date(byAdding: .day, value: 365, to: now)!)),
                           selected: whenKind == .year) { whenKind = .year }
                WhenOption(id: .birthday, label: "Sinh nhật tới",
                           sub: dateLabel(toISO(nextBirthday(birthISO: store.profile.birthISO, from: now))),
                           selected: whenKind == .birthday) { whenKind = .birthday }
                WhenOption(id: .tet,      label: nextTet(from: now).name,
                           sub: dateLabel(nextTet(from: now).iso),
                           selected: whenKind == .tet) { whenKind = .tet }
                WhenOption(id: .custom,   label: "Chọn ngày…", sub: nil,
                           selected: whenKind == .custom) { whenKind = .custom }
                if whenKind == .custom {
                    DatePicker("", selection: Binding(
                        get: { parseISO(customDate) ?? Date() },
                        set: { customDate = toISO($0) }
                    ), in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(c.accent)
                    .padding(12)
                    .glassCard(radius: 18)
                }
            }
            .padding(.top, 22)
        }
    }

    var reviewStep: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Niêm phong").font(.system(size: 26, weight: .semibold)).foregroundColor(c.text)
                .frame(maxWidth: .infinity, alignment: .center).padding(.top, 10)
            EnvelopeView(width: 230, seal: sealChar)
                .padding(.vertical, 26)
            VStack(spacing: 0) {
                SummaryRow(key: "Tiêu đề", value: title)
                SummaryRow(key: "Người nhận", value: toSelf ? "Chính mình" : otherName)
                SummaryRow(key: "Đính kèm", value: attachTypes.isEmpty ? "Không" : "\(attachTypes.count) mục")
                if let d = parseISO(openISO) {
                    SummaryRow(key: "Ngày mở", value: fmtDate(d), accent: true)
                    SummaryRow(key: "Còn lại", value: "\(diffParts(target: d, from: now).d) ngày", isLast: true)
                }
            }
            .padding(18)
            .glassCard(radius: 20)
        }
    }

    private func dateLabel(_ iso: String) -> String? {
        guard let d = parseISO(iso) else { return nil }
        return "\(fmtDate(d)) · còn \(diffParts(target: d, from: now).d) ngày"
    }

    private func finish() {
        let letter = Letter(
            id: "l-\(Date().timeIntervalSince1970)",
            to: toSelf ? "Gửi chính mình" : "Gửi \(otherName.trimmingCharacters(in: .whitespaces))",
            title: title.trimmingCharacters(in: .whitespaces),
            sealedISO: toISO(now),
            openISO: openISO,
            opened: false,
            openedAtISO: nil,
            seal: sealChar,
            attachments: attachTypes.map { kind in
                LetterAttachment(type: {
                    switch kind {
                    case .photo: return .photo
                    case .voice: return .voice
                    case .file:  return .file
                    }
                }(), name: kind == .photo ? "ảnh_đính_kèm.jpg" : kind == .file ? "tệp.pdf" : "ghi_âm.wav", src: nil)
            },
            body: letterBody.trimmingCharacters(in: .whitespaces)
        )
        onCreate(letter)
        onClose()
    }
}

// MARK: - Helpers

struct PickCard<Leading: View>: View {
    var selected: Bool
    @ViewBuilder var leading: () -> Leading
    var title: String
    var sub: String
    var action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                leading()
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(c.text)
                    Text(sub).font(.system(size: 13)).foregroundColor(c.muted)
                }
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundColor(c.accent).font(.system(size: 14, weight: .semibold)) }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(c.surface.opacity(0.78))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(selected ? c.accent.opacity(0.6) : c.hairSoft, lineWidth: 1))
            )
            .shadow(color: selected ? c.glow.opacity(0.35) : .clear, radius: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct WhenOption: View {
    var id: ComposeView.WhenKind
    var label: String
    var sub: String?
    var selected: Bool
    var action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(c.text)
                    if let sub { Text(sub).font(.system(size: 12.5)).foregroundColor(c.muted) }
                }
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundColor(c.accent).font(.system(size: 14, weight: .semibold)) }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(c.surface.opacity(0.78))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(selected ? c.accent.opacity(0.6) : c.hairSoft, lineWidth: 1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SummaryRow: View {
    var key: String
    var value: String
    var accent = false
    var isLast = false
    @Environment(\.colors) var c

    var body: some View {
        HStack {
            Text(key).font(.system(size: 13.5)).foregroundColor(c.muted)
            Spacer()
            Text(value).font(.system(size: 14.5, weight: .semibold)).foregroundColor(accent ? c.accent : c.text)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) { if !isLast { Divider().background(c.hairSoft) } }
    }
}
