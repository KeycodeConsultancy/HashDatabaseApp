//
//  SQLiteDatabase.swift
//  HashDatabaseApp
//
//  Created by Kevin Reid on 07/02/2024.
//

import Foundation
import SQLite3

class SQLiteDatabase {
    static let shared = SQLiteDatabase()
    private let dbPointer: OpaquePointer?
        
    private init() {
        var db: OpaquePointer? = nil
        let databaseFileName = Constants.db
        guard let fullPath = Bundle.main.path(forResource: databaseFileName, ofType: nil) else {
            fatalError("Failed to locate database file '\(databaseFileName)' in the main bundle.")
        }

        if sqlite3_open_v2(fullPath, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            print("Successfully opened connection to database at \(fullPath)")
        } else {
            fatalError("Unable to open database. Verify that you created a database file at the given path: \(fullPath)")
        }
        
        dbPointer = db
    }

    deinit {
        sqlite3_close(dbPointer)
    }
    
    func fetchData(withLimit limit: Int, offset: Int, completion: @escaping ([(String, String)]?, Int) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var resultArray = [(String, String)]()
            
            var queryStatement: OpaquePointer? = nil
            let query = "SELECT hash_id, sha1 FROM safe_hashes LIMIT ? OFFSET ?;"
            
            guard sqlite3_prepare_v2(self.dbPointer, query, -1, &queryStatement, nil) == SQLITE_OK else {
                print("Error preparing query: \(String(cString: sqlite3_errmsg(self.dbPointer)))")
                completion(nil, 0)
                return
            }
            
            sqlite3_bind_int(queryStatement, 1, Int32(limit))
            sqlite3_bind_int(queryStatement, 2, Int32(offset))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                if let hashID = sqlite3_column_text(queryStatement, 0), let sha1 = sqlite3_column_text(queryStatement, 1) {
                    let hashIDString = String(cString: hashID)
                    let sha1String = String(cString: sha1)
                    resultArray.append((hashIDString, sha1String))
                } else {
                    print("Error retrieving data: \(String(cString: sqlite3_errmsg(self.dbPointer)))")
                }
            }
            
            sqlite3_finalize(queryStatement)
            DispatchQueue.main.async {
                completion(resultArray, resultArray.count)
            }
        }
    }
    
    func searchHashInDatabase(withPattern pattern: String, completion: @escaping ([(String, String)]?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var resultArray = [(String, String)]()
            
            var queryStatement: OpaquePointer? = nil
            let query = "SELECT hash_id, sha1 FROM safe_hashes WHERE sha1 = ?;"
            
            guard sqlite3_prepare_v2(self.dbPointer, query, -1, &queryStatement, nil) == SQLITE_OK else {
                let errorMessage = String(cString: sqlite3_errmsg(self.dbPointer))
                let error = NSError(domain: NSPOSIXErrorDomain, code: Int(SQLITE_ERROR), userInfo: [NSLocalizedDescriptionKey: "Error preparing query: \(errorMessage)"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let cPattern = pattern.cString(using: .utf8)
            sqlite3_bind_text(queryStatement, 1, cPattern, -1, nil)
        
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                if let hashID = sqlite3_column_text(queryStatement, 0), let sha1 = sqlite3_column_text(queryStatement, 1) {
                    let hashIDString = String(cString: hashID)
                    let sha1String = String(cString: sha1)
                    resultArray.append((hashIDString, sha1String))
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(self.dbPointer))
                    let error = NSError(domain: NSPOSIXErrorDomain, code: Int(SQLITE_ERROR), userInfo: [NSLocalizedDescriptionKey: "Error retrieving data: \(errorMessage)"])
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    sqlite3_finalize(queryStatement)
                    return
                }
            }
            
            sqlite3_finalize(queryStatement)
            DispatchQueue.main.async {
                completion(resultArray, nil)
            }
        }
    }
}
