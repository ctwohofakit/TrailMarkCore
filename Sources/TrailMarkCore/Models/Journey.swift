//
//  Untitled.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/10/26.
//

import Foundation
import Combine

public struct Journey: Identifiable, Hashable, Sendable, Codable{
    public let id: UUID
    public var title: String
    public var startedAt: Date
    public var eddedAt: Date?
    
    public var track: RouteTrack
    public var memosIDs: [UUID]
    public var workout:WorkoutRecord?
    
    public init(id: UUID = UUID(), title: String = "Untitled Journey", startedAt: Date=Date(), endedAt: Date=Date(), track: RouteTrack=RouteTrack(), memosIDs: [UUID] = [], workout: WorkoutRecord? = nil){
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.eddedAt = endedAt
        self.track = track
        self.memosIDs = memosIDs
        self.workout = workout
    }
    
    public var distanceMeters: Double {
        workout?.distanceMeters ?? track.distanceMeters
    }
    
    public var dateText: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: startedAt)
    }
    
}
