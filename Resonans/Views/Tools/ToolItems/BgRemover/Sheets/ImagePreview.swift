//
//  ImagePreview.swift
//  Resonans
//
//  Created by Kevin Dallian on 22/11/25.
//

import SwiftUI

struct ImagePreview: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let image: UIImage
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .typography(.displayLarge)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    AppCard(isMaxWidth: false) {
                        Text("Close")
                    }
                }
            }
            AppCard {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
    }
}

#Preview {
    struct Preview: View {
        @State var isPresented: Bool = true
        
        var body: some View {
            Button("Show") {
                isPresented.toggle()
            }
            .sheet(isPresented: $isPresented) {
                ImagePreview(
                    title: "Hello",
                    image: UIImage(resource: .resonanslogo)
                )
            }
        }
    }
    
    return Preview()
}
