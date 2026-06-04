import SwiftUI

// MARK: - Star field

struct StarField: View {
    var count: Int = 46
    @Environment(\.colors) var c

    // Fixed deterministic stars (no Math.random — seeded by index)
    private struct Star: Identifiable {
        let id: Int
        let x, y, size: Double
        let dur: Double
        let delay: Double
        let minO, maxO: Double
    }

    private var stars: [Star] {
        (0..<count).map { i in
            // deterministic pseudo-random from index
            let f = Double(i)
            let big = (i % 7 == 0)
            return Star(
                id: i,
                x: (sin(f * 2.3) * 0.5 + 0.5) * 100,
                y: (cos(f * 1.7 + 1.1) * 0.5 + 0.5) * 100,
                size: big ? 2.4 + sin(f * 0.4) * 0.7 : 0.9 + sin(f * 0.9) * 0.6,
                dur: 3 + sin(f * 0.5) * 2.5,
                delay: cos(f * 0.8) * 3,
                minO: big ? 0.15 : 0.08 + sin(f * 1.1) * 0.07,
                maxO: big ? 0.9 : 0.45 + sin(f * 0.7) * 0.3
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { s in
                Circle()
                    .fill(c.star)
                    .frame(width: s.size, height: s.size)
                    .position(
                        x: geo.size.width  * s.x / 100,
                        y: geo.size.height * s.y / 100
                    )
                    .modifier(TwinkleModifier(duration: s.dur, delay: s.delay,
                                              minOpacity: s.minO, maxOpacity: s.maxO))
            }
        }
        .allowsHitTesting(false)
    }
}

struct TwinkleModifier: ViewModifier {
    let duration: Double, delay: Double, minOpacity: Double, maxOpacity: Double
    @State private var bright = false

    func body(content: Content) -> some View {
        content
            .opacity(bright ? maxOpacity : minOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
                    bright = true
                }
            }
    }
}

// MARK: - Wax seal

struct WaxSeal: View {
    var size: CGFloat = 64
    var label: String = "M"
    @Environment(\.colors) var c

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w / 2, cy = h / 2
            let R = w * 0.32
            let ring = w * 0.37
            let bumps = 14
            let br = w * 0.066

            // Bumps
            for i in 0..<bumps {
                let angle = Double(i) * .pi * 2 / Double(bumps)
                let bx = cx + ring * cos(angle)
                let by = cy + ring * sin(angle)
                let bumpPath = Path(ellipseIn: CGRect(x: bx - br, y: by - br, width: br*2, height: br*2))
                ctx.fill(bumpPath, with: .color(c.accent))
            }

            // Main circle
            let mainPath = Path(ellipseIn: CGRect(x: cx-R, y: cy-R, width: R*2, height: R*2))
            ctx.fill(mainPath, with: .color(c.accent))

            // Inner pressed rim
            var rimPath = Path()
            rimPath.addEllipse(in: CGRect(x: cx-(R-w*0.045*2), y: cy-(R-w*0.045*2),
                                           width: (R-w*0.045*2)*2, height: (R-w*0.045*2)*2))
            ctx.stroke(rimPath, with: .color(.white.opacity(0.3)), lineWidth: 1.2)
        }
        .overlay(
            Text(String(label.prefix(1)))
                .font(.system(size: size * 0.29, weight: .bold, design: .monospaced))
                .foregroundColor(c.onAccent.opacity(0.75))
        )
        .frame(width: size, height: size)
        .shadow(color: c.glow, radius: 8, y: 4)
    }
}

// MARK: - Paper plane

struct PaperPlane: View {
    var size: CGFloat = 96
    @Environment(\.colors) var c

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // top wing (lit)
            var top = Path(); top.move(to: CGPoint(x: w*0.90, y: h*0.12))
            top.addLine(to: CGPoint(x: w*0.16, y: h*0.41))
            top.addLine(to: CGPoint(x: w*0.47, y: h*0.52))
            ctx.fill(top, with: .color(c.accent.opacity(0.85)))
            // lower wing / underside
            var low = Path(); low.move(to: CGPoint(x: w*0.90, y: h*0.12))
            low.addLine(to: CGPoint(x: w*0.47, y: h*0.52))
            low.addLine(to: CGPoint(x: w*0.43, y: h*0.90))
            ctx.fill(low, with: .color(c.accent.opacity(0.55)))
            // mid wing
            var mid = Path(); mid.move(to: CGPoint(x: w*0.90, y: h*0.12))
            mid.addLine(to: CGPoint(x: w*0.47, y: h*0.52))
            mid.addLine(to: CGPoint(x: w*0.62, y: h*0.56))
            ctx.fill(mid, with: .color(c.accent))
        }
        .frame(width: size, height: size)
        .shadow(color: c.glow, radius: 12, y: 6)
    }
}

// MARK: - Envelope

