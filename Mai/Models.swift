import Foundation

// MARK: - Date helpers

let viWeekdays = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]

func startOfDay(_ date: Date = Date()) -> Date {
    Calendar.current.startOfDay(for: date)
}

func daysBetween(_ a: Date, _ b: Date) -> Int {
    let comps = Calendar.current.dateComponents([.day], from: startOfDay(a), to: startOfDay(b))
    return comps.day ?? 0
}

func monthsBetween(_ a: Date, _ b: Date) -> Int {
    let comps = Calendar.current.dateComponents([.month], from: startOfDay(a), to: startOfDay(b))
    return max(0, comps.month ?? 0)
}

func fmtDate(_ date: Date) -> String {
    let c = Calendar.current
    return "\(c.component(.day, from: date)) Tháng \(c.component(.month, from: date)), \(c.component(.year, from: date))"
}

func fmtLong(_ date: Date) -> String {
    let c = Calendar.current
    let w = c.component(.weekday, from: date) - 1
    return "\(viWeekdays[w]) · \(c.component(.day, from: date)) Tháng \(c.component(.month, from: date))"
}

func nextBirthday(birthISO: String, from ref: Date = Date()) -> Date {
    guard let birth = parseISO(birthISO) else { return Date() }
    let c = Calendar.current
    let refDay = startOfDay(ref)
    let year = c.component(.year, from: refDay)
    let month = c.component(.month, from: birth)
    let day = c.component(.day, from: birth)
    var next = c.date(from: DateComponents(year: year, month: month, day: day))!
    if startOfDay(next) < refDay {
        next = c.date(from: DateComponents(year: year + 1, month: month, day: day))!
    }
    return next
}

func ageOn(birthISO: String, on date: Date = Date()) -> Int {
    guard let birth = parseISO(birthISO) else { return 0 }
    let c = Calendar.current
    var age = c.component(.year, from: date) - c.component(.year, from: birth)
    let dm = c.component(.month, from: date) - c.component(.month, from: birth)
    let dd = c.component(.day, from: date) - c.component(.day, from: birth)
    if dm < 0 || (dm == 0 && dd < 0) { age -= 1 }
    return max(0, age)
}

struct TetEntry { let iso: String; let name: String }

let TET_DATES: [TetEntry] = [
    TetEntry(iso: "2026-02-17", name: "Tết Bính Ngọ"),
    TetEntry(iso: "2027-02-06", name: "Tết Đinh Mùi"),
    TetEntry(iso: "2028-01-26", name: "Tết Mậu Thân"),
    TetEntry(iso: "2029-02-13", name: "Tết Kỷ Dậu"),
]

func nextTet(from ref: Date = Date()) -> TetEntry {
    let refDay = startOfDay(ref)
    for e in TET_DATES {
        if let d = parseISO(e.iso), startOfDay(d) >= refDay { return e }
    }
    return TET_DATES.last!
}

func parseISO(_ s: String) -> Date? {
    // Try date-only first (YYYY-MM-DD)
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone.current
    if let d = df.date(from: String(s.prefix(10))) { return d }
    return ISO8601DateFormatter().date(from: s)
}

func toISO(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: date)
}

struct DiffParts {
    let d, h, m, s: Int
    let past: Bool
}

func diffParts(target: Date, from now: Date) -> DiffParts {
    let ms = target.timeIntervalSince(now)
    let past = ms <= 0
    let abs = Swift.abs(ms)
    return DiffParts(
        d: Int(abs / 86400),
        h: Int(abs.truncatingRemainder(dividingBy: 86400) / 3600),
        m: Int(abs.truncatingRemainder(dividingBy: 3600) / 60),
        s: Int(abs.truncatingRemainder(dividingBy: 60)),
        past: past
    )
}

func pad2(_ n: Int) -> String { String(format: "%02d", n) }

// MARK: - Data models

struct Profile: Codable {
    var name: String
    var birthISO: String
    var setupISO: String
    var lifespanYears: Int
    var goals: [LifeGoal]
    var onboarded: Bool

