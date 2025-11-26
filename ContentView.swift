//
//  ContentView.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "brain.head.profile")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Homework Copilot")
                .font(.title)
                .padding()
            
            Text("This app runs in the menu bar")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Look for the 🧠 icon in your menu bar")
                .font(.caption)
                .padding(.top, 5)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
