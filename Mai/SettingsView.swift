import SwiftUI

private let accentOptions: [(hex: String, name: String)] = [
    ("#B6A6E9", "Tử đinh hương"),
    ("#8FE0C8", "Bạc hà"),
    ("#F2AEC2", "Hồng phấn"),
    ("#E9CC92", "Hổ phách"),
]

struct SettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(\.colors) var c
    var onClose: () -> Void
    var onReset: () -> Void

    var body: some View {
        ZStack {
            c.bg.ignoresSafeArea()
            if store.appearance.theme == .cosmic { StarField(count: 34) }
            else { StarField(count: 18) }

            VStack(spacing: 0) {
                OverlayHeader(onClose: onClose, title: "Cài đặt")

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Profile
                        EyebrowText(text: "hồ sơ").padding(.top, 6).padding(.bottom, 10)
                        HStack(spacing: 14) {
                            Text(store.profile.name.isEmpty ? "M" : String(store.profile.name.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(c.onAccent)
                                .frame(width: 46, height: 46)
                                .background(c.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            TextField("Tên của bạn", text: Binding(
                                get: { store.profile.name },
                                set: { store.profile.name = $0; store.save() }
                            ))
                            .textFieldStyle(MaiFieldStyle())
                        }
                        .padding(16)
                        .glassCard(radius: 20)

                        // Theme
                        EyebrowText(text: "chủ đề").padding(.top, 26).padding(.bottom, 10)
                        HStack(spacing: 12) {
                            ForEach(ThemeKind.allCases, id: \.self) { th in
                                ThemeCard(
                                    theme: th,
                                    accentHex: store.appearance.accentHex,
                                    selected: store.appearance.theme == th
                                ) {
                                    store.appearance.theme = th
                                    store.save()
                                }
                            }
                        }

                        // Accent
                        EyebrowText(text: "màu chủ đạo").padding(.top, 26).padding(.bottom, 12)
                        HStack(spacing: 14) {
                            ForEach(accentOptions, id: \.hex) { opt in
                                let on = store.appearance.accentHex == opt.hex
                                Button {
                                    store.appearance.accentHex = opt.hex
                                    store.save()
                                } label: {
                                    ZStack {
                                        Circle().fill(Color(hex: opt.hex)!)
                                        if on {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(hex: "#1C1838")!)
                                        }
                                    }
                                    .frame(width: 54, height: 54)
                                    .shadow(color: on ? Color(hex: opt.hex)!.opacity(0.7) : .clear, radius: 8)
                                    .overlay(on ? Circle().stroke(c.bg, lineWidth: 3)
                                                      .overlay(Circle().stroke(Color(hex: opt.hex)!, lineWidth: 2))
                                                : nil)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }

                        // Other
                        EyebrowText(text: "khác").padding(.top, 30).padding(.bottom, 12)
                        Button(action: onReset) {
                            Text("Xem lại phần giới thiệu (onboarding)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "#E8857A")!)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 15)
                                .background(c.surface.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(c.hairSoft, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)
                }
            }
        }
        .preferredColorScheme(store.appearance.theme == .cosmic ? .dark : .light)
    }
}

// MARK: - Theme card

struct ThemeCard: View {
    let theme: ThemeKind
    let accentHex: String
    let selected: Bool
    let action: () -> Void

    private var bgGradient: LinearGradient {
        switch theme {
        case .cosmic: return LinearGradient(colors: [Color(hex: "#1C1838")!, Color(hex: "#241D3E")!], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dawn:   return LinearGradient(colors: [Color(hex: "#F1EAF7")!, Color(hex: "#EFE2EE")!], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    private var label: String {
        switch theme { case .cosmic: "Vũ trụ"; case .dawn: "Bình minh" }
    }
    private var sub: String {
        switch theme { case .cosmic: "Tối · đêm sao"; case .dawn: "Sáng · pastel" }
    }
    private var textColor: Color {
        switch theme { case .cosmic: .white; case .dawn: Color(hex: "#2E2545")! }
    }
    private var subtextColor: Color {
        switch theme { case .cosmic: Color.white.opacity(0.6); case .dawn: Color(hex: "#5C5272")! }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    bgGradient.frame(height: 84)
                    // Stars for cosmic
                    if theme == .cosmic {
                        ForEach([12, 34, 60, 78, 50].indices, id: \.self) { i in
                            Circle().fill(Color.white.opacity(0.7)).frame(width: 3, height: 3)
                                .offset(x: CGFloat([12, 34, 60, 78, 50][i] % 100) - 50,
                                        y: CGFloat(i) * 10 - 30)
                        }
                    }
                    // Accent dot
                    Circle()
                        .fill(Color(hex: accentHex)!)
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .padding(.leading, 14).padding(.bottom, 12)
                }
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundColor(textColor)
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: accentHex)!)
                        }
                    }
                    Text(sub).font(.system(size: 11.5)).foregroundColor(subtextColor)
                }
                .padding(.horizontal, 13).padding(.vertical, 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected ? (Color(hex: accentHex) ?? .accentColor) : Color.white.opacity(0.15), lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? (Color(hex: accentHex) ?? .clear).opacity(0.3) : .clear, radius: 12)
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
