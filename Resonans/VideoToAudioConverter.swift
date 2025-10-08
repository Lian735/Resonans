import AVFoundation
import Foundation
import LAME

enum AudioFormat: String, CaseIterable {
    case m4a = "M4A"
    case wav = "WAV"
    case mp3 = "MP3"

    var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        case .mp3: return "mp3"
        }
    }
}

final class VideoToAudioConverter {
    private final class MediaExportContext: @unchecked Sendable {
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        let writer: AVAssetWriter
        let writerInput: AVAssetWriterInput
        let outputURL: URL
        let durationSeconds: Double
        private let progressHandler: @Sendable (Double) -> Void
        private let completionHandler: @Sendable (Result<URL, Error>) -> Void

        init(
            reader: AVAssetReader,
            readerOutput: AVAssetReaderTrackOutput,
            writer: AVAssetWriter,
            writerInput: AVAssetWriterInput,
            outputURL: URL,
            durationSeconds: Double,
            progress: @escaping (Double) -> Void,
            completion: @escaping (Result<URL, Error>) -> Void
        ) {
            self.reader = reader
            self.readerOutput = readerOutput
            self.writer = writer
            self.writerInput = writerInput
            self.outputURL = outputURL
            self.durationSeconds = durationSeconds
            self.progressHandler = { value in
                DispatchQueue.main.async {
                    progress(min(max(value, 0), 1))
                }
            }
            self.completionHandler = { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }

        func reportProgress(_ value: Double) {
            progressHandler(value)
        }

        func finish(with result: Result<URL, Error>) {
            completionHandler(result)
        }
    }

    private static func runExportLoop(
        context: MediaExportContext,
        queueLabel: String,
        appendFailureCode: Int,
        readerFailureCode: Int
    ) {
        let queue = DispatchQueue(label: queueLabel)
        context.writerInput.requestMediaDataWhenReady(on: queue) { [context] in
            while context.writerInput.isReadyForMoreMediaData {
                if context.reader.status == .reading,
                   let sampleBuffer = context.readerOutput.copyNextSampleBuffer() {
                    if !context.writerInput.append(sampleBuffer) {
                        context.reader.cancelReading()
                        context.writerInput.markAsFinished()
                        context.writer.cancelWriting()
                        let error = context.writer.error ?? NSError(domain: "export", code: appendFailureCode)
                        context.finish(with: .failure(error))
                        return
                    }

                    if context.durationSeconds > 0 {
                        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                        context.reportProgress(time / context.durationSeconds)
                    }
                } else {
                    context.writerInput.markAsFinished()
                    switch context.reader.status {
                    case .completed:
                        context.writer.finishWriting {
                            if let error = context.writer.error {
                                context.finish(with: .failure(error))
                            } else {
                                context.reportProgress(1)
                                context.finish(with: .success(context.outputURL))
                            }
                        }
                    case .failed, .cancelled:
                        let error = context.reader.error ?? context.writer.error ?? NSError(domain: "export", code: readerFailureCode)
                        context.writer.cancelWriting()
                        context.finish(with: .failure(error))
                    default:
                        break
                    }
                    return
                }
            }
        }
    }

