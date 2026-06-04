import SwiftUI
import AVFoundation

// MARK: - Open letter (the moment)

struct OpenLetterView: View {
    let letter: Letter
    var alreadyOpened: Bool
    var onMarkOpened: (String) -> Void
    var onClose: () -> Void

    @State private var phase: OpenPhase = .sealed
    @Environment(\.colors) var c

    enum OpenPhase { case sealed, breaking, reading }

    var body: some View {
        ZStack {
            c.bgDeep.ignoresSafeArea()
            StarField(count: 48)

            VStack(spacing: 0) {
                OverlayHeader(onClose: onClose, title: phase == .reading ? "" : nil)

                if phase != .reading {
                    Spacer()
                    VStack(spacing: 40) {
                        EnvelopeView(width: 270, open: phase == .breaking, broken: phase == .breaking, seal: letter.seal)
                        VStack(spacing: 8) {
                            if phase == .sealed {
                                EyebrowText(text: letter.to)
                                Text(letter.title)
                                    .font(.maiH2).foregroundColor(c.text)
                                Text("Chạm để mở phong thư")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(c.accent)
                                    .scaleEffect(phase == .sealed ? 1 : 0.95)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: phase)
                            } else {
                                Text("Đang mở…")
                                    .font(.maiBody).foregroundColor(c.accent)
                            }
                        }
                        .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            LetterReadingView(letter: letter)
                            GhostButton(label: "Đóng lại", fullWidth: true, action: onClose)
                                .padding(.top, 36)
                        }
                        .padding(.horizontal, 26)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard phase == .sealed else { return }
            withAnimation { phase = .breaking }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { phase = .reading }
            }
        }
        .onAppear {
            if alreadyOpened { phase = .reading }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .reading && !alreadyOpened {
                onMarkOpened(letter.id)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Locked letter

struct LockedLetterView: View {
    let letter: Letter
    let now: Date
    var onClose: () -> Void

    @State private var live = Date()
    @Environment(\.colors) var c

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            c.bgDeep.ignoresSafeArea()
            StarField(count: 40)

            VStack(spacing: 0) {
                OverlayHeader(onClose: onClose)
                Spacer()

                VStack(spacing: 0) {
                    EnvelopeView(width: 250, seal: letter.seal)
                        .scaleEffect(1 + 0.035 * sin(live.timeIntervalSince1970 * 0.7))
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: live.timeIntervalSince1970)

                    HStack(spacing: 7) {
                        Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(c.faint)
                        EyebrowText(text: "chưa tới ngày mở")
                    }
                    .padding(.top, 36)

                    Text(letter.title).font(.maiH2).foregroundColor(c.text).padding(.top, 12)

                    let dp = diffParts(target: letter.openDate, from: live)
                    Text("\(dp.d)")
                        .font(.system(size: 46, weight: .bold, design: .monospaced))
                        .foregroundColor(c.accent)
                        .monospacedDigit()
                        .padding(.top, 18)
                    HStack(spacing: 4) {
                        Text("ngày ·")
                        Text("\(pad2(dp.h)):\(pad2(dp.m)):\(pad2(dp.s))")
                            .font(.system(size: 15, weight: .regular, design: .monospaced))
                            .monospacedDigit()
                    }
                    .font(.maiBody).foregroundColor(c.muted)

                    (Text("Bức thư này mở vào ")
                        .foregroundColor(c.muted)
                        + Text(fmtDate(letter.openDate))
                            .fontWeight(.semibold).foregroundColor(c.text)
                        + Text(". Hãy để dành sự tò mò cho ngày ấy.")
                            .foregroundColor(c.muted))
                        .font(.maiBody)
                }
                .font(.maiBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .frame(maxWidth: 320)

                Spacer()
                GhostButton(label: "Quay lại", action: onClose)
                    .padding(.bottom, 30)
            }
        }
        .onReceive(timer) { live = $0 }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Letter reading body

struct LetterReadingView: View {
    let letter: Letter
    @Environment(\.colors) var c

    var body: some View {
        VStack(spacing: 0) {
            EyebrowText(text: letter.to).frame(maxWidth: .infinity, alignment: .center)
            Text(letter.title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(c.text)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            Text("Niêm phong \(fmtDate(letter.sealedDate)) · mở \(fmtDate(letter.openDate))")
                .font(.system(size: 12.5))
                .foregroundColor(c.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Divider().background(c.hair).frame(width: 40).padding(.vertical, 22)

            Text(letter.body)
                .font(.system(size: 16.5))
                .lineSpacing(8)
                .foregroundColor(c.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !letter.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    EyebrowText(text: "đính kèm · \(letter.attachments.count)")
                    ForEach(Array(letter.attachments.enumerated()), id: \.offset) { _, a in
                        AttachmentView(attachment: a)
                    }
                }
                .padding(.top, 26)
            }
        }
    }
}

// MARK: - Attachment views

struct AttachmentView: View {
    let attachment: LetterAttachment
    @Environment(\.colors) var c

    var body: some View {
        switch attachment.type {
        case .photo:
            VStack(alignment: .leading, spacing: 7) {
                // Placeholder photo (actual image would load from src)
                RoundedRectangle(cornerRadius: 16)
                    .fill(c.surface2)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 32))
                                .foregroundColor(c.faint)
                            Text(attachment.name)
                                .font(.system(size: 12))
                                .foregroundColor(c.muted)
                        }
                    )
                    .frame(height: 180)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(c.hair, lineWidth: 1))
            }
        case .voice:
            AudioPlayerView(attachment: attachment)
        case .file:
            HStack(spacing: 10) {
                Image(systemName: "paperclip").foregroundColor(c.accent)
                Text(attachment.name).font(.system(size: 14)).foregroundColor(c.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(radius: 14)
        }
    }
}

// MARK: - Audio player

struct AudioPlayerView: View {
    let attachment: LetterAttachment
    @State private var player: AVAudioPlayer?
    @State private var playing = false
    @State private var current: Double = 0
    @State private var duration: Double = 0
    @Environment(\.colors) var c

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // Deterministic waveform bars
    private var bars: [Double] {
        (0..<38).map { i in
            let f = Double(i)
            return 0.25 + 0.75 * abs(sin(f * 0.9) * cos(f * 0.35))
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                if playing {
                    player?.pause(); playing = false
                } else {
                    player?.play(); playing = true
                }
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(c.onAccent)
                    .frame(width: 46, height: 46)
                    .background(c.accent)
                    .clipShape(Circle())
                    .shadow(color: c.glow, radius: 8)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(player == nil)

            VStack(spacing: 6) {
                // Waveform
                HStack(alignment: .bottom, spacing: 2) {
                    let activeBar = duration > 0 ? Int((current / duration) * Double(bars.count)) : 0
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, b in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= activeBar ? c.accent : c.text.opacity(0.22))
                            .frame(maxWidth: .infinity)
                            .frame(height: CGFloat(b) * 30)
                    }
                }
                .frame(height: 30)

                HStack {
                    Text(attachment.name)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(c.muted)
                    Spacer()
                    Text("\(fmtTime(current)) / \(fmtTime(duration))")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(c.faint)
                        .monospacedDigit()
                }
            }
        }
        .padding(14)
        .glassCard(radius: 18)
        .onReceive(timer) { _ in
            guard let p = player else { return }
            current = p.currentTime
            if !p.isPlaying && playing { playing = false; current = 0 }
        }
        .onAppear { setupPlayer() }
        .onDisappear { player?.stop() }
    }

    private func setupPlayer() {
        // For now, show UI without actual file (file would be stored in-app)
        // In a real implementation, audio data would be stored with the letter
        duration = 0
    }

    private func fmtTime(_ t: Double) -> String {
        let s = Int(t)
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}
