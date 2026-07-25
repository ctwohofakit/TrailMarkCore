//
//  Connectivity.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/18/26.
//

import Foundation
import Observation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
@Observable
public final class ConnectivityManager: NSObject{
    public static let shared = ConnectivityManager()
    
    public private(set) var isRaachable: Bool = false
    public private(set) var isActivated: Bool = false
    public private(set) var lastError: String?
    
    //today's summary mirrored from the phone, shown in the writst
    public private(set) var mirroredSummary: ActivitySummary?

    //app-supplied sinks. the app wires these once at launch
    public var onRecieveWorkout: ((WorkoutRecord) -> Void)?
    public var onReceiveJourney:((Journey) -> Void)?

    //called when a media file arrives
    public var onRecieveMediaFile:((URL, MediaMemo) -> Void)?
    
    public enum PayloadTypes: String {
        case summary, workout, journey, memo
    }
    
    #if canImport(WatchConnectivity)
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    } #endif
    
    public func activate(){
        #if canImport(WatchConnectivity)
        guard let session else {return}
        session.delegate = self
        session.activate()
        #endif
        
    }
    
    private var canSend:Bool {
        #if canImport(WatchConnectivity)
            guard let session, session.activationState == . activated else {return false}
            #if os(ios)
                return session.isPaired && session.isWatchAppInstalled
            #else
                return true
            #endif
        #else
            return false
        #endif
    }
    
    //tranfer a media dile with its metadata
    public func transfer(memo: MediaMemo ,fileURL: URL){
        #if canImport(WatchConnectivity)
        guard canSend,
              //we transdorm the DSU to json
            let data = try? JSONEncoder.trailmark.encode(memo),
            let json = String(data: data, encoding: .utf8) else {return}
        session?.transferFile(fileURL, metadata: [
            "type": PayloadTypes.memo.rawValue,
            "memo": json
        ])
        #endif
    }
    public func send<T: Encodable>(_ type: PayloadTypes, encoding value: T) {
        #if canImport(WatchConnectivity)
        guard canSend, let data = try? JSONEncoder.trailmark.encode(value) else {return}
        session?.transferUserInfo([
            "type": type.rawValue,
            "payload": data
        ])
        #endif
    }
    
    public func sync(workout: WorkoutRecord){
        send(.workout, encoding: workout)
    }
    
    public func sync(journey: Journey){
        send(.journey, encoding: journey)
    }
    public func sync(summary: ActivitySummary){
        #if canImport(WatchConnectivity)
        guard canSend, let data = try? JSONEncoder.trailmark.encode(summary) else {return}
        try? session?.updateApplicationContext( [
            "type": PayloadTypes.summary.rawValue,
            "payload": data
        ])
        #endif
    }
    
    
}

#if canImport(WatchConnectivity)
extension ConnectivityManager: WCSessionDelegate {
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?){
        let message = error?.localizedDescription
        Task{@MainActor in
            self.isActivated = (state == .activated)
            self.lastError = message
        }
    }
    nonisolated public func sessionReachablilityDidChange(_ session: WCSession){
        let reachable = session.isReachable
        Task {@MainActor in self.isRaachable = reachable}
    }
    
    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]){
        handler(dataDict: applicationContext)
    }
    
    nonisolated public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]){
        handler(dataDict: userInfo)
    }
    
    private nonisolated func handler(dataDict: [String: Any]){
        guard let typeString = dataDict["type"] as? String,
              let type = PayloadTypes(rawValue: typeString),
        let data = dataDict["payload"] as? Data else {return}
        
        Task{ @MainActor in
            switch type {
            case .summary:
                if let summary = try? JSONDecoder.trailmark.decode(ActivitySummary.self, from: data){
                    self.mirroredSummary = summary}
            case .workout:
                if let workout = try? JSONDecoder.trailmark.decode(WorkoutRecord.self, from: data){
                    self.onRecieveWorkout?(workout)}

            case .journey:
                if let journey = try? JSONDecoder.trailmark.decode(Journey.self, from: data){
                    self.onReceiveJourney?(journey)}
            case .memo:
                    break
            }
        }
    }
    
    nonisolated public func session(_ session: WCSession, dedRevceive file: WCSessionFile){
        
        
    }
    
    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession){}
    nonisolated public func sessionDidDeactivate(_ session: WCSession){
        session.activate()
    }
    #endif
    
}
#endif
