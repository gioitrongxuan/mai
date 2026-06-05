import SwiftUI

private enum Unit: String, CaseIterable {
    case day = "day", week = "week", month = "month", year = "year"

    var label: String {
        switch self { case .day: "Ngày"; case .week: "Tuần"; case .month: "Tháng"; case .year: "Năm" }
    }
    var perYear: Int {
        switch self { case .day: 365; case .week: 52; case .month: 12; case .year: 1 }
    }
    var cols: Int {
        switch self { case .day: 118; case .week: 52; case .month: 24; case .year: 10 }
    }
    var cell: CGFloat {
        switch self { case .day: 2; case .week: 4; case .month: 9; case .year: 20 }
    }
    var gap: CGFloat {
        switch self { case .day: 1; case .week: 2; case .month: 4; case .year: 8 }
    }
    func lived(birthISO: String, now: Date) -> Int {
        guard let birth = parseISO(birthISO) else { return 0 }
        switch self {
        case .day:   return max(0, daysBetween(birth, now))
        case .week:  return max(0, daysBetween(birth, now) / 7)
        case .month: return max(0, monthsBetween(birth, now))
        case .year:  return max(0, ageOn(birthISO: birthISO, on: now))
        }
    }
}

struct MapView: View {
    @Environment(AppStore.self) var store
    @Environment(\.colors) var c
    var now: Date
    var accent: Color
    var theme: ThemeKind

    @State private var unit: Unit = .week
    @State private var adding = false
    @State private var newTitle = ""
    @State private var newAge = ""
    @State private var picked: Int? = nil
    @State private var mapScrollWidth: CGFloat = 300

    private var years: Int { store.profile.lifespanYears }
    private var livedCount: Int { unit.lived(birthISO: store.profile.birthISO, now: now) }
    private var canvasHPad: CGFloat {
        let step = unit.cell + unit.gap
        let w = CGFloat(unit.cols) * step - unit.gap
        return max(0, (mapScrollWidth - w) / 2)
    }
    private var total: Int { years * unit.perYear }
    private var pct: Double { total > 0 ? min(100, Double(livedCount) / Double(total) * 100) : 0 }

    private var marks: [Int: LifeCanvas.MarkKind] {
        var m: [Int: LifeCanvas.MarkKind] = [:]
        let goals = store.profile.goals
        for g in goals {
            let idx = unit.lived(birthISO: store.profile.birthISO, now: goalDate(g.age))
            m[idx] = .goal
        }
        for l in store.letters {
            let idx = unit.lived(birthISO: store.profile.birthISO, now: l.openDate)
            m[idx] = .letter
        }
        let bdIdx = unit.lived(birthISO: store.profile.birthISO,
                               now: nextBirthday(birthISO: store.profile.birthISO, from: now))
        m[bdIdx] = .birthday
        if let tetDate = parseISO(nextTet(from: now).iso) {
            let tetIdx = unit.lived(birthISO: store.profile.birthISO, now: tetDate)
            m[tetIdx] = .tet
        }
        return m
    }

