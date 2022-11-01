//
//  TestableFileSystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableFileSystem: FileSystemProtocol {
    init(files: [String: FakeFile]) {
        self.files = files
    }

    var files: [String: FakeFile]

    // MARK: - Basics

    func createDirectory(_ path: String, withIntermediateDirectories: Bool) throws {
        if files[path] != nil {
            throw TestableFileSystemError.alreadyExists
        }

        self.files[path] = .fake(.directory)
    }

    func writeAtomicallyToFile(_ path: String, content: String) throws {
        if files[path] != nil {
            throw TestableFileSystemError.alreadyExists
        }

        self.files[path] = .fake(.text, content)
    }

    func readStringFromFile(_ path: String) throws -> String {
        guard let file = files[path] else {
            throw TestableFileSystemError.fileMissing
        }

        return file.content ?? ""
    }

    // MARK: - Move & Delete Files

    func move(from path: String, to newPath: String) throws {
        // TODO
    }

    func remove(_ path: String) throws {
        // TODO
    }

    // MARK: — Attributes

    func makeExecutable(_ path: String) throws {
        guard let file = files[path] else {
            throw TestableFileSystemError.fileMissing
        }

        file.type = .binary
    }

    // MARK: - Checks

    func isExecutableFile(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return file.type == .binary
    }

    func isWriteableFile(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return !file.readOnly
    }

    func anyExists(_ path: String) -> Bool {
        return files.keys.contains(path)
    }

    func fileExists(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return [.binary, .symlink, .text].contains(file.type)
    }

    func directoryExists(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return [.directory].contains(file.type)
    }

    func fileIsSymlink(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return file.type == .symlink
    }
}

enum FakeFileType: Codable {
    case binary, text, directory, symlink
}

class FakeFile: Codable {
    var type: FakeFileType
    var content: String?
    var readOnly: Bool = false

    init(type: FakeFileType, content: String?, readOnly: Bool = false) {
        self.type = type
        self.content = content
        self.readOnly = readOnly
    }

    public static func fake(
        _ type: FakeFileType,
        _ content: String? = nil,
        readOnly: Bool = false
    ) -> FakeFile {
        return FakeFile(
            type: type,
            content: content,
            readOnly: readOnly
        )
    }
}

enum TestableFileSystemError: Error {
    case fileMissing
    case alreadyExists
}
