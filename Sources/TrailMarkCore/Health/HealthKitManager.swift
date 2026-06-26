//
//  HealthKitManager.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 6/23/26.
//authoriztion model
import HealthKit //sdk development kit, health store is a database with engie
import Foundation
import Observation

@MainActor //main thread
@Observable
public final class HealthKitManager{
    
    //1. create enum to catch error
    public enum AuthorizationState: Equatable{
        case unknown
        case unavailable //device has no health data, eg. ipad, simulators ets
        case requesting
        case authorized
        case denied
        case notDetermined
    }
    
    //getter setter private set
    public private(set)var authorizationState: AuthorizationState = .unknown //3. create authorization state to unknow, consume can read from but canot set
    
    private let store = HKHealthStore() //2. get an instance of healthStore
    
    public init(){
        if !HKHealthStore.isHealthDataAvailable(){
            authorizationState = .unavailable
        }
    }
    
    private var stepsType: HKQuantityType{HKQuantityType(.stepCount)}
    private var distanceType: HKQuantityType{HKQuantityType(.distanceWalkingRunning)}
    private var energyType: HKQuantityType{HKQuantityType(.activeEnergyBurned) }
    private var heartRateType: HKQuantityType{HKQuantityType(.heartRate) }
    private var sleepType: HKCategoryType{HKCategoryType(.sleepAnalysis) }
    
    
    //reading
    private var readyType: Set<HKObjectType> {
        [stepsType, distanceType, energyType, heartRateType, sleepType, HKObjectType.workoutType()]
    }
    
    //send sample/write
    private var shareTypes: Set<HKSampleType>{
        [energyType, distanceType, HKObjectType.workoutType()]
    }
    
    public func requestAuthorization() async{
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return
        }
        authorizationState = .requesting
    
    
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: shareTypes)
            //note: for privacy ios nevel tells us whether read access was granted
            //we treat the request completed as authorized and let zeroed summary stand in screen
            //
            authorizationState = .authorized
        } catch {
            authorizationState = .denied
        }
    
    }
    
    
}
