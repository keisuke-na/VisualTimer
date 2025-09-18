import SwiftUI
import AVFoundation

public struct TimerView: View {
    @State private var remainingSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var isDragging: Bool = false
    @State private var audioPlayer: AVAudioPlayer?

    private let maxMinutes: Int = 60

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let circleSize = size * 0.9 // 90% of available space

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // Timer Circle
                    ZStack {
                        // Background circle with white fill
                        Circle()
                            .fill(Color(NSColor.systemGray).opacity(0.05))
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Border circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: circleSize, height: circleSize)

                        // Red countdown arc (filled sector)
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: circleSize - 20, height: circleSize - 20)
                            .mask(
                                GeometryReader { geo in
                                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                    Path { path in
                                        path.move(to: center)
                                        path.addArc(
                                            center: center,
                                            radius: geo.size.width / 2,
                                            startAngle: .degrees(-90),
                                            endAngle: .degrees(-90 + 360 * Double(remainingSeconds) / Double(maxMinutes * 60)),
                                            clockwise: false
                                        )
                                        path.closeSubpath()
                                    }
                                }
                            )
                            .animation(.linear(duration: isRunning ? 1.0 : 0.1), value: remainingSeconds)

                        // Minute marks
                        ForEach(0..<12) { i in
                            Rectangle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: i % 3 == 0 ? 2.5 : 1, height: i % 3 == 0 ? circleSize * 0.06 : circleSize * 0.035)
                                .offset(y: -circleSize/2 + circleSize * 0.04)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }

                        // Minute labels
                        ForEach([12, 3, 6, 9], id: \.self) { hour in
                            Text("\(hour == 12 ? 60 : hour * 5)")
                                .font(.system(size: circleSize * 0.06, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                                .offset(y: hour == 12 ? -circleSize/2 + circleSize * 0.11 : (hour == 6 ? circleSize/2 - circleSize * 0.11 : 0))
                                .offset(x: hour == 3 ? circleSize/2 - circleSize * 0.11 : (hour == 9 ? -circleSize/2 + circleSize * 0.11 : 0))
                        }

                        // Time display
                        VStack(spacing: 2) {
                            Text(timeString())
                                .font(.system(size: circleSize * 0.16, weight: .light, design: .rounded))
                                .foregroundColor(.black.opacity(0.85))
                                .monospacedDigit()

                            if remainingSeconds == 0 && !isRunning && !isDragging {
                                Text("Drag to set")
                                    .font(.system(size: circleSize * 0.04, weight: .regular))
                                    .foregroundColor(.gray)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Stop any running timer when starting to drag
                                if isRunning {
                                    stopTimer()
                                }
                                isDragging = true
                                let center = CGSize(width: circleSize / 2, height: circleSize / 2)
                                let angle = angleFromPoint(
                                    point: value.location,
                                    center: CGPoint(x: center.width, y: center.height)
                                )
                                setTimeFromAngle(angle)
                            }
                            .onEnded { _ in
                                isDragging = false
                                // Start timer if time is set
                                if remainingSeconds > 0 {
                                    startTimer()
                                }
                            }
                    )
                    .onTapGesture {
                        // Single tap to pause/resume
                        if isRunning {
                            stopTimer()
                        } else if remainingSeconds > 0 {
                            startTimer()
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(minWidth: 300, minHeight: 300)
    }

    private func timeString() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func angleFromPoint(point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var angle = atan2(dy, dx) * 180 / .pi
        angle = angle + 90 // Adjust so 0 degrees is at top
        if angle < 0 {
            angle += 360
        }
        return angle
    }

    private func setTimeFromAngle(_ angle: Double) {
        // Convert angle to minutes (0-60)
        // Round to nearest minute and allow full 60 minutes
        let minutes = Int(round(angle / 360.0 * Double(maxMinutes)))

        // Allow 0 to 60 minutes, with minimum 1 minute
        let clampedMinutes = max(1, min(maxMinutes, minutes))
        remainingSeconds = clampedMinutes * 60
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    // Timer finished
                    stopTimer()
                    // Play beep pattern: 3-4-4-4
                    playBeepPattern()
                }
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func playBeepPattern() {
        // Play MP3 alarm sound
        playAlarmSound()
    }

    private func playAlarmSound() {
        guard let soundURL = Bundle.module.url(forResource: "four_alarms", withExtension: "mp3") else {
            print("Could not find four_alarms.mp3")
            NSSound.beep()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
            NSSound.beep()
        }
    }
}