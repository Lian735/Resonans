import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedFormat: AudioFormat = .m4a
    @State private var isConverting = false
    @State private var message: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color.white)
                    .shadow(radius: 10)
                    .frame(height: 260)
                    .overlay(
                        VStack(spacing: 20) {
                            if let url = videoURL {
                                Text(url.lastPathComponent)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .transition(.opacity)
                            } else {
                                Text("Keine Datei gewählt")
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 20) {
                                Button(action: { showPhotoPicker = true }) {
                                    Label("Galerie", systemImage: "photo")
                                }
                                Button(action: { showFilePicker = true }) {
                                    Label("Dateien", systemImage: "folder")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .animation(.easeInOut, value: videoURL)
                    )

                Picker("Format", selection: $selectedFormat) {
                    ForEach(AudioFormat.allCases, id: \.#self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button(action: convert) {
                    if isConverting {
                        ProgressView()
                    } else {
                        Text("Konvertieren")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(videoURL == nil || isConverting)
                .padding(.horizontal)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)

                if let msg = message {
                    Text(msg)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                videoURL = url
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                videoURL = url
            }
        }
    }

    private func convert() {
        guard let videoURL else { return }
        isConverting = true
        message = nil
        VideoToAudioConverter.convert(videoURL: videoURL, format: selectedFormat) { result in
            DispatchQueue.main.async {
                isConverting = false
                switch result {
                case .success(let url):
                    message = "Gespeichert: \(url.lastPathComponent)"
                case .failure(let error):
                    message = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
