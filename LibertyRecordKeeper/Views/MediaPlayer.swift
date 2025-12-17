//
//  MediaPlayer.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import SwiftUI
import AVKit

struct MediaPlayer: View {
    var body: some View {
        ZStack {
            Color.gray // Background color to indicate the area
                .edgesIgnoringSafeArea(.all)
            Text("Media Player")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}