    static func convert(
        videoURL: URL,
        format: AudioFormat,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let baseName = videoURL.deletingPathExtension().lastPathComponent + "_out"
        let tmp = FileManager.default.temporaryDirectory
        progress(0)
        switch format {
        case .m4a:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension(format.fileExtension)
            exportToM4A(videoURL: videoURL, outputURL: out, bitrate: bitrate, progress: progress, completion: completion)
        case .wav:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension(format.fileExtension)
            exportToWAV(videoURL: videoURL, outputURL: out, progress: progress, completion: completion)
        case .mp3:
            let wavURL = tmp.appendingPathComponent(baseName).appendingPathExtension(AudioFormat.wav.fileExtension)
            exportToWAV(videoURL: videoURL, outputURL: wavURL, progress: { value in
                progress(value * 0.85)
            }) { result in
                switch result {
                case .failure(let err):
                    DispatchQueue.main.async {
                        completion(.failure(err))
                    }
                case .success:
                    do {
                        let mp3URL = tmp.appendingPathComponent(baseName).appendingPathExtension(format.fileExtension)
                        try wavToMp3(wavURL: wavURL, mp3URL: mp3URL, bitrate: bitrate) { encodeProgress in
                            let mapped = 0.85 + (encodeProgress * 0.15)
                            progress(min(max(mapped, 0), 1))
                        }
                        DispatchQueue.main.async {
                            progress(1)
                        }
                        DispatchQueue.main.async {
                            completion(.success(mp3URL))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }

    private static func exportToM4A(
        videoURL: URL,
        outputURL: URL,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        Task {
            func fail(_ error: Error) {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

            do {
                try removeFileIfNeeded(at: outputURL)

                let asset = AVURLAsset(url: videoURL)
                let track = try await fetchAudioTrack(from: asset, failureCode: -3)
                let characteristics = try await audioCharacteristics(for: track)
                let readerSettings = pcmSettings(sampleRate: characteristics.sampleRate, channels: characteristics.channels)
                let writerSettings = aacSettings(
                    sampleRate: characteristics.sampleRate,
                    channels: characteristics.channels,
                    bitrate: bitrate
                )

                let (reader, readerOutput) = try makeReader(
                    for: asset,
                    track: track,
                    settings: readerSettings,
                    failureCode: -10
                )
                let (writer, writerInput) = try makeWriter(
                    outputURL: outputURL,
                    fileType: .m4a,
                    settings: writerSettings,
                    failureCode: -11
                )
                let context = try await startSession(
                    asset: asset,
                    reader: reader,
                    readerOutput: readerOutput,
                    writer: writer,
                    writerInput: writerInput,
                    outputURL: outputURL,
                    startFailureCode: -12,
                    progress: progress,
                    completion: completion
                )

                runExportLoop(
                    context: context,
                    queueLabel: "m4a.export.queue",
                    appendFailureCode: -13,
                    readerFailureCode: -14
                )
            } catch {
                fail(error)
            }
        }
    }

    private static func exportToWAV(
        videoURL: URL,
        outputURL: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        Task {
            func fail(_ error: Error) {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

            do {
                try removeFileIfNeeded(at: outputURL)

                let asset = AVURLAsset(url: videoURL)
                let track = try await fetchAudioTrack(from: asset, failureCode: -4)
                let characteristics = try await audioCharacteristics(for: track)
                let pcmSettings = pcmSettings(sampleRate: characteristics.sampleRate, channels: characteristics.channels)

                let (reader, readerOutput) = try makeReader(
                    for: asset,
                    track: track,
                    settings: pcmSettings,
                    failureCode: -5
                )
                let (writer, writerInput) = try makeWriter(
                    outputURL: outputURL,
                    fileType: .wav,
                    settings: pcmSettings,
                    failureCode: -6
                )
                let context = try await startSession(
                    asset: asset,
                    reader: reader,
                    readerOutput: readerOutput,
                    writer: writer,
                    writerInput: writerInput,
                    outputURL: outputURL,
                    startFailureCode: -7,
                    progress: progress,
                    completion: completion
                )

                runExportLoop(
                    context: context,
                    queueLabel: "wav.export.queue",
                    appendFailureCode: -8,
                    readerFailureCode: -9
                )
            } catch {
                fail(error)
            }
        }
    }

    private static func removeFileIfNeeded(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func fetchAudioTrack(from asset: AVURLAsset, failureCode: Int) async throws -> AVAssetTrack {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "export", code: failureCode)
        }
        return track
    }

    private static func audioCharacteristics(for track: AVAssetTrack) async throws -> (sampleRate: Double, channels: Int) {
        let formatDescriptions = try await track.load(.formatDescriptions)
        let cmDesc: CMFormatDescription? = formatDescriptions.first
        let asbd = cmDesc.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }
        let sampleRate = asbd?.mSampleRate ?? 44_100
        let channels = Int(max(asbd?.mChannelsPerFrame ?? 2, 1))
        return (sampleRate, channels)
    }

    private static func pcmSettings(sampleRate: Double, channels: Int) -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }

    private static func aacSettings(sampleRate: Double, channels: Int, bitrate: Int) -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: max(bitrate, 64) * 1000,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    private static func makeReader(
        for asset: AVURLAsset,
        track: AVAssetTrack,
        settings: [String: Any],
        failureCode: Int
    ) throws -> (AVAssetReader, AVAssetReaderTrackOutput) {
        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        readerOutput.alwaysCopiesSampleData = false
        readerOutput.audioTimePitchAlgorithm = .timeDomain
        guard reader.canAdd(readerOutput) else {
            throw NSError(domain: "export", code: failureCode)
        }
        reader.add(readerOutput)
        return (reader, readerOutput)
    }

    private static func makeWriter(
        outputURL: URL,
        fileType: AVFileType,
        settings: [String: Any],
        failureCode: Int
    ) throws -> (AVAssetWriter, AVAssetWriterInput) {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: fileType)
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(writerInput) else {
            throw NSError(domain: "export", code: failureCode)
        }
        writer.add(writerInput)
        return (writer, writerInput)
    }

    private static func startSession(
        asset: AVURLAsset,
        reader: AVAssetReader,
        readerOutput: AVAssetReaderTrackOutput,
        writer: AVAssetWriter,
        writerInput: AVAssetWriterInput,
        outputURL: URL,
        startFailureCode: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) async throws -> MediaExportContext {
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "export", code: startFailureCode)
        }
        let durationSeconds = (try? await asset.load(.duration).seconds) ?? 0
        reader.startReading()
        writer.startSession(atSourceTime: .zero)

        return MediaExportContext(
            reader: reader,
            readerOutput: readerOutput,
            writer: writer,
            writerInput: writerInput,
            outputURL: outputURL,
            durationSeconds: durationSeconds,
            progress: progress,
            completion: completion
        )
    }

    private static func wavToMp3(wavURL: URL, mp3URL: URL, bitrate: Int, progress: @escaping (Double) -> Void) throws {
        guard let pcm = fopen(wavURL.path, "rb") else { throw NSError(domain: "lame", code: -1) }
        defer { fclose(pcm) }
        guard let mp3 = fopen(mp3URL.path, "wb") else { throw NSError(domain: "lame", code: -2) }
        defer { fclose(mp3) }
        guard let lame: OpaquePointer = lame_init() else { throw NSError(domain: "lame", code: -3) }
        var header = [UInt8](repeating: 0, count: 44)
        fread(&header, 1, header.count, pcm)
        let sampleRate = header.withUnsafeBytes { ptr -> UInt32 in
            ptr.load(fromByteOffset: 24, as: UInt32.self).littleEndian
        }
        let channels = header.withUnsafeBytes { ptr -> UInt16 in
            ptr.load(fromByteOffset: 22, as: UInt16.self).littleEndian
        }
        let resolvedSampleRate = sampleRate > 0 ? Int32(sampleRate) : 44_100
        let resolvedChannels = max(Int32(channels), 1)
        lame_set_in_samplerate(lame, resolvedSampleRate)
        lame_set_num_channels(lame, resolvedChannels)
        lame_set_VBR(lame, vbr_off)
        lame_set_brate(lame, Int32(max(bitrate, 64)))
        lame_set_quality(lame, 2)
        lame_init_params(lame)
        fseek(pcm, 44, SEEK_SET)
        let pcmBufferSize: Int32 = 8192
        var pcmBuffer = [Int16](repeating: 0, count: Int(pcmBufferSize))
        var mp3Buffer = [UInt8](repeating: 0, count: Int(8192))
        var read: Int32
        let totalBytes = max(((try? FileManager.default.attributesOfItem(atPath: wavURL.path)[.size] as? NSNumber)?.doubleValue ?? 0) - 44, 0)
        var processedBytes: Double = 0
        repeat {
            read = Int32(pcmBuffer.withUnsafeMutableBufferPointer { ptr in
                fread(ptr.baseAddress, MemoryLayout<Int16>.size, Int(pcmBufferSize), pcm)
            })
            let write = lame_encode_buffer_interleaved(lame, &pcmBuffer, read / 2, &mp3Buffer, 8192)
            _ = mp3Buffer.withUnsafeBufferPointer { ptr in
                fwrite(ptr.baseAddress, Int(write), 1, mp3)
            }
            processedBytes += Double(read) * Double(MemoryLayout<Int16>.size)
            if totalBytes > 0 {
                let ratio = min(max(processedBytes / totalBytes, 0), 1)
                DispatchQueue.main.async {
                    progress(ratio)
                }
            }
        } while read != 0
        let flush = lame_encode_flush(lame, &mp3Buffer, 8192)
        _ = mp3Buffer.withUnsafeBufferPointer { ptr in
            fwrite(ptr.baseAddress, Int(flush), 1, mp3)
        }
        DispatchQueue.main.async {
            progress(1)
        }
        lame_close(lame)
        try? FileManager.default.removeItem(at: wavURL)
    }
}

