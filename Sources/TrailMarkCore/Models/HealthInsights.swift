//
//  HealthInsights.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/2/26.
//

import Foundation
import Combine

public struct SleepSummary: Equatable, Sendable, Codable{
    public var asleepSeconds: TimeInterval
    public var date: Date
    
    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()){
        self.asleepSeconds = asleepSeconds
        self.date = date
    }
    public static let empty = SleepSummary()
    public var hours: Double {asleepSeconds/3600}
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: asleepSeconds) ?? "_"
    }
}

//One DAy's active energy total, for the 7-day trend chart
//uuid is not mapable
public struct EnergyTrendPoint: Equatable, Sendable, Codable, Identifiable{
    public var id: Date { day } // getter shorten form {} instead of get{day}, Date{}
    public var day: Date // start of the day
    public var activeEnergyKcal: Double
    
    public init(day: Date, activeEnergyKcal: Double){
        self.day = day
        self.activeEnergyKcal = activeEnergyKcal
    }
    
    
    
}
