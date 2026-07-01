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
    public private(set) var todaySummary: ActivitySummary = .empty
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
    
    //MARK: authoization model
    //reading
    private var readTypes: Set<HKObjectType> {
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
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            //note: for privacy ios nevel tells us whether read access was granted
            //we treat the request completed as authorized and let zeroed summary stand in screen
            //
            authorizationState = .authorized
        } catch {
            authorizationState = .denied
        }
        
    }
    public func refreshToday()async{
        guard authorizationState == .authorized else {return}
        
        //create time predicate
        let calendar = Calendar.current
        let now = Date() //ISO6001 2026-06*25T17:24:12.000UTC
        let startOfDay = calendar.startOfDay(for: now) //2026-06*25T17:24:12.000UTC
        
        async let steps = getSumQuanityFromStartDate(stepsType, unit: .count(), since: startOfDay)
        async let distance = getSumQuanityFromStartDate(distanceType, unit: .meter(), since: startOfDay)
        async let energy = getSumQuanityFromStartDate(energyType, unit: .kilocalorie(), since: startOfDay)
        
        todaySummary = ActivitySummary(// from model-Activity Summary,occurance
            steps: await steps,
            distanceMeter: await distance,
            activeEnergyKcal: await energy,
            date: startOfDay
            
            
        )
        
    }
    
    
    //MARK: --HK Queries
    private func getSumQuanityFromStartDate(_ type: HKQuantityType, unit: HKUnit, since start: Date) async -> Double{
        
        return await withCheckedContinuation{ continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ){ _, stats, _ in //query, stats, error <data handler>
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0  //return 0 if nil on sumQuantity
                continuation.resume(returning: value)
            }
            
            store.execute(query)
        }
        
    }
    
    private func getLastestHeartRate() async -> Double{
        //1. option
        let unit = HKUnit.count().unitDivided(by: .minute())
        
        //        guard let heatRateType = HKQuantity.quantityType(forIdentifier: .heartRate) else { return}
        //
        return await withCheckedContinuation{ continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ){ _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: bpm)
                
            }
            store.execute(query)
            
            
        }
    }
}
