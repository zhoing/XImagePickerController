//
//  XMLocationManager.swift
//  channel_sp
//
//  Created by ming on 2017/10/18.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import CoreLocation

class XMLocationManager: NSObject, CLLocationManagerDelegate {
    public static let manager = XMLocationManager()

    private lazy var locationManager = CLLocationManager()
    private var success: ((CLLocation) -> Void)?
    private var failure: ((Error) -> Void)?
    private var geocode: ((Array<CLPlacemark>) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    public func startLocation(success: ((_ location: CLLocation) -> Void)? = nil, failure: ((_ error: Error) -> Void)? = nil, geocode: ((_ geocoderArray: Array<CLPlacemark>) -> Void)? ) {
        locationManager.startUpdatingLocation()
        self.success = success
        self.failure = failure
        self.geocode = geocode
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if success != nil && locations.count > 0 {
            success!(locations[0])
        }
        if geocode != nil && locations.count > 0 {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(locations[0], completionHandler: { [weak self](placemarks, error) in
                if let geocoderPlacemarks = placemarks {
                    self?.geocode!(geocoderPlacemarks)
                }
            })
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if failure != nil {
            failure!(error)
        }
    }
    
}





