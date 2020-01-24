//
//  LocationManager.swift
//  Example2GisApi
//
//  Created by Aleksandr Smetannikov on 21/01/2020.
//  Copyright © 2020 Aleksandr Smetannikov. All rights reserved.
//

import UIKit
import CoreLocation

enum LocationError: Error {
    case updateLocation
    case serviceDisabled   // сервис геолокации неактивен
    case serviceRestricted // пользователю ограничен доступ к сервису геолокации
    case accessDenied      // доступ приложению к геолокации запрещен пользователем
    case locationUnknown(Error?) // не удалось определить местоположение, возможно из-за ошибки
}

protocol LocationManagerDelegate: AnyObject {
    func locationDefined(_: CLLocationCoordinate2D)
    func locationError(_: LocationError)
}

class LocationManager: NSObject, CLLocationManagerDelegate {

    private let locator: CLLocationManager
    weak var delegate: LocationManagerDelegate?

    var lastLocation: CLLocation?

    init(locator: CLLocationManager = CLLocationManager()) {
        self.locator = locator
        super.init()
        locator.distanceFilter = 10
        locator.desiredAccuracy = kCLLocationAccuracyBest
        locator.delegate = self
    }

    func startLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.locationError(.serviceDisabled)
            return
        }

        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .notDetermined:
            locator.requestWhenInUseAuthorization()
        case .denied:
            delegate?.locationError(.accessDenied)
        case .restricted:
            delegate?.locationError(.serviceRestricted)
        case .authorizedAlways, .authorizedWhenInUse:
            if let lastLocation = lastLocation {
                delegate?.locationDefined(lastLocation.coordinate)
            }
            locator.startUpdatingLocation()
        }
    }

    func stopLocation() {
        locator.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if  status == .authorizedAlways || status == .authorizedWhenInUse {
            startLocation()
        } else {
            lastLocation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            lastLocation = location
            delegate?.locationDefined(lastLocation!.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationError(.locationUnknown(error))
    }
}

