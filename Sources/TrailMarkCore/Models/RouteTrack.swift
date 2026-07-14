//
//  RouteTrack.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/10/26.
//

import Foundation
import Combine
import CoreLocation

public struct TrackPoint: Hashable, Sendable, Codable, Identifiable{
    public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var timestamp: Date
    
    public init(id: UUID = UUID(), latitude: Double, longtitude: Double, altitude:Double, timestamp: Date = Date()){
        self.id = id
        self.latitude = latitude
        self.longitude = longtitude
        self.altitude = altitude
        self.timestamp = timestamp
        
    }
    
    public init(location: CLLocation){
        self.init(
            latitude: location.coordinate.latitude,
            longtitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
    }
    
    public var coordinate: CLLocationCoordinate2D{
        CLLocationCoordinate2D(latitude:latitude, longitude: longitude)
    }
}





public struct RouteTrack: Hashable, Sendable, Codable{
    public var points: [TrackPoint]
    public init(points: [TrackPoint] = []){
        self.points = points
    }
    
    public var coordinates: [CLLocationCoordinate2D]{
        points.map(\.coordinate)
    }
    
    public var distanceMeters: Double{
        guard points.count > 1 else {return 0}
        var total: Double = 0
        for i in 1..<points.count{
            let preElement = points[i - 1]
            let currentElement = points[i]
            let a = CLLocation(latitude: preElement.latitude, longitude:  preElement.longitude)
            let b = CLLocation(latitude: currentElement.latitude, longitude:  currentElement.longitude)
            
            total += b.distance(from: a)
        }
        return total
    }
    public var isEmpty:Bool {points.isEmpty}
    
}
