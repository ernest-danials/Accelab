//
//  VideoClipStore.swift
//  Accelab
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Keeps the clip being analysed in the temporary directory.
nonisolated enum VideoClipStore {
    private static let filePrefix = "accelab-clip-"

    static func makeTempURL(pathExtension: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)\(UUID().uuidString)").appendingPathExtension(pathExtension.isEmpty ? "mov" : pathExtension)
    }

    static func removeTempFiles() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix(filePrefix) {
            try? fileManager.removeItem(at: file)
        }
    }
}

/// A video picked from the photo library, copied into the temporary directory so it outlives the picker.
nonisolated struct ImportedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let url = VideoClipStore.makeTempURL(pathExtension: received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: url)
            return Self(url: url)
        }
    }
}
