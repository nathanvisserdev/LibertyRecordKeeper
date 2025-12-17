//
//  DatabaseService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import SQLite3
import CryptoKit

enum DatabaseError: Error {
    case openFailed
    case prepareFailed
    case executeFailed
    case encryptionFailed
    case decryptionFailed
    case integrityCheckFailed
}

class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private var encryptionKey: SymmetricKey?
    private let databaseFileName = "forensic_records.db"
    
    private var databaseURL: URL {
        return URL(fileURLWithPath: "/Users/nathanvisser/Library/Containers/Liberty.LibertyRecordKeeper/Data/Documents/forensic_records.db")
    }
    
    private var forensic_records_db_sha_sum = "12341bc3cce1b3725cc5386e9028544ef2dd8c92a8c096c9eef1e45c6b0074fa"
    
    private init() {}
    
    // MARK: - Database Lifecycle
    
    private func getSha256Sum(for fileURL: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shasum")
        process.arguments = ["-a", "256", fileURL.path]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.split(separator: " ").first else {
            throw DatabaseError.integrityCheckFailed
        }

        return String(output)
    }
    
    func initializeDatabase(with key: SymmetricKey) throws {
        self.encryptionKey = key
        
        // Close any existing connection first
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            do {
                let computedHash = try getSha256Sum(for: databaseURL)
                if computedHash == forensic_records_db_sha_sum {
                    print("DB integrity verified.")
                } else {
                    print("DB failed integrity verification.")
                }
            } catch {
                print("Failed to compute SHA-256 hash: \(error)")
            }
            sqlite3_close(db)
            db = nil
        }
        
        // Ensure the documents directory exists
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        
        print("Initializing database at URL: \(databaseURL)")
        
        // Check if the database file exists
        if !FileManager.default.fileExists(atPath: databaseURL.path) {
            print("Database file does not exist. Creating a new database file.")
            FileManager.default.createFile(atPath: databaseURL.path, contents: nil, attributes: nil)
        } else {
            print("Database file already exists.")
        }

        // Proceed with opening the database
        let result = sqlite3_open(databaseURL.path, &db)
        guard result == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Database open failed: \(errorMessage)")
            throw DatabaseError.openFailed
        }
        
        print("Database opened successfully.")
        
        // Enable Write-Ahead Logging for better concurrency
        print("Enabling Write-Ahead Logging...")
        try execute("PRAGMA journal_mode=WAL;")
        
        // Enable foreign keys
        print("Enabling foreign keys...")
        try execute("PRAGMA foreign_keys=ON;")
        
        // Create tables if they don't exist
        print("Creating tables...")
        try createTables()
        print("Database initialization complete.")
    }
    
    func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    private func createTables() throws {
        // Screen Recordings Table
        try execute("""
            CREATE TABLE IF NOT EXISTS screen_recordings (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                duration REAL NOT NULL,
                resolution TEXT NOT NULL,
                frame_rate REAL NOT NULL
            );
        """)
        
        // Videos Table
        try execute("""
            CREATE TABLE IF NOT EXISTS videos (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                duration REAL NOT NULL,
                resolution TEXT NOT NULL,
                codec TEXT NOT NULL
            );
        """)
        
        // Photos Table
        try execute("""
            CREATE TABLE IF NOT EXISTS photos (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                resolution TEXT NOT NULL,
                format TEXT NOT NULL
            );
        """)
        
        // Audio Recordings Table
        try execute("""
            CREATE TABLE IF NOT EXISTS audio_recordings (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                duration REAL NOT NULL,
                format TEXT NOT NULL,
                sample_rate REAL NOT NULL
            );
        """)
        
        // Screenshots Table
        try execute("""
            CREATE TABLE IF NOT EXISTS screenshots (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                resolution TEXT NOT NULL,
                format TEXT NOT NULL
            );
        """)
        
        // AI Chat Logs Table
        try execute("""
            CREATE TABLE IF NOT EXISTS ai_chat_logs (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                conversation_title TEXT NOT NULL,
                message_count INTEGER NOT NULL
            );
        """)
        
        // Document Records Table
        try execute("""
            CREATE TABLE IF NOT EXISTS document_records (
                id TEXT PRIMARY KEY,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                device_identifier TEXT NOT NULL,
                checksum_sha256 TEXT NOT NULL,
                file_url TEXT,
                file_size INTEGER NOT NULL,
                metadata_json TEXT NOT NULL,
                custody_json TEXT NOT NULL,
                document_type TEXT NOT NULL,
                description TEXT NOT NULL
            );
        """)
        
        // Create indexes for better query performance
        try execute("CREATE INDEX IF NOT EXISTS idx_screen_recordings_created ON screen_recordings(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_videos_created ON videos(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_photos_created ON photos(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_audio_created ON audio_recordings(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_screenshots_created ON screenshots(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_chat_logs_created ON ai_chat_logs(created_at DESC);")
        try execute("CREATE INDEX IF NOT EXISTS idx_document_records_created ON document_records(created_at DESC);")
    }
    
    private func execute(_ sql: String) throws {
        guard db != nil else {
            print("Database pointer is nil when trying to execute SQL")
            throw DatabaseError.prepareFailed
        }
        
        var statement: OpaquePointer?
        
        // Potential error: SQL prepare statement failed
        print("Preparing SQL statement: \(sql)")
        let prepareResult = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        guard prepareResult == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL prepare failed: \(errorMessage)")
            print("SQL: \(sql)")
            throw DatabaseError.prepareFailed
        }
        
        print("SQL statement prepared successfully.")
        
        var stepResult: Int32
        repeat {
            stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_ROW {
                // Consume the row (if needed, log or process the data here)
                print("SQL returned a row, ignoring as it's not needed.")
            }
        } while stepResult == SQLITE_ROW
        
        guard stepResult == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL execution failed: \(errorMessage)")
            print("SQL: \(sql)")
            throw DatabaseError.executeFailed
        }
        
        print("SQL executed successfully: \(sql)")
    }
    
    // MARK: - Encryption Helpers
    
    private func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw DatabaseError.encryptionFailed
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw DatabaseError.decryptionFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Screen Recordings
    
    func saveScreenRecording(_ record: ScreenRecordingRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        
        let sql = """
            INSERT INTO screen_recordings 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, duration, resolution, frame_rate)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_double(statement, 10, record.duration)
        sqlite3_bind_text(statement, 11, record.resolution, -1, nil)
        sqlite3_bind_double(statement, 12, record.frameRate)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllScreenRecordings() throws -> [ScreenRecordingRecord] {
        let sql = "SELECT * FROM screen_recordings ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [ScreenRecordingRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            // Extract all fields - this is simplified, full implementation would parse all fields
            _ = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))) ?? UUID()
            _ = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            _ = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            // ... parse remaining fields
            
            // For brevity, creating a minimal record - full implementation would restore all properties
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let duration = sqlite3_column_double(statement, 9)
                let resolution = String(cString: sqlite3_column_text(statement, 10))

                guard let frameRateValue = sqlite3_column_text(statement, 11) else {
                    let defaultFrameRate = 30.0 // Default value
                    print("Warning: Frame rate not found in database. Using default value: \(defaultFrameRate)")
                    let record = ScreenRecordingRecord(
                        fileURL: url,
                        duration: duration,
                        resolution: resolution,
                        frameRate: defaultFrameRate
                    )
                    records.append(record)
                    continue
                }

                let frameRate = sqlite3_column_double(statement, 11)
                let record = ScreenRecordingRecord(
                    fileURL: url,
                    duration: duration,
                    resolution: resolution,
                    frameRate: frameRate
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    // MARK: - Videos
    
    func saveVideo(_ record: VideoRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        
        let sql = """
            INSERT INTO videos 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, duration, resolution, codec)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_double(statement, 10, record.duration)
        sqlite3_bind_text(statement, 11, record.resolution, -1, nil)
        sqlite3_bind_text(statement, 12, record.codec, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllVideos() throws -> [VideoRecord] {
        let sql = "SELECT * FROM videos ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [VideoRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let duration = sqlite3_column_double(statement, 9)
                let resolution = String(cString: sqlite3_column_text(statement, 10))
                let frameRate = sqlite3_column_double(statement, 12)
                let codec = String(cString: sqlite3_column_text(statement, 11))
                
                let record = VideoRecord(
                    fileURL: url,
                    duration: duration,
                    resolution: resolution,
                    frameRate: frameRate,
                    codec: codec
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    // Similar methods for Photos, Audio, Screenshots, and AI Chat Logs...
    // For brevity, showing pattern above and implementing the remaining in actual usage
    
    func savePhoto(_ record: PhotoRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        
        let sql = """
            INSERT INTO photos 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, resolution, format)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 10, record.resolution, -1, nil)
        sqlite3_bind_text(statement, 11, record.format, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllPhotos() throws -> [PhotoRecord] {
        let sql = "SELECT * FROM photos ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [PhotoRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let resolution = String(cString: sqlite3_column_text(statement, 9))
                let format = String(cString: sqlite3_column_text(statement, 10))
                
                let record = PhotoRecord(fileURL: url, resolution: resolution, format: format)
                records.append(record)
            }
        }
        
        return records
    }
    
    func saveAudioRecording(_ record: AudioRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        
        let sql = """
            INSERT INTO audio_recordings 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, duration, format, sample_rate)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_double(statement, 10, record.duration)
        sqlite3_bind_text(statement, 11, record.format, -1, nil)
        sqlite3_bind_double(statement, 12, record.sampleRate)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllAudioRecordings() throws -> [AudioRecord] {
        let sql = "SELECT * FROM audio_recordings ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [AudioRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let duration = sqlite3_column_double(statement, 9)
                let format = String(cString: sqlite3_column_text(statement, 10))
                let sampleRate = sqlite3_column_double(statement, 11)
                
                let record = AudioRecord(fileURL: url, duration: duration, format: format, sampleRate: sampleRate)
                records.append(record)
            }
        }
        
        return records
    }
    
    func saveScreenshot(_ record: ScreenshotRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        
        let sql = """
            INSERT INTO screenshots 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, resolution, format)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 10, record.resolution, -1, nil)
        sqlite3_bind_text(statement, 11, record.format, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllScreenshots() throws -> [ScreenshotRecord] {
        let sql = "SELECT * FROM screenshots ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [ScreenshotRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let resolution = String(cString: sqlite3_column_text(statement, 9))
                let format = String(cString: sqlite3_column_text(statement, 10))
                
                let record = ScreenshotRecord(fileURL: url, resolution: resolution, format: format)
                records.append(record)
            }
        }
        
        return records
    }
    
    func saveDocumentRecord(_ record: DocumentRecord) throws {
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)

        let sql = """
            INSERT INTO document_records 
            (id, created_at, modified_at, device_identifier, checksum_sha256, file_url, file_size, 
             metadata_json, custody_json, document_type, description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, record.modifiedAt.timeIntervalSince1970)
        sqlite3_bind_text(statement, 4, record.deviceIdentifier, -1, nil)
        sqlite3_bind_text(statement, 5, record.checksumSHA256, -1, nil)
        sqlite3_bind_text(statement, 6, record.fileURL?.path, -1, nil)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_text(statement, 8, String(data: metadataJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 9, String(data: custodyJSON, encoding: .utf8), -1, nil)
        sqlite3_bind_text(statement, 10, record.documentType, -1, nil)
        sqlite3_bind_text(statement, 11, record.description, -1, nil)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executeFailed
        }
    }
    
    func fetchAllDocumentRecords() throws -> [DocumentRecord] {
        let sql = "SELECT * FROM document_records ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        var records: [DocumentRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let fileURLString = sqlite3_column_text(statement, 5),
               let url = URL(string: String(cString: fileURLString)) {
                let documentType = String(cString: sqlite3_column_text(statement, 10))
                let description = String(cString: sqlite3_column_text(statement, 11))
                
                let record = DocumentRecord(fileURL: url, documentType: documentType, description: description)
                records.append(record)
            }
        }
        
        return records
    }
}
