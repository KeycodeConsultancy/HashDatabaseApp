//
//  HashViewModel.swift
//  HashDatabaseApp
//
//  Created by Kevin Reid on 07/02/2024.
//

import Foundation
import SQLite3
import SwiftUI

class HashViewModel: ObservableObject {
    @Published var currentPage = 1
    @Published var totalRecords = 0
    @Published var data: [(String, String)] = []
    @Published var pageNumberInput = ""
    @Published var searchHash = ""
    @Published var hashFound = false

    private let database = SQLiteDatabase.shared

    func fetchData() {
        let offset = (currentPage - 1) * Constants.theMaximumAmountOfRecordsPaged
        database.fetchData(withLimit: Constants.theMaximumAmountOfRecordsPaged, offset: offset) { [weak self] result, totalRecordsCount in
            guard let self = self else { return }
            if let result = result {
                self.data = result
                self.totalRecords = totalRecordsCount
            } else {
                print("Failed to fetch data")
            }
        }
    }
    
    func searchHashInDatabase() {
        print("Hashes \(searchHash)")
        guard !searchHash.isEmpty else {
            return
        }

        let hashes = searchHash.components(separatedBy: ",")
        var allHashesFound = true

        for hash in hashes {
            database.searchHashInDatabase(withPattern: hash.trimmingCharacters(in: .whitespacesAndNewlines)) { [weak self] result, _ in
                guard let self = self else { return }
                if let result = result, !result.isEmpty {
                    self.hashFound = true
                } else {
                    allHashesFound = false
                }
            }
        }

        if !allHashesFound {
            self.hashFound = false
        }

        searchHash = ""
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
