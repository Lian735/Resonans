//
//  EditorDetailView.swift
//  Resonans
//
//  Created by Lian on 11.11.25.
//

import SwiftUI

struct EditorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack {
                    HStack {
                        Text("Cinemator")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .navigationTitle("Cinemator")
                    .padding()
                }
                
                VStack {
                    previewSection
                    
                    Spacer()
                    
                    timelineSection
                    
                    actionSection
                }
                .padding(.horizontal, 24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var previewSection: some View {
        EmptyView()
    }
    
    private var timelineSection: some View {
        EmptyView()
    }
    
    private var actionSection: some View {
        EmptyView()
    }
}

#Preview {
    EditorDetailView()
}

