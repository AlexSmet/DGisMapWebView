//
//  LocationManager.swift
//  Example2GisApi
//
//  Created by Aleksandr Smetannikov on 21/01/2020.
//  Copyright © 2020 Aleksandr Smetannikov. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case updateLocation
    case accessDenied  // доступ приложению к геолокации запрещен пользователем
    case serviceDisabled // сервис геолокации неактивен
    case locationUnknown(Error?) // не удалось определить местоположение, возможно из-за ошибки
}

protocol LocationManagerDelegate: AnyObject {
    func locationDefined(_: CLLocationCoordinate2D)
    func locationError(_: LocationError)
}

class LocationManager: NSObject, CLLocationManagerDelegate {

    private let locator: CLLocationManager

    weak var delegate: LocationManagerDelegate?

    private let accuracySteps = [
        kCLLocationAccuracyHundredMeters,
        kCLLocationAccuracyNearestTenMeters,
        kCLLocationAccuracyBestForNavigation
    ]
    private var currentAccuracyStep: Int = 0
    private var bestAccuracy: CLLocationAccuracy = Double.greatestFiniteMagnitude
    private var isLocationStarted = false

    init(locator: CLLocationManager = CLLocationManager()) {
        self.locator = locator
        super.init()
        locator.delegate = self
    }

    func findLocation() {
        isLocationStarted = true
        currentAccuracyStep = 0
        bestAccuracy = Double.greatestFiniteMagnitude
        locate()
    }

    private func locate() {
        locator.desiredAccuracy = accuracySteps[currentAccuracyStep]

        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.locationError(LocationError.serviceDisabled)
            return
        }

        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locator.requestAlwaysAuthorization()
            return
        }
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locator.requestLocation()
        } else {
            delegate?.locationError(LocationError.accessDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locate()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLocationStarted else { return }

        if let location = locations.first {
            let lastAccuracy = location.horizontalAccuracy

            if bestAccuracy >= lastAccuracy  {
                bestAccuracy = lastAccuracy
                delegate?.locationDefined(location.coordinate)
            }

            currentAccuracyStep += 1

            if currentAccuracyStep < accuracySteps.count {
                locate()
            } else {
                isLocationStarted = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationError(.locationUnknown(error))
    }
}