    // Pick info
    private var pickInfo: PickInfo? {
        guard let idx = picked else { return nil }
        let date = unitStartDate(idx)
        let age = ageOn(birthISO: store.profile.birthISO, on: date)
        let c = Calendar.current
        let label: String
        switch unit {
        case .year:  label = "Tuổi \(idx) · năm \(c.component(.year, from: date))"
        case .month: label = "Tháng thứ \(idx+1) · \(fmtDate(date))"
        case .week:  label = "Tuần thứ \(idx+1) · quanh \(fmtDate(date))"
        case .day:   label = "\(fmtLong(date)) năm \(c.component(.year, from: date))"
        }
        let rel = idx < livedCount ? "đã qua" : idx == livedCount ? "\(unit.label) hiện tại" : "phía trước"
        var items: [PickItem] = []
        for g in store.profile.goals {
            if unit.lived(birthISO: store.profile.birthISO, now: goalDate(g.age)) == idx {
                items.append(PickItem(kind: "goal", title: g.title, sub: "Mục tiêu · tuổi \(g.age)"))
            }
        }
        for l in store.letters {
            if unit.lived(birthISO: store.profile.birthISO, now: l.openDate) == idx {
                let status = l.opened ? "Thư đã mở" : "Thư sẽ mở"
                items.append(PickItem(kind: "letter", title: l.title, sub: "\(status) · \(fmtDate(l.openDate))"))
            }
        }
        let bdIdx = unit.lived(birthISO: store.profile.birthISO,
                               now: nextBirthday(birthISO: store.profile.birthISO, from: now))
        if bdIdx == idx { items.append(PickItem(kind: "birthday", title: "Sinh nhật", sub: "Bạn thêm một tuổi")) }
        if let tetDate = parseISO(nextTet(from: now).iso),
           unit.lived(birthISO: store.profile.birthISO, now: tetDate) == idx {
            items.append(PickItem(kind: "tet", title: nextTet(from: now).name, sub: "Năm mới âm lịch"))
        }
        return PickInfo(label: label, age: age, rel: rel, items: items)
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    EyebrowText(text: "bản đồ cuộc đời · 1 chấm = 1 \(unit.label.lowercased())")
                        .padding(.top, 60)
                    Text("Đời người\ntheo từng \(unit.label.lowercased())")
                        .font(.maiDisplay)
                        .foregroundColor(c.text)
                        .padding(.top, 10)

                    // Unit segmented control
                    HStack(spacing: 5) {
                        ForEach(Unit.allCases, id: \.self) { u in
                            Button { unit = u } label: {
                                Text(u.label)
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .foregroundColor(unit == u ? c.onAccent : c.muted)
                                    .background(unit == u ? c.accent : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(5)
                    .background(c.surface.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(c.hairSoft, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 18)

                    // Stat card
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(livedCount.formatted())
                                .font(.system(size: 25, weight: .bold, design: .monospaced))
                                .foregroundColor(c.accent)
                                .monospacedDigit()
                            EyebrowText(text: "\(unit.label.lowercased()) đã sống · \(String(format: "%.1f", pct))%")
                        }
                        Divider().background(c.hair)
                        VStack(spacing: 6) {
                            EyebrowText(text: "giới hạn · năm")
                            HStack(spacing: 10) {
                                StepperButton(label: "−") {
                                    store.profile.lifespanYears = max(50, years - 1); store.save()
                                }
                                Text("\(years)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(c.text)
                                    .frame(minWidth: 30)
                                StepperButton(label: "+") {
                                    store.profile.lifespanYears = min(110, years + 1); store.save()
                                }
                            }
                            EyebrowText(text: "tuổi thọ kỳ vọng").font(.system(size: 9.5, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .glassCard(radius: 20)
                    .padding(.top, 14)

                    // Canvas grid
                    ScrollView(.horizontal, showsIndicators: false) {
                        LifeCanvas(
                            lived: livedCount, total: total,
                            cols: unit.cols, cell: unit.cell, gap: unit.gap,
                            marks: marks, accent: accent, theme: theme,
                            onPick: { picked = $0 }
                        )
                        .padding(.vertical, 2)
                        .padding(.horizontal, canvasHPad)
                    }
                    .padding(.top, 22)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: MapScrollWidthKey.self, value: geo.size.width)
                        }
                    )
                    .onPreferenceChange(MapScrollWidthKey.self) { mapScrollWidth = $0 }

                    Text("chạm vào một chấm để xem mốc thời gian")
                        .font(.system(size: 11.5))
                        .foregroundColor(c.faint.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)

                    // Legend
                    HStack(spacing: 0) {
                        Spacer()
                        FlowLayout(spacing: 14) {
                            LegendItem(color: accent, label: "\(unit.label.lowercased()) này")
                            LegendItem(color: accent.opacity(0.42), label: "Đã sống")
                            LegendItem(color: Color(hex: "#8FE0C8")!, label: "Mục tiêu", glow: true)
                            LegendItem(color: Color(hex: "#F0A6BC")!, label: "Sinh nhật", glow: true)
                            LegendItem(color: Color(hex: "#ECC98E")!, label: "Tết", glow: true)
                            LegendItem(color: accent, label: "Thư sẽ mở", glow: true)
                        }
                        Spacer()
                    }
                    .padding(.top, 22)

                    // Goals header
                    HStack {
                        EyebrowText(text: "mục tiêu cuộc đời")
                        Spacer()
                        Button {
                            withAnimation { adding.toggle() }
                        } label: {
                            Text(adding ? "Đóng" : "+ Thêm")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(c.accent)
                        }
                    }
                    .padding(.top, 34)
                    .padding(.bottom, 12)

                    // Add goal form
                    if adding {
                        VStack(spacing: 10) {
                            TextField("Mục tiêu (vd: Đi 30 quốc gia)", text: $newTitle)
                                .textFieldStyle(MaiFieldStyle())
                            HStack(spacing: 10) {
                                TextField("Tuổi đạt được", text: $newAge)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(MaiFieldStyle())
                                Button("Lưu") { addGoal() }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(c.onAccent)
                                    .padding(.horizontal, 24)
                                    .frame(height: 50)
                                    .background(c.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(16)
                        .glassCard(radius: 20)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Goals list
                    let sortedGoals = store.profile.goals.sorted { $0.age < $1.age }
                    if sortedGoals.isEmpty && !adding {
                        Text("Chưa có mục tiêu nào. Đặt một cột mốc cho chặng đường phía trước.")
                            .font(.system(size: 13.5))
                            .foregroundColor(c.muted)
                            .padding(.vertical, 6)
                    }
                    VStack(spacing: 10) {
                        ForEach(sortedGoals) { g in
                            GoalRow(goal: g, birthISO: store.profile.birthISO, now: now, onRemove: { removeGoal(g.id) })
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
            }

            // Pick sheet overlay
            if let info = pickInfo {
                Color.black.opacity(0.0)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { picked = nil }

                VStack {
                    Spacer()
                    PickSheet(info: info, accent: accent, onClose: { picked = nil })
                        .padding(.horizontal, 10)
                        .padding(.bottom, 100)
                }
                .background(Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { picked = nil })
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: picked)
            }
        }
    }

    private func goalDate(_ age: Int) -> Date {
        guard let birth = parseISO(store.profile.birthISO) else { return Date() }
        return Calendar.current.date(byAdding: .year, value: age, to: birth) ?? Date()
    }

    private func unitStartDate(_ idx: Int) -> Date {
        guard let birth = parseISO(store.profile.birthISO) else { return Date() }
        let c = Calendar.current
        switch unit {
        case .year:  return c.date(byAdding: .year,  value: idx, to: birth) ?? birth
        case .month: return c.date(byAdding: .month, value: idx, to: birth) ?? birth
        case .week:  return c.date(byAdding: .day,   value: idx * 7, to: birth) ?? birth
        case .day:   return c.date(byAdding: .day,   value: idx, to: birth) ?? birth
        }
    }

    private func addGoal() {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              let age = Int(newAge), age > 0 else { return }
        let g = LifeGoal(id: "g\(Date().timeIntervalSince1970)", title: newTitle.trimmingCharacters(in: .whitespaces), age: age)
        store.profile.goals.append(g)
        store.save()
        newTitle = ""; newAge = ""; adding = false
    }

    private func removeGoal(_ id: String) {
        store.profile.goals.removeAll { $0.id == id }
        store.save()
    }
}

private struct MapScrollWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Goal row

struct GoalRow: View {
    let goal: LifeGoal
    let birthISO: String
    let now: Date
    let onRemove: () -> Void
    @Environment(\.colors) var c

    private var goalDate: Date {
        guard let birth = parseISO(birthISO) else { return Date() }
        return Calendar.current.date(byAdding: .year, value: goal.age, to: birth) ?? Date()
    }

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#8FE0C8")!)
                .shadow(color: Color(hex: "#8FE0C8")!.opacity(0.6), radius: 4)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(goal.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(c.text)
                Text("Tuổi \(goal.age)")
                    .font(.system(size: 12.5))
                    .foregroundColor(c.muted)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(c.faint)
                    .padding(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(radius: 18)
    }
}

// MARK: - Pick info

struct PickItem { let kind: String; let title: String; let sub: String }
struct PickInfo { let label: String; let age: Int; let rel: String; let items: [PickItem] }

struct PickSheet: View {
    let info: PickInfo
    let accent: Color
    let onClose: () -> Void
    @Environment(\.colors) var c

    private var markColors: [String: Color] {[
        "goal":     Color(hex: "#8FE0C8")!,
        "letter":   accent,
        "birthday": Color(hex: "#F0A6BC")!,
        "tet":      Color(hex: "#ECC98E")!,
    ]}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(c.hair).frame(width: 40, height: 4).frame(maxWidth: .infinity).padding(.bottom, 16)
            EyebrowText(text: info.rel)
            Text(info.label).font(.maiH2).foregroundColor(c.text).padding(.top, 6)
            Text(info.age < 0 ? "Khi đó bạn chưa ra đời." : "Khi đó bạn \(info.age) tuổi.")
                .font(.system(size: 13)).foregroundColor(c.muted).padding(.top, 4)

            if info.items.isEmpty {
                Text("Chưa có cột mốc nào ở thời điểm này.")
                    .font(.system(size: 13))
                    .foregroundColor(c.muted.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 9) {
                    ForEach(Array(info.items.enumerated()), id: \.offset) { _, it in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(markColors[it.kind] ?? accent)
                                .shadow(color: (markColors[it.kind] ?? accent).opacity(0.6), radius: 4)
                                .frame(width: 9, height: 9)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(it.title).font(.system(size: 14.5, weight: .semibold)).foregroundColor(c.text)
                                Text(it.sub).font(.system(size: 12)).foregroundColor(c.muted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background(c.surface2.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 16)
            }

            GhostButton(label: "Đóng", fullWidth: true, action: onClose)
                .padding(.top, 18)
                .frame(height: 46)
        }
        .padding(22)
        .glassCard(radius: 28)
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
    }
}

// MARK: - Flow layout helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var curX: CGFloat = 0, curY: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if curX + sz.width > maxW && curX > 0 { curX = 0; curY += rowH + spacing; rowH = 0 }
            rowH = max(rowH, sz.height); curX += sz.width + spacing
        }
        return CGSize(width: maxW, height: curY + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var curX = bounds.minX, curY = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if curX + sz.width > bounds.maxX && curX > bounds.minX { curX = bounds.minX; curY += rowH + spacing; rowH = 0 }
            sv.place(at: CGPoint(x: curX, y: curY), proposal: .unspecified)
            rowH = max(rowH, sz.height); curX += sz.width + spacing
        }
    }
}
