//
//  ProgressViews.swift
//  swiftchan
//
//  Created on 9/4/22.
//

import SwiftUI

struct PausePlayCircularProgressViewStyle: ProgressViewStyle {
    var paused: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(paused ? .red : .blue, style: StrokeStyle(lineWidth: 2))
                .rotationEffect(.degrees(-90))
                .frame(width: 25)

            configuration.label
        }
    }
}

struct WhiteCircularProgressViewStyle: ProgressViewStyle {
    var strokeColor = Color.white
    var strokeWidth = 2.0

    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 50, height: 50)
        }
    }
}

struct ThreadRefreshProgressViewStyle: ProgressViewStyle {
    var paused: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(paused ? .red : .blue, style: StrokeStyle(lineWidth: 2))
                .rotationEffect(.degrees(-90))
                .frame(width: 25)

            configuration.label
        }
    }
}
