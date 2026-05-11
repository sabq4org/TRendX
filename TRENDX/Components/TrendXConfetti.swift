//
//  TrendXConfetti.swift
//  TRENDX
//
//  Lightweight particle-based confetti used by every celebration moment
//  (gift redemption, survey completion, weekly challenge resolution).
//  No third-party dependency — just SwiftUI shapes animated with built-in
//  springs, so it ships everywhere the app does.
//

import SwiftUI

struct TrendXConfetti: View {
    var particleCount: Int = 54

    private let particles: [Particle]

    init(particleCount: Int = 54) {
        self.particleCount = particleCount
        let colors: [Color] = [
            TrendXTheme.primary, TrendXTheme.accent, TrendXTheme.success,
            TrendXTheme.aiIndigo, TrendXTheme.aiViolet,
            Color(red: 0.95, green: 0.55, blue: 0.20),
            Color(red: 0.92, green: 0.44, blue: 0.60)
        ]
        self.particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                delay: Double.random(in: 0...0.45),
                duration: Double.random(in: 1.6...2.6),
                color: colors.randomElement() ?? TrendXTheme.primary,
                size: CGFloat.random(in: 5...11),
                rotation: Double.random(in: -180...180),
                shape: Int.random(in: 0...2)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Piece(particle: p, size: geo.size)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let color: Color
        let size: CGFloat
        let rotation: Double
        let shape: Int
    }

    private struct Piece: View {
        let particle: Particle
        let size: CGSize
        @State private var animated = false

        var body: some View {
            Group {
                switch particle.shape {
                case 0:
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 1.7)
                case 1:
                    Circle().fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                default:
                    Capsule().fill(particle.color)
                        .frame(width: particle.size * 0.6, height: particle.size * 1.6)
                }
            }
            .opacity(animated ? 0.0 : 0.95)
            .position(
                x: particle.x * size.width,
                y: animated ? size.height + 40 : -20
            )
            .rotationEffect(.degrees(animated ? particle.rotation * 3 : particle.rotation))
            .onAppear {
                withAnimation(
                    .easeOut(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    animated = true
                }
            }
        }
    }
}
