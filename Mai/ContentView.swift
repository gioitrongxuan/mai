import SwiftUI

enum OverlayKind: Identifiable {
    case compose
    case openLetter(Letter, Bool)
    case lockedLetter(Letter)
    case settings

    var id: String {
        switch self {
        case .compose:              return "compose"
        case .openLetter(let l, _): return "open-\(l.id)"
        case .lockedLetter(let l):  return "locked-\(l.id)"
        case .settings:             return "settings"
        }
    }
}

struct ContentView: View {
    @State private var store = AppStore()
    @State private var tab: AppTab = .today
    @State private var overlay: OverlayKind? = nil
    @State private var now = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var colors: MaiColors {
        MaiColors.make(theme: store.appearance.theme, accentHex: store.appearance.accentHex)
    }

    var body: some View {
        ZStack {
            AppCanvas()
            StarField(count: store.appearance.theme == .cosmic ? 46 : 22)

            if !store.profile.onboarded {
                OnboardingView { name, birthISO in
                    store.profile.name = name
                    store.profile.birthISO = birthISO
                    store.profile.onboarded = true
                    store.save()
                }
            } else {
                mainContent
            }

            if let ov = overlay {
                overlayView(for: ov)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .environment(store)
        .environment(\.colors, colors)
        .preferredColorScheme(store.appearance.theme == .cosmic ? .dark : .light)
        .onReceive(timer) { now = $0 }
        .animation(.spring(response: 0.35), value: overlay?.id)
    }

    // MARK: - Main

    var mainContent: some View {
        ZStack(alignment: .bottom) {
            switch tab {
            case .today:
                TodayView(now: now,
                          onOpenLetter: { handleOpenLetter($0) },
                          onOpenSettings: { overlay = .settings })
            case .letters:
                LettersView(now: now,
                            onOpen: { handleOpenLetter($0) },
                            onCompose: { overlay = .compose })
            case .map:
                MapView(now: now,
                        accent: colors.accent,
                        theme: store.appearance.theme)
            }

            MaiTabBar(selected: $tab)
                .padding(.horizontal, 14)
                .padding(.bottom, 30)
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    func overlayView(for ov: OverlayKind) -> some View {
        switch ov {
        case .compose:
            ComposeView(onClose: { overlay = nil }, onCreate: { store.createLetter($0) })
        case .openLetter(let letter, let already):
            OpenLetterView(letter: letter, alreadyOpened: already,
                           onMarkOpened: { store.markOpened($0) },
                           onClose: { overlay = nil })
        case .lockedLetter(let letter):
            LockedLetterView(letter: letter, now: now, onClose: { overlay = nil })
        case .settings:
            SettingsView(onClose: { overlay = nil }, onReset: {
                store.resetAll(); overlay = nil
            })
        }
    }

    func handleOpenLetter(_ letter: Letter) {
        if letter.opened        { overlay = .openLetter(letter, true)  }
        else if letter.isArrived { overlay = .openLetter(letter, false) }
        else                     { overlay = .lockedLetter(letter)      }
    }
}

#Preview {
    ContentView()
}
