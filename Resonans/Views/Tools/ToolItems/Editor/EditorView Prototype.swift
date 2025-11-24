//
//  EditorView2.swift
//  Resonans
//
//  Created by Comic-Star_55 on 24.11.25.
//

import SwiftUI
import SwiftData

struct EditorView2: View {
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    
    @Query private var projects: [VideoProject]
    @Environment(\.modelContext) private var modelContext
    
    @State private var newProject = false
    @State private var newProjectName: String = ""
    
    var body: some View {
        NavigationStack{
            ScrollView{
                ForEach(projects) { project in
                    NavigationLink{
                        ProjectDetailView(project)
                    }label: {
                        AppCard{
                            HStack{
                                Text(project.title)
                                Spacer()
                            }
                        }
                    }
                }
                if projects.isEmpty {
                    Text("No Projects")
                }
            }
            .toolbar{
                ToolbarItem(placement: .primaryAction, content: {
                    Button{
                        newProject.toggle()
                    }label: {
                        Label("New Project", systemImage: "plus")
                    }
                })
            }
            .alert("New Project", isPresented: $newProject, actions: {
                TextField("Untitled Project", text: $newProjectName)
                Button(role: .cancel){
                    newProject = false
                    newProjectName = ""
                }label:{
                    Text("Cancel")
                }
                Button(role: .confirm){
                    let newModel = VideoProject(title: newProjectName)
                    modelContext.insert(newModel)
                    newProjectName = ""
                }label:{
                    Text("Create Project")
                }
            })
            .safeAreaBar(edge: .top) {
                HStack {
                    Text("Projects")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 45)
            }
        }
        .background(
            LinearGradient(
                colors: [accent.gradient.opacity(0.7), .clear],
                startPoint: .bottomTrailing,
                endPoint: .top
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    EditorView2()
        .modelContainer(for: VideoProject.self, inMemory: false)
}
