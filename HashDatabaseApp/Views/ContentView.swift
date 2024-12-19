//
//  ContentView.swift
//  HashDatabaseApp
//
//  Created by Kevin Reid on 07/02/2024.
//

import SwiftUI

//0000002D9D62AEBE1E0E9DB6C4C4C7C16A163D2C
//0000004DA6391F7F5D2F7FCCF36CEBDA60C6EA02

struct ContentView: View {
    @StateObject private var viewModel = HashViewModel()
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                TextField("Enter Page Number", text: $viewModel.pageNumberInput)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)

                Button("Go to Page") {
                    if let pageNumber = Int(viewModel.pageNumberInput), pageNumber > 0 {
                        viewModel.currentPage = pageNumber
                        viewModel.fetchData()
                        viewModel.hideKeyboard()
                    }
                }
                .buttonStyle(RoundedButtonStyle())
            }

            HStack {
                TextField("Enter Hash", text: $viewModel.searchHash)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Search") {
                    viewModel.hideKeyboard()
                    viewModel.searchHashInDatabase()
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .frame(height: 50)

            List(viewModel.data, id: \.0) { item in
                VStack(alignment: .leading) {
                    Text("Hash ID: \(item.0)")
                    Text("SHA1: \(item.1)")
                }
            }

            HStack {
                Button("Previous Page") {
                    viewModel.hideKeyboard()
                    if viewModel.currentPage > 1 {
                        viewModel.currentPage -= 1
                        viewModel.fetchData()
                    }
                }
                .buttonStyle(RoundedButtonStyle())

                Button("Next Page") {
                    viewModel.hideKeyboard()
                        viewModel.currentPage += 1
                        viewModel.fetchData()

                }
                .buttonStyle(RoundedButtonStyle())
            }

            .alert(isPresented: $viewModel.hashFound) {
                Alert(title: Text("Hash Found"), message: Text("One or more hashes matching the search pattern were found."), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
        .onAppear {
            viewModel.fetchData()
        }
    }
}
