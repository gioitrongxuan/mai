import SwiftUI

struct OnboardingView: View {
    var onDone: (String, String) -> Void  // (name, birthISO)

    @State private var step = 0
    @State private var name = ""
    @State private var birthDay   = 15
    @State private var birthMonth = 8
    @State private var birthYear  = 1996
    @Environment(\.colors) var c

    private var birthISO: String {
        let comps = DateComponents(year: birthYear, month: birthMonth, day: birthDay)
        let d = Calendar.current.date(from: comps) ?? Date()
        return toISO(d)
    }

    private var daysLived: Int {
        guard let birth = parseISO(birthISO) else { return 0 }
        return max(0, daysBetween(birth, Date()))
    }

    var body: some View {
        ZStack {
            AppCanvas()
            StarField(count: 46)

            VStack {
                Spacer()
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: nameStep
                    case 2: birthStep
                    default: summaryStep
                    }
                }
                .padding(.horizontal, 26)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Step 0 — welcome
    var welcomeStep: some View {
        VStack(spacing: 0) {
            PaperPlane(size: 96)
                .padding(.bottom, 30)
            Text("Mai")
                .font(.system(size: 52, weight: .semibold))
                .foregroundColor(c.text)
            Text("Thư gửi mai sau.\nViết hôm nay, mở vào một ngày đã hẹn.")
                .font(.system(size: 16))
                .foregroundColor(c.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
            PrimaryButton(label: "Bắt đầu", fullWidth: true) { withAnimation { step = 1 } }
                .padding(.top, 40)
            EyebrowText(text: "thời gian là món quà")
                .padding(.top, 22)
                .opacity(0.7)
        }
    }

    // MARK: Step 1 — name
    var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "bước 1 / 2")
            Text("Mình gọi bạn\nlà gì?")
                .font(.maiDisplay)
                .foregroundColor(c.text)
                .padding(.top, 14)
            TextField("Tên của bạn", text: $name)
                .textFieldStyle(MaiFieldStyle())
                .font(.system(size: 20))
                .padding(.top, 26)
                .submitLabel(.continue)
                .onSubmit { withAnimation { step = 2 } }
            PrimaryButton(label: "Tiếp tục", icon: "arrow.right", fullWidth: true) {
                withAnimation { step = 2 }
            }
            .padding(.top, 24)
        }
    }

    // MARK: Step 2 — birthdate
    var birthStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "bước 2 / 2")
            Text("Bạn bắt đầu\nhành trình ngày nào?")
                .font(.maiDisplay)
                .foregroundColor(c.text)
                .padding(.top, 14)
            Text("Ngày sinh giúp Mai vẽ bản đồ thời gian và đếm ngược sinh nhật.")
                .font(.maiBody)
                .foregroundColor(c.muted)
                .padding(.top, 10)

            HStack(spacing: 10) {
                WheelPicker(value: $birthDay, options: Array(1...31), label: { "\($0)" })
                WheelPicker(value: $birthMonth, options: Array(1...12), label: { "Th\($0)" })
                WheelPicker(value: $birthYear, options: Array(stride(from: 2025, through: 1940, by: -1)), label: { "\($0)" })
            }
            .padding(.top, 24)

            PrimaryButton(label: "Tiếp tục", icon: "arrow.right", fullWidth: true) {
                withAnimation { step = 3 }
            }
            .padding(.top, 28)
        }
    }

    // MARK: Step 3 — summary
    var summaryStep: some View {
        VStack(spacing: 0) {
            EyebrowText(text: "tính tới hôm nay")
            Text(daysLived.formatted())
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundColor(c.accent)
                .monospacedDigit()
                .padding(.top, 18)
            Text("ngày bạn đã sống")
                .font(.maiH2)
                .foregroundColor(c.text)
                .padding(.top, 4)
            Text("Mỗi ngày là một chấm sáng. Hãy gửi vài lời cho những chấm còn ở phía trước.")
                .font(.maiBody)
                .foregroundColor(c.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .frame(maxWidth: 280)
            PrimaryButton(label: "Vào Mai", fullWidth: true) {
                onDone(name.isEmpty ? "bạn" : name, birthISO)
            }
            .padding(.top, 38)
        }
    }
}

// MARK: - Wheel picker

struct WheelPicker<T: Hashable>: View {
    @Binding var value: T
    let options: [T]
    let label: (T) -> String
    @Environment(\.colors) var c

    var body: some View {
        Picker("", selection: $value) {
            ForEach(options, id: \.self) { opt in
                Text(label(opt)).tag(opt)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .background(c.surface.opacity(0.6))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(c.hair, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(height: 120)
    }
}

// MARK: - Field style

struct MaiFieldStyle: TextFieldStyle {
    @Environment(\.colors) var c

    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(c.surface.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(c.hair, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .foregroundColor(c.text)
    }
}
