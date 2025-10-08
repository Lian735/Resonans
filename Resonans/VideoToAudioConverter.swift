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
                guard context.reader.status == .reading,
                      let sampleBuffer = context.readerOutput.copyNextSampleBuffer() else {
                    finalize(context: context, readerFailureCode: readerFailureCode)
                    return
                }

                guard context.writerInput.append(sampleBuffer) else {
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
            }
        }
    }

    private static func finalize(context: MediaExportContext, readerFailureCode: Int) {
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
    }

    static func convert(
        videoURL: URL,
        format: AudioFormat,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let baseName = videoURL.deletingPathExtension().lastPathComponent + "_out"
        progress(0)

        switch format {
        case .m4a:
            let output = temporaryURL(for: baseName, format: .m4a)
            exportToM4A(videoURL: videoURL, outputURL: output, bitrate: bitrate, progress: progress, completion: completion)
        case .wav:
            let output = temporaryURL(for: baseName, format: .wav)
            exportToWAV(videoURL: videoURL, outputURL: output, progress: progress, completion: completion)
        case .mp3:
            convertToMP3(
                baseName: baseName,
                videoURL: videoURL,
                bitrate: bitrate,
                progress: progress,
                completion: completion
            )
        }
    }

    private static func temporaryURL(for baseName: String, format: AudioFormat) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(baseName)
            .appendingPathExtension(format.fileExtension)
    }

    private static func convertToMP3(
        baseName: String,
        videoURL: URL,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let wavURL = temporaryURL(for: baseName, format: .wav)
        let mp3URL = temporaryURL(for: baseName, format: .mp3)

        exportToWAV(videoURL: videoURL, outputURL: wavURL, progress: { value in
            progress(value * 0.85)
        }) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                do {
                    try wavToMp3(wavURL: wavURL, mp3URL: mp3URL, bitrate: bitrate) { encodeProgress in
                        let mapped = min(max(0.85 + (encodeProgress * 0.15), 0), 1)
                        progress(mapped)
                    }
                    progress(1)
                    completion(.success(mp3URL))
                } catch {
                    completion(.failure(error))
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
            do {
                try removeExistingFile(at: outputURL)

                let asset = AVURLAsset(url: videoURL)
                let track = try await audioTrack(from: asset, failureCode: -3)
                let (sampleRate, channels) = try await audioProperties(for: track)

                let readerSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: sampleRate,
                    AVNumberOfChannelsKey: channels,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]

                let writerSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVEncoderBitRateKey: max(bitrate, 64) * 1000,
                    AVSampleRateKey: sampleRate,
                    AVNumberOfChannelsKey: channels,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                let reader = try AVAssetReader(asset: asset)
                let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: readerSettings)
                readerOutput.alwaysCopiesSampleData = false
                readerOutput.audioTimePitchAlgorithm = .timeDomain
                try ensure(reader.canAdd(readerOutput), code: -10)
                reader.add(readerOutput)

                let writer = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
                let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerSettings)
                writerInput.expectsMediaDataInRealTime = false
                try ensure(writer.canAdd(writerInput), code: -11)
                writer.add(writerInput)

                try startWriting(writer, code: -12)

                let durationSeconds = (try? await asset.load(.duration).seconds) ?? 0
                reader.startReading()
                writer.startSession(atSourceTime: .zero)

                let context = MediaExportContext(
                    reader: reader,
                    readerOutput: readerOutput,
                    writer: writer,
                    writerInput: writerInput,
                    outputURL: outputURL,
                    durationSeconds: durationSeconds,
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
                deliverFailure(completion, error: error)
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
            do {
                try removeExistingFile(at: outputURL)

                let asset = AVURLAsset(url: videoURL)
                let track = try await audioTrack(from: asset, failureCode: -4)
                let (sampleRate, channels) = try await audioProperties(for: track)

                let pcmSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: sampleRate,
                    AVNumberOfChannelsKey: channels,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]

                let reader = try AVAssetReader(asset: asset)
                let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: pcmSettings)
                readerOutput.alwaysCopiesSampleData = false
                readerOutput.audioTimePitchAlgorithm = .timeDomain
                try ensure(reader.canAdd(readerOutput), code: -5)
                reader.add(readerOutput)

                let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)
                let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: pcmSettings)
                writerInput.expectsMediaDataInRealTime = false
                try ensure(writer.canAdd(writerInput), code: -6)
                writer.add(writerInput)

                try startWriting(writer, code: -7)

                let durationSeconds = (try? await asset.load(.duration).seconds) ?? 0
                reader.startReading()
                writer.startSession(atSourceTime: .zero)

                let context = MediaExportContext(
                    reader: reader,
                    readerOutput: readerOutput,
                    writer: writer,
                    writerInput: writerInput,
                    outputURL: outputURL,
                    durationSeconds: durationSeconds,
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
                deliverFailure(completion, error: error)
            }
        }
    }

    private static func ensure(_ condition: Bool, code: Int) throws {
        guard condition else { throw NSError(domain: "export", code: code) }
    }

    private static func removeExistingFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func startWriting(_ writer: AVAssetWriter, code: Int) throws {
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "export", code: code)
        }
    }

    private static func audioTrack(from asset: AVAsset, failureCode: Int) async throws -> AVAssetTrack {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "export", code: failureCode)
        }
        return track
    }

    private static func audioProperties(for track: AVAssetTrack) async throws -> (sampleRate: Double, channels: Int) {
        let formatDescriptions = try await track.load(.formatDescriptions)
        let cmDesc: CMFormatDescription? = formatDescriptions.first
        let asbd = cmDesc.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }
        let sampleRate = asbd?.mSampleRate ?? 44_100
        let channels = Int(max(asbd?.mChannelsPerFrame ?? 2, 1))
        return (sampleRate, channels)
    }

    private static func deliverFailure(
        _ completion: @escaping (Result<URL, Error>) -> Void,
        error: Error
    ) {
        DispatchQueue.main.async {
            completion(.failure(error))
        }
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

