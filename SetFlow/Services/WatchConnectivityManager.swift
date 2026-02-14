//
//  WatchConnectivityManager.swift
//  SetFlow
//

import Foundation
import Combine
import WatchConnectivity

/// Manages iPhone -> Watch communication. When a watchOS companion app is added,
/// it will receive today's workout and can send logs back. Add SetFlow Watch
/// target in Xcode, then implement WCSessionDelegate on Watch to receive data.
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendTodayWorkout(_ workout: WorkoutDay) {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(workout)
            WCSession.default.sendMessageData(data, replyHandler: nil) { _ in }
        } catch { }
    }

    func sendLogToPhone(_ log: WorkoutLog) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(log)
            WCSession.default.sendMessageData(data, replyHandler: nil) { _ in }
        } catch { }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
