//
//  SVMonitor.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-17.
//

import Foundation
import SwiftUI

struct ThirtyPercentOfSpaceView: View {
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Underlying view
            Text("30% Space View")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray)

            // Draggable ControlCenterView on top
            ControlCenterView(
                controlCenterModel: ControlCenterModel(), // Directly initialize ControlCenterModel
                selectedMedia: .constant(nil)
            )
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        if dragOffset.height > 100 {
                            dragOffset = CGSize(width: 0, height: 300) // Fully reveal underlying view
                        } else {
                            dragOffset = .zero // Snap back to original position
                        }
                    }
            )
        }
    }
}

#Preview {
    ThirtyPercentOfSpaceView()
}
