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
    static func convert(
        videoURL: URL,
        format: AudioFormat,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: videoURL)
        let baseName = videoURL.deletingPathExtension().lastPathComponent + "_out"
        let tmp = FileManager.default.temporaryDirectory
        progress(0)
        switch format {
        case .m4a:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension(format.fileExtension)
            exportToM4A(asset: asset, outputURL: out, bitrate: bitrate, progress: progress, completion: completion)
        case .wav:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension(format.fileExtension)
            exportToWAV(asset: asset, outputURL: out, progress: progress, completion: completion)
        case .mp3:
            let wavURL = tmp.appendingPathComponent(baseName).appendingPathExtension(AudioFormat.wav.fileExtension)
            exportToWAV(asset: asset, outputURL: wavURL, progress: { value in
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
        asset: AVAsset,
        outputURL: URL,
        bitrate: Int,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            guard let track = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "export", code: -3)))
                }
                return
            }

            Task {
                do {
                    let formatDescriptions: [CMFormatDescription] = try await track.load(.formatDescriptions)
                    let cmDesc: CMFormatDescription? = formatDescriptions.first
                    let asbd = cmDesc.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }
                    let sampleRate = asbd?.mSampleRate ?? 44_100
                    let channels = Int(max(asbd?.mChannelsPerFrame ?? 2, 1))

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
                    guard reader.canAdd(readerOutput) else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "export", code: -10)))
                        }
                        return
                    }
                    reader.add(readerOutput)

                    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
                    let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerSettings)
                    writerInput.expectsMediaDataInRealTime = false
                    guard writer.canAdd(writerInput) else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "export", code: -11)))
                        }
                        return
                    }
                    writer.add(writerInput)

                    guard writer.startWriting() else {
                        throw writer.error ?? NSError(domain: "export", code: -12)
                    }

                    reader.startReading()
                    writer.startSession(atSourceTime: .zero)

                    let durationSeconds = asset.duration.seconds
                    let queue = DispatchQueue(label: "m4a.export.queue")
                    writerInput.requestMediaDataWhenReady(on: queue) {
                        while writerInput.isReadyForMoreMediaData {
                            if reader.status == .reading, let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                                if !writerInput.append(sampleBuffer) {
                                    reader.cancelReading()
                                    writerInput.markAsFinished()
                                    writer.cancelWriting()
                                    let error = writer.error ?? NSError(domain: "export", code: -13)
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                    return
                                }

                                if durationSeconds.isFinite && durationSeconds > 0 {
                                    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                                    let ratio = min(max(time / durationSeconds, 0), 1)
                                    DispatchQueue.main.async {
                                        progress(ratio)
                                    }
                                }
                            } else {
                                writerInput.markAsFinished()
                                switch reader.status {
                                case .completed:
                                    writer.finishWriting {
                                        if let error = writer.error {
                                            DispatchQueue.main.async {
                                                completion(.failure(error))
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                progress(1)
                                                completion(.success(outputURL))
                                            }
                                        }
                                    }
                                case .failed, .cancelled:
                                    let error = reader.error ?? writer.error ?? NSError(domain: "export", code: -14)
                                    writer.cancelWriting()
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                default:
                                    break
                                }
                                return
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }

            return
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }

    private static func exportToWAV(
        asset: AVAsset,
        outputURL: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            guard let track = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "export", code: -4)))
                }
                return
            }

            Task {
                do {
                    let formatDescriptions: [CMFormatDescription] = try await track.load(.formatDescriptions)
                    let cmDesc: CMFormatDescription? = formatDescriptions.first
                    let asbd = cmDesc.flatMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee }
                    let sampleRate = asbd?.mSampleRate ?? 44_100
                    let channels = Int(asbd?.mChannelsPerFrame ?? 2)

                    let pcmSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: sampleRate,
                        AVNumberOfChannelsKey: channels,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false
                    ]

                    // Recreate the remainder of the original function from here using `pcmSettings`:
                    let reader = try AVAssetReader(asset: asset)
                    let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: pcmSettings)
                    readerOutput.alwaysCopiesSampleData = false
                    guard reader.canAdd(readerOutput) else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "export", code: -5)))
                        }
                        return
                    }
                    reader.add(readerOutput)

                    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)
                    let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: pcmSettings)
                    writerInput.expectsMediaDataInRealTime = false
                    guard writer.canAdd(writerInput) else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "export", code: -6)))
                        }
                        return
                    }
                    writer.add(writerInput)

                    guard writer.startWriting() else {
                        throw writer.error ?? NSError(domain: "export", code: -7)
                    }

                    let durationSeconds = asset.duration.seconds
                    reader.startReading()
                    writer.startSession(atSourceTime: .zero)

                    let queue = DispatchQueue(label: "wav.export.queue")
                    writerInput.requestMediaDataWhenReady(on: queue) {
                        while writerInput.isReadyForMoreMediaData {
                            if reader.status == .reading, let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                                if !writerInput.append(sampleBuffer) {
                                    reader.cancelReading()
                                    writerInput.markAsFinished()
                                    writer.cancelWriting()
                                    let error = writer.error ?? NSError(domain: "export", code: -8)
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                    return
                                }

                                if durationSeconds.isFinite && durationSeconds > 0 {
                                    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                                    let ratio = min(max(time / durationSeconds, 0), 1)
                                    DispatchQueue.main.async {
                                        progress(ratio)
                                    }
                                }
                            } else {
                                writerInput.markAsFinished()
                                switch reader.status {
                                case .completed:
                                    writer.finishWriting {
                                        if let error = writer.error {
                                            DispatchQueue.main.async {
                                                completion(.failure(error))
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                progress(1)
                                                completion(.success(outputURL))
                                            }
                                        }
                                    }
                                case .failed, .cancelled:
                                    let error = reader.error ?? writer.error ?? NSError(domain: "export", code: -9)
                                    writer.cancelWriting()
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                default:
                                    break
                                }
                                return
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }

            // Early return because the async Task will handle the rest
            return
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
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

