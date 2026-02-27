import SwiftUI
import AVFoundation
import Combine

// MARK: - Sound Player Manager
class SoundPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var volume: Float = 1.0
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var currentSoundFileName: String = ""

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    func loadSound(named fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Could not find sound file: \(fileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            currentSoundFileName = fileName
            progress = 0.0
            currentTime = 0.0
            duration = audioPlayer?.duration ?? 0.0
        } catch {
            print("Error loading sound: \(error)")
        }
    }

    func playSound() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }

    func stopSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentSoundFileName = ""
        stopProgressTimer()
        progress = 0.0
        currentTime = 0.0
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioPlayer?.volume = newVolume
    }

    func isPlayingSound(named fileName: String) -> Bool {
        return isPlaying && currentSoundFileName == fileName
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let player = self.audioPlayer else { return }
                let current = player.currentTime
                let total = player.duration
                self.currentTime = current
                self.duration = total
                if total > 0 {
                    self.progress = current / total
                } else {
                    self.progress = 0.0
                }
                if !player.isPlaying && self.isPlaying {
                    self.stopSound()
                }
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    deinit {
        stopProgressTimer()
    }
}

// MARK: - Time Formatter
func formatTime(_ seconds: TimeInterval) -> String {
    guard seconds.isFinite && !seconds.isNaN && seconds >= 0 else { return "0:00" }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var soundPlayer = SoundPlayerManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .bottomTrailing) {
                    // Centered title row (birds + title)
                    HStack(spacing: 10) {
                        Image(systemName: "bird.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                        Text("Uccellini")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Image(systemName: "bird.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                            .scaleEffect(x: -1, y: 1)
                    }
                    .frame(maxWidth: .infinity)

                    // Byline, bottom-aligned and trailing
                    Text("by Foia")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(Color(.systemBackground))

                Divider()

                // ── Volume Control ──
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.1")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Slider(value: Binding(
                        get: { Double(soundPlayer.volume) },
                        set: { soundPlayer.setVolume(Float($0)) }
                    ), in: 0...1, step: 0.01)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                Divider()

                // ── Sound List ──
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(SoundsManager.shared.sounds, id: \.id) { sound in
                            SoundCard(sound: sound, player: soundPlayer)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                // ── Progress Bar + Time (animated bottom strip) ──
                if soundPlayer.isPlaying {
                    VStack(spacing: 6) {
                        Divider()
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(Color.blue)
                                    .frame(
                                        width: max(0, geometry.size.width * CGFloat(soundPlayer.progress)),
                                        height: 5
                                    )
                                    .animation(.linear(duration: 0.1), value: soundPlayer.progress)
                            }
                        }
                        .frame(height: 5)
                        .padding(.horizontal, 20)

                        HStack {
                            Text(formatTime(soundPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                            Spacer()
                            Text(formatTime(soundPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // Hide the default nav bar title area — our custom header replaces it
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
            .animation(.easeInOut(duration: 0.2), value: soundPlayer.isPlaying)
        }
    }
}

// MARK: - Sound Card View
struct SoundCard: View {
    let sound: Sound
    @ObservedObject var player: SoundPlayerManager

    @State private var showFullImage = false

    private var isThisSoundPlaying: Bool {
        player.isPlayingSound(named: sound.fileName)
    }

    var body: some View {
        HStack(spacing: 14) {

            // ── Circular thumbnail with blue ring when active ──
            Image(sound.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isThisSoundPlaying ? Color.blue : Color.clear, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                .contentShape(Circle())
                .onTapGesture { showFullImage = true }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(Text("Show full image"))

            // ── Name ──
            Text(sound.name)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            // ── Play / Stop button ──
            Button(action: {
                if isThisSoundPlaying {
                    player.stopSound()
                } else {
                    player.loadSound(named: sound.fileName)
                    player.playSound()
                }
            }) {
                Image(systemName: isThisSoundPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 36))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showFullImage) {
            ZStack {
                Color.black.ignoresSafeArea()
                Image(sound.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .onTapGesture { showFullImage = false }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: .black.opacity(isThisSoundPlaying ? 0.10 : 0.04),
                    radius: isThisSoundPlaying ? 8 : 4,
                    x: 0, y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isThisSoundPlaying ? Color.blue.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isThisSoundPlaying)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

