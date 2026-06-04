import SwiftUI

// MARK: - Event model

struct LifeEvent: Identifiable {
    let id = UUID()
    let kind: String   // "birthday" | "tet" | "anniversary"
    let label: String
    let sub: String
    let date: Date
}

func buildEvents(profile: Profile, now: Date) -> [LifeEvent] {
    var ev: [LifeEvent] = []
    // birthday
    let bd = nextBirthday(birthISO: profile.birthISO, from: now)
    ev.append(LifeEvent(kind: "birthday", label: "Sinh nhật",
                        sub: "Bạn tròn \(ageOn(birthISO: profile.birthISO, on: bd)) tuổi",
                        date: bd))
    // tet
    let tet = nextTet(from: now)
    ev.append(LifeEvent(kind: "tet", label: tet.name, sub: "Năm mới âm lịch",
                        date: parseISO(tet.iso) ?? now))
    // setup anniversary
    let setup = parseISO(profile.setupISO) ?? now
    let c = Calendar.current
    var anv = c.date(from: DateComponents(
        year: c.component(.year, from: now),
        month: c.component(.month, from: setup),
        day: c.component(.day, from: setup))) ?? now
    if startOfDay(anv) < startOfDay(now) {
        anv = c.date(byAdding: .year, value: 1, to: anv) ?? anv
    }
    let yrs = c.component(.year, from: anv) - c.component(.year, from: setup)
    ev.append(LifeEvent(kind: "anniversary", label: "Ngày bắt đầu Mai",
                        sub: yrs <= 0 ? "Hôm nay bạn khởi hành" : "Tròn \(yrs) năm cùng Mai",
                        date: anv))
    return ev.sorted { $0.date < $1.date }
}

// MARK: - Today screen

struct TodayView: View {
    @Environment(AppStore.self) var store
    @Environment(\.colors) var c
    var now: Date
    var onOpenLetter: (Letter) -> Void
    var onOpenSettings: () -> Void

    private var events: [LifeEvent] {
        buildEvents(profile: store.profile, now: now)
    }
    private var hero: LifeEvent { events[0] }
    private var others: [LifeEvent] { Array(events.dropFirst()) }

    private var arrived: Letter? {
        store.letters.first { !$0.opened && $0.openDate <= now }
    }
    private var upcoming: Letter? {
        store.letters
            .filter { !$0.opened && $0.openDate > now }
            .sorted { $0.openDate < $1.openDate }
            .first
    }
    private var lived: Int {
        guard let b = parseISO(store.profile.birthISO) else { return 0 }
        return max(0, daysBetween(b, now))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        EyebrowText(text: fmtLong(now))
                        Text("Chào \(store.profile.name),")
                            .font(.maiDisplay)
                            .foregroundColor(c.text)
                    }
                    Spacer()
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(c.muted)
                            .frame(width: 42, height: 42)
                            .background(c.surface.opacity(0.6))
                            .overlay(Circle().stroke(c.hair, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 4)

                (Text("Hôm nay là ngày thứ ")
                    .foregroundColor(c.muted)
                    + Text(lived.formatted())
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(c.text)
                    + Text(" của đời bạn.")
                        .foregroundColor(c.muted))
                    .font(.maiBody)

                // Hero countdown card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        Circle().fill(eventColor(hero.kind)).frame(width: 8, height: 8)
                        EyebrowText(text: "sắp tới · \(hero.label)")
                    }
                    CountdownHero(target: hero.date, now: now, accent: eventColor(hero.kind))
                        .padding(.top, 16)
                    Text("\(hero.sub) · \(fmtDate(hero.date))")
                        .font(.maiBody)
                        .foregroundColor(c.muted)
                        .padding(.top, 12)
                }
                .padding(24)
                .glassCard()
                .padding(.top, 22)

                // Arrived banner
                if let arrived {
                    Button { onOpenLetter(arrived) } label: {
                        HStack(spacing: 16) {
                            LetterTile(state: .arrived)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Một bức thư vừa tới")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(c.text)
                                Text("\"\(arrived.title)\" · chạm để mở")
                                    .font(.system(size: 13.5))
                                    .foregroundColor(c.muted)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(c.accent)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(c.surface.opacity(0.78))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(c.accent.opacity(0.55), lineWidth: 1))
                        )
                        .shadow(color: c.glow, radius: 18, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 14)
                }

                // Other countdowns
                EyebrowText(text: "những cột mốc khác")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 30)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(others) { e in
                        HStack(spacing: 14) {
                            Circle().fill(eventColor(e.kind)).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(e.label)
                                    .font(.system(size: 15.5, weight: .semibold))
                                    .foregroundColor(c.text)
                                Text(fmtDate(e.date))
                                    .font(.system(size: 12.5))
                                    .foregroundColor(c.muted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(diffParts(target: e.date, from: now).d)")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(eventColor(e.kind))
                                    .monospacedDigit()
                                Text("ngày")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(c.faint)
                                    .textCase(.uppercase)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .glassCard(radius: 20)
                    }
                }

                // Upcoming sealed hint
                if let upcoming {
                    HStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(c.faint)
                        (Text("Bức thư ")
                            .foregroundColor(c.muted)
                        + Text("\"\(upcoming.title)\"")
                            .fontWeight(.semibold)
                            .foregroundColor(c.text)
                        + Text(" sẽ mở sau \(diffParts(target: upcoming.openDate, from: now).d) ngày.")
                            .foregroundColor(c.muted))
                        .font(.maiBody)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(c.surface.opacity(0.6))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(c.hair, style: StrokeStyle(lineWidth: 1, dash: [6, 4])))
                    )
                    .padding(.top, 22)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
        }
    }

    private func eventColor(_ kind: String) -> Color {
        evtColor[kind] ?? c.accent
    }
}
