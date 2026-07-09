//
//  WorkoutRecord.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/2/26.
//

import Foundation
import Combine

public struct WorkoutRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var start: Date
    public var end: Date
    public var activeEnergyKcal: Double
    public var distanceMeters: Double
    //Avg heart rate, will need heartrate sensor connected
    public var averageHeratRate: Double?
    
    public init(id:UUID = UUID(), start: Date = Date(), end: Date = Date(), activeEnergyKcal: Double = 0, distanceMeters: Double = 0, averageHeartRate: Double? = nil){
        self.id = id
        self.start = start
        self.end = end
        self.activeEnergyKcal = activeEnergyKcal
        self.distanceMeters = distanceMeters
        self.averageHeratRate = averageHeartRate
        
    }//defaults will be the id, activityEnergyKcal, distanceMeters, averageHeartRate
        
    //MARK: -computed properties
    //we need one duration computed property(end - start) use timeinterval and timeIntervalSince
    //we need another one to represent the duration (time interval) into a formatted string like "00:00:00"
    //use allowedUnits, and zeroFrormattingBehavior(recommend .pad)
    // 1. create a formatter(DateComponnentFormatter)
    //2. set the formatter option
    //3. return formatted string
    
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    
    
}
