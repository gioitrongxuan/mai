import SwiftUI

// MARK: - Colors

struct MaiColors {
    var bg:        Color
    var bgDeep:    Color
    var surface:   Color
    var surface2:  Color
    var text:      Color
    var muted:     Color
    var faint:     Color
    var accent:    Color
    var onAccent:  Color
    var star:      Color
    var hair:      Color
    var hairSoft:  Color
    var glow:      Color

    static func make(theme: ThemeKind, accentHex: String) -> MaiColors {
        let accent = Color(hex: accentHex) ?? Color(hex: "#B6A6E9")!
        switch theme {
        case .cosmic:
            return MaiColors(
                bg:       Color(hex: "#1C1730")!,
                bgDeep:   Color(hex: "#13112A")!,
                surface:  Color(hex: "#242040")!,
                surface2: Color(hex: "#2C2848")!,
                text:     Color(hex: "#F4F3FF")!,
                muted:    Color(hex: "#B8B5CC")!,
                faint:    Color(hex: "#807C9A")!,
                accent:   accent,
                onAccent: Color(hex: "#1C1838")!,
                star:     Color(hex: "#F4F3FF")!,
                hair:     .white.opacity(0.13),
                hairSoft: .white.opacity(0.07),
                glow:     accent.opacity(0.55)
            )
        case .dawn:
            return MaiColors(
                bg:       Color(hex: "#F8F0FB")!,
                bgDeep:   Color(hex: "#EFE5F5")!,
                surface:  Color(hex: "#FEFCFF")!,
                surface2: Color(hex: "#F0E6F5")!,
                text:     Color(hex: "#2E2545")!,
                muted:    Color(hex: "#5C5272")!,
                faint:    Color(hex: "#918AA8")!,
                accent:   accent,
                onAccent: Color(hex: "#1C1838")!,
                star:     Color(hex: "#7A68A0")!,
                hair:     Color(hex: "#2E2545")!.opacity(0.13),
                hairSoft: Color(hex: "#2E2545")!.opacity(0.06),
                glow:     accent.opacity(0.40)
            )
        }
    }
}

// MARK: - Special event colors

let evtColor: [String: Color] = [
    "birthday":    Color(hex: "#F0A6BC")!,
    "tet":         Color(hex: "#ECC98E")!,
    "anniversary": Color(hex: "#8FC8C4")!,
]

// MARK: - Environment key

struct MaiColorsKey: EnvironmentKey {
    static let defaultValue = MaiColors.make(theme: .cosmic, accentHex: "#B6A6E9")
}
extension EnvironmentValues {
    var colors: MaiColors {
        get { self[MaiColorsKey.self] }
        set { self[MaiColorsKey.self] = newValue }
    }
}

// MARK: - Color hex init

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8)  & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}

// MARK: - Glass card modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    @Environment(\.colors) var c

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(c.surface.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(c.hairSoft, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(radius: CGFloat = 24) -> some View {
        modifier(GlassCard(cornerRadius: radius))
    }
}

// MARK: - Typography helpers

extension Font {
    static var maiDisplay: Font  { .system(size: 30, weight: .semibold, design: .default) }
    static var maiH2: Font       { .system(size: 21, weight: .semibold) }
    static var maiBody: Font     { .system(size: 15, weight: .regular) }
    static var maiEyebrow: Font  { .system(size: 12, weight: .semibold) }
    static var maiMono: Font     { .system(size: 15, weight: .regular, design: .monospaced) }
}
