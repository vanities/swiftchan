//
//  AnimatedImage.swift
//  swiftchan
//
//  Created by vanities on 10/9/21.
//

import SwiftUI
import Combine

struct AnimatedImage: View, Identifiable {
    var id = UUID()

    @State private var image: Image?
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @State private var imageIndex: Int = 0
    @State private var totalIterations: Int = Int.max
    @State private var idle: Bool = false

    private let images: [Image]
    private let interval: Double
    private let loop: Bool
    private let loopIndex: Int
    private let iterations: Int
    private let finished: (() -> Void)?

    public init(
        _ images: [Image],
        interval: Double,
        loop: Bool = false,
        loopIndex: Int = 0,
        iterations: Int = Int.max,
        finished:  (() -> Void)? = nil
    ) {
        self.images = images
        self.interval = interval
        self.loop = loop
        self.loopIndex = loopIndex
        self.iterations = iterations
        self.finished = finished

        _timer = State(initialValue: Timer.publish(every: interval, on: .main, in: .common).autoconnect())
    }

    public var body: some View {
        Group {
            image
        }
        .onReceive(timer) { _ in
            animate()
        }
    }

    private func animate() {
        idle = false

        if imageIndex < images.count {
            image = images[imageIndex]
            imageIndex += 1

            if imageIndex == images.count {
                imageIndex = loopIndex

                if totalIterations != Int.max {
                    totalIterations += 1
                }

                if !idle {
                    idle = true
                }
            }
        }
        if !loop && idle && iterations == totalIterations {
            timer.upstream.connect().cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                finished?()
            }
        }
    }
}

struct AnimatedImageView_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            AnimatedImage(
                [
                    Image(systemName: "arrowtriangle.forward"),
                    Image(systemName: "forward")
                ],
                interval: 0.2,
                loop: true
            )
                .font(.system(size: 64))
        }
    }
}
