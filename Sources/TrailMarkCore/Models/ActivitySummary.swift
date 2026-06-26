//
//  ActivitySummary.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 6/23/26.
//

import Foundation

public struct ActivitySummary{
    
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
    
    
    
}
