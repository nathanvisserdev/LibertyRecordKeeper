//
//  SVMonitor.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-17.
//

import Foundation
import SwiftUI

struct ThirtyPercentOfSpaceView: View {
    var body: some View {
        Text("30% Space View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
    }
}

#Preview {
    ThirtyPercentOfSpaceView()
}
