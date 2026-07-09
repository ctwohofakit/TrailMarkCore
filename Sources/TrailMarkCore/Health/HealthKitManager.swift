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
    
    public private(set) var sleep : SleepSummary = .empty
    public private(set) var energyTrend: [EnergyTrendPoint] = []
    
    
    
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
    

    //build a daily active energy collection for the last 7 day using HKStatisticsCollectionQuery, then map it to chart points(EneryTrendPoint)
        public func refreshEnergyTrend() async {
      
            
        //1.check for auth sate
        //2. calculate dates for time predicate
        //3. set checked continuation and return variable
        //3.1 make the actual query
        //3.2 create the data handler/ closure
        //3.3 execute query
        //4. set dats to new property
        
        //var interal = DateComponenets()
        //interval.day = 1
        //HKStatisticsCollectionQuery(quantityType: {energy type})
        
        guard authorizationState == .authorized else { return }
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
            guard let startDay = calendar.date(byAdding: .day, value: -6, to: endDate) else {return}
      
            
            let trend: [EnergyTrendPoint] = await withCheckedContinuation{ continuation in
            var interval = DateComponents()
                interval.day = 1
            let predicate = HKQuery.predicateForSamples(withStart: startDay, end: endDate)
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDay,
                intervalComponents: interval
            )
                query.initialResultsHandler = { _, collection, _ in
                var points: [EnergyTrendPoint] = []
                collection?.enumerateStatistics(from: startDay, to: endDate) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    points.append(EnergyTrendPoint(day: stats.startDate, activeEnergyKcal: kcal))
                    
                        }
                    continuation.resume(returning: points)
                    }
                store.execute(query)
                }
            energyTrend = trend
        }

    
    
    public func refreshLastNightSleep() async {
        guard authorizationState == .authorized else {return}
        // let's define a night as the time between 6pm to 12 pm
        let calendar = Calendar.current
        let now = Date()
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let sixPmYesterday = calendar.date(byAdding: .hour, value: -18, to: noonToday) ?? now
        
        let samples : [HKCategorySample] = await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: sixPmYesterday, end: noonToday)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ){ _, results, _ in //result at this point is just an HKSample
                continuation.resume(returning: (results as? [HKCategorySample] ?? []))
            }
            store.execute(query)
        }
        let asleepValidStateRawValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        
        let total = samples.filter {asleepValidStateRawValues.contains($0.value)}.reduce(0){$0 + $1.endDate.timeIntervalSince($1.startDate)}
        
        sleep = SleepSummary(asleepSeconds: total, date: calendar.startOfDay(for: now))
        
        
        
    }
    
    public func save(_ record: WorkoutRecord, activity: HKWorkoutActivityType = .walking) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity
        
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        try await builder.beginCollection(at: record.start)
        
        var samples: [HKSample] = []
        if record.activeEnergyKcal > 0 {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: record.activeEnergyKcal)
            samples.append(HKCumulativeQuantitySample(type: distanceType, quantity: quantity, start: record.start, end: record.end))
        }
        if !samples.isEmpty{
            try await builder.addSamples(samples)
        }
        try await builder.endCollection(at: record.end)
        _ = try await builder.finishWorkout()
    }
    
    
    
    
    
}
