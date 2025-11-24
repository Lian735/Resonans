//
//  ImagePreview.swift
//  Resonans
//
//  Created by Kevin Dallian on 22/11/25.
//

import SwiftUI

struct TransparencyGrid: View {
    let size: CGFloat = 20

    var body: some View {
        Canvas { context, rect in
            let cols = Int(rect.width / size) + 2
            let rows = Int(rect.height / size) + 2

            for y in 0..<rows {
                for x in 0..<cols {
                    let isDark = (x + y).isMultiple(of: 2)
                    let color = isDark ? Color.gray.opacity(0.35) : Color.gray.opacity(0.12)
                    let rect = CGRect(x: CGFloat(x) * size,
                                      y: CGFloat(y) * size,
                                      width: size,
                                      height: size)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

struct ImagePreview: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let primary: Color
    
    let title: String
    let image: UIImage
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .typography(.displayLarge)
                Spacer()
                Button(action: {
                    HapticsManager.shared.selection()
                    dismiss()
                }) {
                    Text("Close")
                        .typography(
                            .titleSmall,
                            color: colorScheme == .dark ? .white : .black,
                            design: .rounded
                        )
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(primary.opacity(0.07))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(primary.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            ZStack {
                //Transparency grid
                
                TransparencyGrid()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .glassEffect(
                .regular,
                in: .rect(cornerRadius: AppStyle.cornerRadius)
            )
            .mask {
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius)
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
                    primary: .purple, title: "Hello",
                    image: UIImage(resource: .resonanslogo)
                )
            }
        }
    }
    
    return Preview()
}
