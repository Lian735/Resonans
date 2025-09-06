import AVFoundation
import Foundation
import LAME

enum AudioFormat: String, CaseIterable {
    case wav = "WAV"
    case m4a = "M4A"
    case mp3 = "MP3"
}

final class VideoToAudioConverter {
    static func convert(videoURL: URL, format: AudioFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: videoURL)
        let baseName = videoURL.deletingPathExtension().lastPathComponent + "_out"
        let tmp = FileManager.default.temporaryDirectory
        switch format {
        case .wav:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension("wav")
            export(asset: asset, outputURL: out, fileType: .wav, completion: completion)
        case .m4a:
            let out = tmp.appendingPathComponent(baseName).appendingPathExtension("m4a")
            export(asset: asset, outputURL: out, fileType: .m4a, completion: completion)
        case .mp3:
            let wavURL = tmp.appendingPathComponent(baseName).appendingPathExtension("wav")
            export(asset: asset, outputURL: wavURL, fileType: .wav) { result in
                switch result {
                case .failure(let err):
                    completion(.failure(err))
                case .success:
                    do {
                        let mp3URL = tmp.appendingPathComponent(baseName).appendingPathExtension("mp3")
                        try wavToMp3(wavURL: wavURL, mp3URL: mp3URL)
                        completion(.success(mp3URL))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private static func export(asset: AVAsset, outputURL: URL, fileType: AVFileType, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "export", code: -1)))
            return
        }
        exporter.outputURL = outputURL
        exporter.outputFileType = fileType
        exporter.exportAsynchronously {
            if exporter.status == .completed {
                completion(.success(outputURL))
            } else {
                completion(.failure(exporter.error ?? NSError(domain: "export", code: -2)))
            }
        }
    }

    private static func wavToMp3(wavURL: URL, mp3URL: URL) throws {
        guard let pcm = fopen(wavURL.path, "rb") else { throw NSError(domain: "lame", code: -1) }
        defer { fclose(pcm) }
        guard let mp3 = fopen(mp3URL.path, "wb") else { throw NSError(domain: "lame", code: -2) }
        defer { fclose(mp3) }
        let lame = lame_init()
        lame_set_in_samplerate(lame, 44100)
        lame_set_VBR(lame, vbr_default)
        lame_init_params(lame)
        let pcmBufferSize: Int32 = 8192
        var pcmBuffer = [Int16](repeating: 0, count: Int(pcmBufferSize))
        var mp3Buffer = [UInt8](repeating: 0, count: Int(8192))
        var read: Int32
        repeat {
            read = pcmBuffer.withUnsafeMutableBufferPointer { ptr in
                fread(ptr.baseAddress, MemoryLayout<Int16>.size, Int(pcmBufferSize), pcm)
            }
            let write = lame_encode_buffer_interleaved(lame, &pcmBuffer, read / 2, &mp3Buffer, 8192)
            mp3Buffer.withUnsafeBufferPointer { ptr in
                fwrite(ptr.baseAddress, Int(write), 1, mp3)
            }
        } while read != 0
        let flush = lame_encode_flush(lame, &mp3Buffer, 8192)
        mp3Buffer.withUnsafeBufferPointer { ptr in
            fwrite(ptr.baseAddress, Int(flush), 1, mp3)
        }
        lame_close(lame)
    }
}
