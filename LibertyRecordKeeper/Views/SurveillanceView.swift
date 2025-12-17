//
//  SurveillanceView.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-17.
//

import Foundation
import SwiftUI

struct SurveillanceView: View {
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ClusterView()
                    .frame(width: geometry.size.width * 0.32)

                LiveView()
                    .frame(width: geometry.size.width * 0.68)
            }
        }
    }
}

#Preview {
    SurveillanceView()
}