struct EnvelopeView: View {
    var width: CGFloat = 280
    var open: Bool = false
    var broken: Bool = false
    var seal: String = "M"
    @Environment(\.colors) var c

    var height: CGFloat { width * 0.66 }

    var body: some View {
        ZStack {
            // Body
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [c.surface2.opacity(0.96), c.surface],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(c.hair, lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 12)

            // Inner pocket shadow
            LinearGradient(colors: [.clear, c.bgDeep.opacity(0.55)],
                           startPoint: .top, endPoint: .bottom)
                .clipShape(
                    TrapezoidShape(topInset: height * 0.38)
                )

            // Flap (triangle from top, folds open)
            FlapShape()
                .fill(LinearGradient(colors: [c.surface2, c.surface2.opacity(0.88)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(FlapShape().stroke(c.hair, lineWidth: 1))
                .rotation3DEffect(
                    .degrees(open ? 176 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.5
                )
                .animation(.easeInOut(duration: 1.1), value: open)
                .zIndex(open ? 1 : 5)

            // Wax seal
            WaxSeal(size: width * 0.157, label: seal)
                .offset(y: height * 0.46 - width * 0.078)
                .opacity(broken ? 0 : 1)
                .scaleEffect(broken ? 0.6 : 1)
                .offset(y: broken ? 30 : 0)
                .rotationEffect(broken ? .degrees(-18) : .zero)
                .animation(.easeInOut(duration: 0.8), value: broken)
                .zIndex(6)
        }
        .frame(width: width, height: height)
    }
}

struct FlapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height * 0.58))
        p.closeSubpath()
        return p
    }
}

struct TrapezoidShape: Shape {
    let topInset: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: topInset))
        p.addLine(to: CGPoint(x: rect.width / 2, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: topInset))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

// MARK: - Letter tile

enum LetterState { case arrived, locked, opened }

struct LetterTile: View {
    var state: LetterState = .locked
    var size: CGFloat = 46
    @Environment(\.colors) var c

    var bg: Color {
        switch state {
        case .arrived: return c.accent
        case .locked:  return c.surface2.opacity(0.88)
        case .opened:  return c.surface2.opacity(0.78)
        }
    }
    var fg: Color {
        switch state {
        case .arrived: return c.onAccent
        case .locked:  return c.muted
        case .opened:  return c.faint
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(bg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.hairSoft, lineWidth: 1))
                .shadow(color: state == .arrived ? c.glow : .clear, radius: 8)

            Group {
                if state == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.38, weight: .semibold))
                } else {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: size * 0.38, weight: .semibold))
                }
            }
            .foregroundColor(fg)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Countdown hero

struct CountdownHero: View {
    var target: Date
    var now: Date
    var accent: Color? = nil
    @Environment(\.colors) var c

    var body: some View {
        let dp = diffParts(target: target, from: now)
        let col = accent ?? c.accent
        HStack(alignment: .lastTextBaseline, spacing: 10) {
            Text("\(dp.d)")
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundColor(col)
                .monospacedDigit()
            Text("ngày")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(c.muted)
            Text("\(pad2(dp.h)):\(pad2(dp.m)):\(pad2(dp.s))")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .foregroundColor(c.faint)
                .monospacedDigit()
        }
    }
}

// MARK: - Countdown pill

struct CountdownPill: View {
    var target: Date
    var now: Date
    @Environment(\.colors) var c

    var body: some View {
        Text("còn \(diffParts(target: target, from: now).d) ngày")
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(c.muted)
    }
}

// MARK: - Canvas life grid

struct LifeCanvas: View {
    var lived: Int
    var total: Int
    var cols: Int = 52
    var cell: CGFloat = 4
    var gap: CGFloat = 2
    var marks: [Int: MarkKind] = [:]
    var accent: Color = Color(hex: "#B6A6E9")!
    var theme: ThemeKind = .cosmic
    var onPick: ((Int) -> Void)? = nil

    enum MarkKind { case letter, birthday, tet, goal }

    var step: CGFloat { cell + gap }
    var rows: Int { Int(ceil(Double(total) / Double(cols))) }
    var width: CGFloat  { CGFloat(cols) * step - gap }
    var height: CGFloat { CGFloat(rows) * step - gap }

    func color(for kind: MarkKind) -> Color {
        switch kind {
        case .letter:   return accent
        case .birthday: return Color(hex: "#F0A6BC")!
        case .tet:      return Color(hex: "#ECC98E")!
        case .goal:     return Color(hex: "#8FE0C8")!
        }
    }

