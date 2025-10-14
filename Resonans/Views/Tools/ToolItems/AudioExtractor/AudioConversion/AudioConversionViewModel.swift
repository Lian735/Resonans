//
//  AudioConversionViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 14/10/25.
//

import AVFoundation
import Foundation

final class AudioConversionViewModel: ObservableObject {
    @Published var selectedFormat: AudioFormat = .mp3
    @Published var bitrate: Double = 192
    @Published var audioDuration: Double = 0
    @Published var audioSampleRate: Double = 44_100
    @Published var audioChannelCount: Int = 2
    @Published var audioStatus: AudioStatus = .initiate
    var videoURL: URL = URL(fileURLWithPath: "")
    var exportUrl: String?
    
    var isLoadedAudioMetadata: Bool {
        audioDuration > 0 || audioSampleRate > 0 || audioChannelCount > 0
    }
    
    func getVideoFileSize() -> String {
        let resourceValues = try? videoURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues?.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }
        return "—"
    }
    
    func getEstimateExportFileSize() -> String {
        guard audioDuration.isFinite, audioDuration > 0 else { return "—" }
        let bytes: Double
        switch selectedFormat {
        case .wav:
            let channels = max(Double(audioChannelCount), 1)
            let bitDepth = 16.0
            let bitsPerSecond = max(audioSampleRate, 1) * channels * bitDepth
            bytes = audioDuration * bitsPerSecond / 8
        case .mp3, .m4a:
            let clamped = max(min(bitrate, 320), 64)
            bytes = audioDuration * clamped * 1000 / 8
        }
        guard bytes.isFinite, bytes > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    func getWavBitrateKbps() -> Int {
        let channels = max(Double(audioChannelCount), 1)
        let bitsPerSecond = max(audioSampleRate, 1) * channels * 16
        return max(Int(bitsPerSecond / 1000), 1)
    }
    
    func loadAudioProperties() {
        let sourceURL = videoURL
        Task {
            let asset = AVURLAsset(url: sourceURL)
            let durationSeconds: Double
            if let duration = try? await asset.load(.duration) {
                durationSeconds = duration.seconds
            } else {
                durationSeconds = 0
            }

            var sampleRate: Double = 44_100
            var channels: Int = 2

            if let tracks = try? await asset.loadTracks(withMediaType: .audio),
               let track = tracks.first {
                if let formatDescriptions = try? await track.load(.formatDescriptions),
                   let description = formatDescriptions.first,
                   let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(description) {
                    let asbd = asbdPtr.pointee
                    sampleRate = asbd.mSampleRate
                    channels = Int(asbd.mChannelsPerFrame)
                }
            }

            await MainActor.run { [sampleRate, channels] in
                audioDuration = durationSeconds.isFinite ? max(durationSeconds, 0) : 0
                audioSampleRate = sampleRate
                audioChannelCount = max(channels, 1)
            }
        }
    }
    
    func convertToAudio() {
        let targetBitrate = Int(max(min(bitrate, 320), 64))
        VideoToAudioConverter.convert(
            videoURL: videoURL,
            format: selectedFormat,
            bitrate: targetBitrate,
            progress: { [weak self] value in
                guard let self else { return }
                self.audioStatus = .inprogress(value)
            },
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let url):
                    self.audioStatus = .completed(url)
                case .failure:
                    self.audioStatus = .failed
                }
            }
        )
    }
}

// MARK: - Audio Status
extension AudioConversionViewModel {
    enum AudioStatus: Equatable {
        case initiate
        case inprogress(Double)
        case completed(URL)
        case failed
    }
}
