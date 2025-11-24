//
//  Project Detail View.swift
//  Resonans
//
//  Created by Samuel Meincke on 24.11.25.
//
import SwiftUI

struct ProjectDetailView: View {
    @State private var project: VideoProject
    
    init(_ project: VideoProject){
        self.project = project
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                Text("This is a Preview")
            }
            .navigationTitle(project.title)
        }
    }
}