    var body: some View {
        Canvas { ctx, sz in
            let futureOpacity: Double = theme == .dawn ? 0.14 : 0.09
            let futureCol = theme == .dawn ? Color(hex: "#46345C")!.opacity(futureOpacity)
                                           : Color.white.opacity(futureOpacity)

            for i in 0..<total {
                let col = i % cols
                let row = i / cols
                let x = CGFloat(col) * step
                let y = CGFloat(row) * step
                let rect = CGRect(x: x, y: y, width: cell, height: cell)
                let path: Path = cell <= 5
                    ? Path(ellipseIn: rect)
                    : Path(roundedRect: rect, cornerRadius: max(1.5, cell * 0.28))

                if i == lived {
                    ctx.fill(path, with: .color(accent))
                    ctx.blendMode = .normal
                    // glow approx — draw twice with opacity
                } else if let mk = marks[i] {
                    ctx.fill(path, with: .color(color(for: mk)))
                } else if i < lived {
                    ctx.fill(path, with: .color(accent.opacity(0.42)))
                } else {
                    ctx.fill(path, with: .color(futureCol))
                }
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { location in
            guard let onPick else { return }
            let col = Int(location.x / step)
            let row = Int(location.y / step)
            let idx = row * cols + col
            if idx >= 0 && idx < total { onPick(idx) }
        }
    }
}

// MARK: - Primary / ghost buttons

struct PrimaryButton: View {
    var label: String
    var icon: String? = nil
    var fullWidth = false
    var action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                if let icon { Image(systemName: icon) }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(c.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, 22)
            .background(c.accent)
            .clipShape(Capsule())
            .shadow(color: c.glow, radius: 14, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GhostButton: View {
    var label: String
    var fullWidth = false
    var action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(c.text)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: 54)
                .padding(.horizontal, 22)
                .background(c.text.opacity(0.08))
                .overlay(Capsule().stroke(c.hair, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Eyebrow / display helpers

struct EyebrowText: View {
    let text: String
    @Environment(\.colors) var c
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(2.2)
            .foregroundColor(c.faint)
    }
}

// MARK: - Stepper button (for lifespan)

struct StepperButton: View {
    let label: String
    let action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(c.text)
                .frame(width: 30, height: 30)
                .background(c.surface2.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(c.hair, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Custom tab bar

enum AppTab { case today, letters, map }

struct MaiTabBar: View {
    @Binding var selected: AppTab
    @Environment(\.colors) var c

    var body: some View {
        HStack(spacing: 0) {
            TabItem(icon: "sun.max.fill", label: "Hôm nay", tab: .today, selected: $selected)
            TabItem(icon: "envelope.fill",  label: "Thư",   tab: .letters, selected: $selected)
            TabItem(icon: "circle.grid.3x3.fill", label: "Bản đồ", tab: .map, selected: $selected)
        }
        .frame(height: 64)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(c.surface.opacity(0.72))
                .overlay(Capsule().stroke(c.hair, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.45), radius: 25, y: 10)
    }
}

struct TabItem: View {
    let icon: String
    let label: String
    let tab: AppTab
    @Binding var selected: AppTab
    @Environment(\.colors) var c

    var active: Bool { selected == tab }

    var body: some View {
        Button { selected = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: active ? .semibold : .regular))
                Text(label).font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundColor(active ? c.accent : c.faint)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overlay back/close header

struct OverlayHeader: View {
    var onBack: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var title: String? = nil
    var step: Int? = nil
    var totalSteps: Int? = nil
    @Environment(\.colors) var c

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                CircleNavButton(systemName: "chevron.left", action: onBack)
            } else {
                Spacer().frame(width: 40)
            }

            VStack(spacing: 6) {
                if let title { Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(c.text) }
                if let step, let totalSteps {
                    HStack(spacing: 5) {
                        ForEach(0..<totalSteps, id: \.self) { i in
                            Capsule()
                                .fill(i <= step ? c.accent : c.hair)

                                .frame(width: i == step ? 18 : 6, height: 6)
                                .animation(.spring(response: 0.3), value: step)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            if let onClose {
                CircleNavButton(systemName: "xmark", action: onClose)
            } else {
                Spacer().frame(width: 40)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 58)
        .padding(.bottom, 8)
    }
}

struct CircleNavButton: View {
    let systemName: String
    let action: () -> Void
    @Environment(\.colors) var c

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(c.text)
                .frame(width: 40, height: 40)
                .background(c.surface.opacity(0.6))
                .overlay(Circle().stroke(c.hair, lineWidth: 1))
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - App canvas gradient

struct AppCanvas: View {
    @Environment(\.colors) var c

    var body: some View {
        ZStack {
            c.bgDeep
            RadialGradient(colors: [c.glow, .clear],
                           center: UnitPoint(x: 0.5, y: -0.1),
                           startRadius: 0, endRadius: 300)
            RadialGradient(colors: [c.accent.opacity(0.22), .clear],
                           center: UnitPoint(x: 0.8, y: 1.1),
                           startRadius: 0, endRadius: 250)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Legend dot

struct LegendItem: View {
    let color: Color
    let label: String
    var glow = false

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: glow ? color : .clear, radius: 3)
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}
