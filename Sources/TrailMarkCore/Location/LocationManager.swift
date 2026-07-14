//
//  LocationManager.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/10/26.
//

import Foundation
import Combine
import Observation
import CoreLocation

@MainActor
@Observable

public final class LocationManager: NSObject, CLLocationManagerDelegate {
    public private(set) var authorizationStatus: CLAuthorizationStatus
    public private(set) var currentLocation: CLLocation?
    public private(set) var isRecording = false
    
    public private(set) var track: RouteTrack = RouteTrack()
    
    public let manager = CLLocationManager()
    
    public override init(){
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        
    }
    public var currentCooridanate: CLLocationCoordinate2D?{
        currentLocation?.coordinate
    }
    
    public func requestWhenInUseAuthorization(){
        manager.requestWhenInUseAuthorization()
    }
    
    public func requestOneShotLocation(){
        manager.requestLocation()
    }
    
    public func startRecording(){
        track = RouteTrack()
        isRecording = true
        manager.startUpdatingLocation()
    }
    
    public func stopRecording() -> RouteTrack{
        isRecording = false
        manager.stopUpdatingLocation()
        return track
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        Task {@MainActor in self.authorizationStatus = status}
    }
    
    nonisolated public func locationManager(_ manager:CLLocationManager, didUpldateLocation locations:[CLLocation]){
        let points = locations.map(TrackPoint.init(location:))
        let last = locations.last
        Task {
            @MainActor in
            self.currentLocation = last
            if self.isRecording{
                self.track.points.append(contentsOf: points)
        }
        }
        

    }
    nonisolated public func locationManger(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        
    }
    
}