    static var seed: Profile {
        Profile(
            name: "",
            birthISO: "1996-08-15",
            setupISO: toISO(startOfDay()),
            lifespanYears: 90,
            goals: [
                LifeGoal(id: "g1", title: "Đi qua 30 quốc gia", age: 35),
                LifeGoal(id: "g2", title: "Viết xong cuốn sách đầu tiên", age: 42),
            ],
            onboarded: false
        )
    }
}

struct LifeGoal: Codable, Identifiable {
    var id: String
    var title: String
    var age: Int
}

struct Letter: Codable, Identifiable {
    var id: String
    var to: String
    var title: String
    var sealedISO: String
    var openISO: String
    var opened: Bool
    var openedAtISO: String?
    var seal: String
    var attachments: [LetterAttachment]
    var body: String

    var sealedDate: Date { parseISO(sealedISO) ?? Date() }
    var openDate: Date { parseISO(openISO) ?? Date() }
    var isArrived: Bool { !opened && openDate <= Date() }
    var isLocked: Bool { !opened && openDate > Date() }
}

struct LetterAttachment: Codable {
    var type: AttachType
    var name: String
    var src: String?

    enum AttachType: String, Codable { case photo, voice, file }
}

// MARK: - Seed letters (relative to today)

func makeSeedLetters() -> [Letter] {
    func plus(_ days: Int) -> String {
        let d = Calendar.current.date(byAdding: .day, value: days, to: startOfDay())!
        return toISO(d)
    }
    return [
        Letter(id: "l-arrived", to: "Gửi chính mình", title: "Lời hứa mùa đông",
               sealedISO: plus(-180), openISO: plus(-3), opened: false, openedAtISO: nil,
               seal: "M",
               attachments: [
                LetterAttachment(type: .photo, name: "biển_tháng_chạp.jpg", src: nil),
                LetterAttachment(type: .voice, name: "lời_nhắn.wav", src: nil),
               ],
               body: "Nếu cậu đang đọc dòng này, nghĩa là sáu tháng đã trôi qua kể từ buổi chiều ngồi ở bến tàu. Mình viết lúc đang sợ, sợ rằng mọi thứ sẽ không ổn. Nhưng mình tin cậu của hôm nay đã đi qua nó rồi.\n\nHãy nhớ uống nước ấm, gọi cho mẹ, và đừng quên mình từng dũng cảm đến nhường nào."
        ),
        Letter(id: "l-year", to: "Gửi mình của năm sau", title: "Một năm nữa thôi",
               sealedISO: plus(0), openISO: plus(365), opened: false, openedAtISO: nil,
               seal: "M", attachments: [],
               body: "Năm nay mình bắt đầu lại từ con số không. Hẹn cậu ở vạch đích — kể mình nghe cậu đã giữ được lời hứa nào nhé."
        ),
        Letter(id: "l-grad", to: "Gửi An", title: "Cho ngày con tốt nghiệp",
               sealedISO: plus(-20), openISO: "2028-06-15T00:00:00Z", opened: false, openedAtISO: nil,
               seal: "A",
               attachments: [LetterAttachment(type: .file, name: "thư_tay.pdf", src: nil)],
               body: "Bố mẹ đã giữ lá thư này từ rất lâu rồi…"
        ),
        Letter(id: "l-opened", to: "Gửi chính mình", title: "Điều mình từng sợ",
               sealedISO: plus(-400), openISO: plus(-76), opened: true, openedAtISO: plus(-76),
               seal: "M",
               attachments: [LetterAttachment(type: .photo, name: "khoảnh_khắc.jpg", src: nil)],
               body: "Hồi đó mình tưởng chuyển nhà sẽ đánh mất tất cả. Hoá ra mình chỉ đang dọn chỗ cho những điều tốt đẹp hơn. Cảm ơn cậu đã không bỏ cuộc."
        ),
    ]
}
