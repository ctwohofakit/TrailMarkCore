//
//  ActivitySummary.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 6/23/26.
//

import Foundation

public struct ActivitySummary: Sendable, Equatable, Encodable, Decodable{
    
    public var steps: Double
    public var distanceMeters: Double
    public var activeEnergyKcal: Double
    public var date: Date
    
    public init(steps: Double = 0, distanceMeter:Double = 0, activeEnergyKcal: Double = 0, date: Date = Date()){
        self.steps = steps
        self.distanceMeters = distanceMeter
        self.activeEnergyKcal = activeEnergyKcal
        self.date = date
    }
    
    public static let empty = ActivitySummary()
    
    public static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
            f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
    
    public var stepsText: String {
        Self.wholeNumber.string(from: NSNumber(value: steps)) ?? "0"
    }
    
    public var activeEnergyText: String {
        let value = Self.wholeNumber.string(from: NSNumber(value: activeEnergyKcal)) ?? "0"
        return "\(value) kcal"
    }
    
    public var distanceText: String {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return f.string(from: measurement)

    }
    


}
