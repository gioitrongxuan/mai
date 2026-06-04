import SwiftUI

struct LettersView: View {
    @Environment(AppStore.self) var store
    @Environment(\.colors) var c
    var now: Date
    var onOpen: (Letter) -> Void
    var onCompose: () -> Void

    private var arrived: [Letter] {
        store.letters.filter { !$0.opened && $0.openDate <= now }
    }
    private var locked: [Letter] {
        store.letters
            .filter { !$0.opened && $0.openDate > now }
            .sorted { $0.openDate < $1.openDate }
    }
    private var opened: [Letter] {
        store.letters
            .filter { $0.opened }
            .sorted { ($0.openedAtISO ?? "") > ($1.openedAtISO ?? "") }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    EyebrowText(text: "hộp thư thời gian").padding(.top, 60)
                    Text("Thư")
                        .font(.maiDisplay)
                        .foregroundColor(c.text)
                        .padding(.top, 10)
                    Text("\(locked.count) bức đang chờ ngày mở. Mỗi bức là một lời hẹn với tương lai.")
                        .font(.maiBody)
                        .foregroundColor(c.muted)
                        .padding(.top, 8)
                        .padding(.bottom, 22)

                    LetterSection(title: "Vừa tới", items: arrived, now: now, onOpen: onOpen, indent: false)
                    LetterSection(title: "Đang niêm phong", items: locked, now: now, onOpen: onOpen, indent: !arrived.isEmpty)
                    LetterSection(title: "Đã mở", items: opened, now: now, onOpen: onOpen, indent: !arrived.isEmpty || !locked.isEmpty)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
            }

            // FAB
            Button(action: onCompose) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(c.onAccent)
                    .frame(width: 60, height: 60)
                    .background(c.accent)
                    .clipShape(Circle())
                    .shadow(color: c.glow, radius: 16, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.trailing, 22)
            .padding(.bottom, 110)
        }
    }
}

// MARK: - Section

struct LetterSection: View {
    let title: String
    let items: [Letter]
    let now: Date
    let onOpen: (Letter) -> Void
    let indent: Bool
    @Environment(\.colors) var c

    var body: some View {
        if items.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    EyebrowText(text: "\(title) · \(items.count)")
                }
                .padding(.top, indent ? 26 : 0)
                .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(items) { letter in
                        LetterRow(letter: letter, now: now, onOpen: onOpen)
                    }
                }
            }
        }
    }
}

// MARK: - Row

struct LetterRow: View {
    let letter: Letter
    let now: Date
    let onOpen: (Letter) -> Void
    @Environment(\.colors) var c

    private var state: LetterState {
        letter.opened ? .opened : letter.isArrived ? .arrived : .locked
    }
    private var statusText: String {
        if letter.isLocked {
            return "Niêm phong · còn \(diffParts(target: letter.openDate, from: now).d) ngày"
        } else if letter.isArrived {
            return "Đã tới — chạm để mở"
        } else {
            return "Đã mở · \(fmtDate(parseISO(letter.openedAtISO ?? letter.openISO) ?? letter.openDate))"
        }
    }
    private var statusColor: Color {
        letter.isArrived ? c.accent : c.faint
    }
    private var isArrived: Bool { letter.isArrived }

    var body: some View {
        Button { onOpen(letter) } label: {
            HStack(spacing: 15) {
                LetterTile(state: state)

                VStack(alignment: .leading, spacing: 2) {
                    Text(letter.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(c.text)
                        .lineLimit(1)
                    Text(letter.to)
                        .font(.system(size: 12.5))
                        .foregroundColor(c.muted)
                    Text(statusText)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(statusColor)
                        .padding(.top, 3)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(c.surface.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isArrived ? c.accent.opacity(0.5) : c.hairSoft, lineWidth: 1)
                    )
            )
            .shadow(color: isArrived ? c.glow.opacity(0.4) : .clear, radius: 12, y: 4)
            .opacity(letter.opened ? 0.72 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
