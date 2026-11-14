// Adapted from Vinyl's real DeckMotion controller (MIT license).
// Source: https://github.com/app-dialect/vinyl/blob/main/Sources/Vinyl/Turntable.swift
// Full license attribution is in THIRD_PARTY_NOTICES.md.
import Foundation
import Observation
@Observable
final class DeckMotion {
    /// The platter is turning or coasting.
    var spinning = true
    /// The arm is lifting, swinging or lowering.
    var armMoving = true

    @ObservationIgnored private var spin: Double = 0
    @ObservationIgnored private var speed: Double = 0
    @ObservationIgnored private var lastSpin: Date?
    @ObservationIgnored private var arm: Double?
    @ObservationIgnored private var lift: Double = 0
    @ObservationIgnored private var lastArm: Date?

    struct Pose {
        var arm: Double
        var lift: Double
    }

    static let rpm33: Double = 2 * .pi * (100.0 / 3.0) / 60.0

    func wake() {
        lastSpin = nil
        lastArm = nil
        if !spinning { spinning = true }
        if !armMoving { armMoving = true }
    }

    /// Flips an observed flag outside the current render pass, and only when it changes:
    /// re-assigning an observed value re-renders the view, which would loop forever.
    private func set(_ keyPath: ReferenceWritableKeyPath<DeckMotion, Bool>, _ value: Bool) {
        guard self[keyPath: keyPath] != value else { return }
        DispatchQueue.main.async {
            if self[keyPath: keyPath] != value { self[keyPath: keyPath] = value }
        }
    }

    func spinStep(_ date: Date, playing: Bool) -> Double {
        let dt = min(max(date.timeIntervalSince(lastSpin ?? date), 0), 0.1)
        lastSpin = date
        let omega = playing ? Self.rpm33 : 0
        speed += (omega - speed) * min(1, dt * (playing ? 1.9 : 1.1))
        if abs(omega - speed) < 0.003 { speed = omega }
        spin = (spin + speed * dt).truncatingRemainder(dividingBy: 2 * .pi)
        if !playing && speed == 0 { set(\.spinning, false) }
        return spin
    }

    func armStep(_ date: Date, playing: Bool, target: Double, rest: Double) -> Pose {
        let dt = min(max(date.timeIntervalSince(lastArm ?? date), 0), 0.1)
        lastArm = date
        var angle = arm ?? rest
        let goal = playing ? target : rest
        let gap = abs(goal - angle)
        let travelling = gap > 0.02 || (gap > 0.002 && lift > 0.05)
        if travelling {
            lift += (1 - lift) * min(1, dt * 5)
            if lift > 0.8 { angle += (goal - angle) * min(1, dt * 2.4) }
        } else {
            // Following the groove: the target creeps a fraction of a degree per second.
            angle = goal
            lift += (0 - lift) * min(1, dt * 5)
            if lift < 0.01 { lift = 0 }
        }
        arm = angle
        set(\.armMoving, travelling || lift > 0)
        return Pose(arm: angle, lift: lift)
    }
}

