//
//  FileStorage.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/11/25.
//

import Foundation

final class FileStorage {
    static let shared = FileStorage()
    private let fileManager = FileManager.default
    
    private func getDirectoryUrl(_ type: DirectoryType, subFolder: SubfolderType) throws -> URL {
        guard var directoryUrl = type.url else {
            fatalError("Error initializing \(type) directory URL")
        }
        
        if subFolder != .none {
            directoryUrl = directoryUrl.appendingPathComponent(subFolder.folderName, isDirectory: true)
        }
        
        if !fileManager.fileExists(atPath: directoryUrl.path()) {
            do {
                try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw FileStorageError.unknown(error)
            }
        }
        
        return directoryUrl
    }
    
    func saveFile(
        on directory: DirectoryType,
        subFolder: SubfolderType = .none,
        fileName: String,
        fileData: Data
    ) throws {
        let directoryUrl = try getDirectoryUrl(directory, subFolder: subFolder)
        let savedUrl = directoryUrl.appendingPathComponent(fileName)
        try fileData.write(to: savedUrl)
    }
    
    func deleteFile(
        on directory: DirectoryType,
        subFolder: SubfolderType = .none,
        fileName: String
    ) throws {
        let directoryUrl = try getDirectoryUrl(directory, subFolder: subFolder)
        let fileUrl = directoryUrl.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileUrl.path()) else {
            throw FileStorageError.fileNotFound(fileUrl)
        }
        
        try fileManager.removeItem(at: fileUrl)
    }
    
    func loadFile(
        on directory: DirectoryType,
        subFolder: SubfolderType = .none,
        fileName: String
    ) throws -> Data {
        let directoryUrl = try getDirectoryUrl(directory, subFolder: subFolder)
        let fileUrl = directoryUrl.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileUrl.path()) else {
            throw FileStorageError.fileNotFound(fileUrl)
        }
        
        return try Data(contentsOf: fileUrl)
    }
}

extension FileStorage {
    enum DirectoryType {
        case documents
        case caches
        case temporary
        case applicationSupport
        
        var url: URL? {
            switch self {
            case .documents:
                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            case .caches:
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            case .temporary:
                return FileManager.default.temporaryDirectory
            case .applicationSupport:
                return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            }
        }
    }
    
    enum FileStorageError: LocalizedError {
        case fileNotFound(URL)
        case failedToCreateDirectory(URL)
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "File not found at path: \(url.path)"
            case .failedToCreateDirectory(let url):
                return "Failed to create directory: \(url.path)"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    enum SubfolderType: String, CaseIterable {
        case none
        case audios
        case videos
        case images

        var folderName: String {
            switch self {
            case .none:
                return ""
            default:
                return self.rawValue
            }
        }
    }
}
