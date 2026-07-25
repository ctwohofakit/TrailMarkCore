//
//  MotionManager.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/16/26.
//



import Foundation
import CoreMotion

import Combine
import Observation

@MainActor
@Observable
public final class MotionManager{
    
    public enum Activity: String, Sendable{
        case stationary, walking, running, cycling, automotive, unknown
        public var label: String {rawValue.capitalized}
        public var symbolName: String{
            switch self{
            case .stationary: return "figure.stand"
            case .walking: return "figure.walk"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .automotive: return "car.fill"
            case .unknown: return "quesitonmark"
            }
        }
    }
    public private(set) var stepsToday: Int = 0
    //current cadece in steps per min
    public private(set) var cadence: Double = 0
    public private(set) var activity: Activity = .unknown
            
    //acc magnitude(g), a simple accelerometer derived signal
    public private(set) var accelerationMagnitude: Double = 0
    public private(set) var rotationRate: (x:Double, y: Double, z: Double) = (0,0,0)
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    
    public init() {}
    
    
    public static var isAvailable: Bool{CMPedometer.isStepCountingAvailable()}
    public static var isAcitvityAvailable: Bool {CMMotionActivityManager.isActivityAvailable()}
    
    public func start(){
        startPedometer()
        startAccelerometer()
        startActivityUpdates()
    }
    
    public func stop(){
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
    
    
    private func startPedometer(){
        guard CMPedometer.isStepCountingAvailable() else {return}
        let startOfDay = Calendar.current.startOfDay(for: Date())
        //1. create handler seperately and pass it as parameter
        //weak self use inside of the clousure, if using self in the closure,
        //weak self provide the weak self reference to let the actor know
        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let data else {return}
            //NSobject is objective c to work with hardware, it need to convert
            let step = data.numberOfSteps.intValue
            //current cadence is steps/second -> steps/minute
            let cadence = (data.currentCadence?.doubleValue ?? 0) * 60
            Task{
                @MainActor in
                self?.stepsToday = step
                self?.cadence = cadence
            }
            
            
            
        }
    }
    
    private func startActivityUpdates(){
        guard CMMotionActivityManager.isActivityAvailable() else {return}
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else {return}
            let resolved: Activity
            if activity.walking{ resolved = .walking}
            else if activity.running{ resolved = .running}
            else if activity.cycling{ resolved = .cycling}
            else if activity.automotive{ resolved = .automotive}
            else { resolved = .unknown}
            
            self?.activity = resolved
        }
        
    }
    
    private func startAccelerometer(){
        guard motionManager.isDeviceMotionActive else {return}
        motionManager.deviceMotionUpdateInterval = 0.1
        
        motionManager.startDeviceMotionUpdates(to: .main){ [weak self] motion, _ in
            guard let a = motion?.userAcceleration else { return }
            self?.accelerationMagnitude = (a.x * a.x * a.y * a.y + a.z * a.z).squareRoot()
  
            guard let b = motion?.rotationRate else { return }
            self?.rotationRate = (x: b.x, y: b.y, z: b.z)
            
        }
        
        
        
    }
    
}

