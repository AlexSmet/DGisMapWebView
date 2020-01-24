//
//  ViewController.swift
//  Example2GisApi
//
//  Created by Aleksandr Smetannikov on 27/12/2019.
//  Copyright © 2019 Aleksandr Smetannikov. All rights reserved.
//

import UIKit
import MapKit
import MBProgressHUD

class ViewController: UIViewController, DGMapWebViewDelegate{

    @IBOutlet weak var mapView: DGMapWebView!

    let locationManager = LocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MBProgressHUD.showAdded(to: view, animated: true)

        mapView.loadMap(
            latitude: 55.753215,
            longitude: 37.622504,
            zoom: 14,
            minZoom: 8,
            disableClusteringAtZoom: 14,
            maxClusterRadius: 40
        )
    }

    // MARK: - События карты

    func mapLoaded() {
        print("2Gis map loaded!")
        addIcons()
        addMarkers()
        locationManager.delegate = self
        MBProgressHUD.hide(for: view, animated: true)
    }

    func mapError(_ errorMessage: String) {
        MBProgressHUD.hide(for: view, animated: true)
        print("2Gis map error: \(errorMessage)")
    }

    func mapMoved(zoom: Int, bounds mapBounds: MapBounds) {
        print("Map was moved! zoom = \(zoom), bounds = \(mapBounds)")
    }

    func clusterClicked(zoom: Int, latitude: Double, longitude: Double) {
        let alert = UIAlertController(title: nil, message: " Cluster Latitude: \(latitude) \n Longitude: \(longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func markerClicked(_ id: String, latitude: Double, longitude: Double) {
        mapView.setView(latitude: latitude, longitude: longitude)
        let alert = UIAlertController(title: nil, message: " MarkerId: \(id) \n Latitude: \(latitude) \n Longitude: \(longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: -  Добавление маркеров

    private func addIcons() {
        mapView.addIcon(id: "home", imageUrl: "https://img.icons8.com/flat_round/64/000000/home--v1.png", height: 30, width: 30)
        mapView.addIcon(id: "user", imageUrl: "https://img.icons8.com/doodle/50/000000/street-view.png", height: 30, width: 30)
        mapView.addIcon(id: "0", imageUrl: "https://img.icons8.com/flat_round/64/000000/salamander--v1.png", height: 30, width: 30)
        mapView.addIcon(id: "1", imageUrl: "https://img.icons8.com/flat_round/64/000000/owl--v1.png", height: 30, width: 30)
        mapView.addIcon(id: "2", imageUrl: "https://img.icons8.com/flat_round/64/000000/pinguin--v1.png", height: 30, width: 30)
        mapView.addIcon(id: "3", imageUrl: "https://img.icons8.com/flat_round/64/000000/lion.png", height: 30, width: 30)
        mapView.addIcon(id: "4", imageUrl: "https://img.icons8.com/flat_round/64/000000/warranty-card.png", height: 30, width: 30)
        mapView.addIcon(id: "5", imageUrl: "https://img.icons8.com/flat_round/64/000000/cap.png", height: 30, width: 30)
        mapView.addIcon(id: "6", imageUrl: "https://img.icons8.com/flat_round/64/000000/update-left-rotation.png", height: 30, width: 30)
        mapView.addIcon(id: "7", imageUrl: "https://img.icons8.com/flat_round/64/000000/youtube-play.png", height: 30, width: 30)
        mapView.addIcon(id: "8", imageUrl: "https://img.icons8.com/flat_round/64/000000/filled-like.png", height: 30, width: 30)
        mapView.addIcon(id: "9", imageUrl: "https://img.icons8.com/flat_round/64/000000/three-stars.png", height: 30, width: 30)
    }

    private func addMarkers() {
        MBProgressHUD.showAdded(to: view, animated: true)

        DispatchQueue.main.async {
             for i in 0..<1000 {
                 let lat = Double.random(in: 55.7...55.8)
                 let lng = Double.random(in: 37.4...37.8)
                 self.mapView.addMarker(id: "\(i)", iconId: "\(i%10)", latitude: lat, longitude: lng)
             }
             self.mapView.addCluster("22", latitude: 55.756111, longitude: 37.625420)
             self.mapView.addCluster("5200", latitude: 55.753570, longitude: 37.632286)
             self.mapView.addCluster("1000", latitude: 55.738538, longitude: 37.633853)
             self.mapView.addCluster("999", latitude: 55.743089, longitude: 37.561240)
             self.mapView.addCluster("9", latitude: 55.722845, longitude: 37.621493)

            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }

    // MARK: - Пользовательские действия

    @IBAction func zoomInClick(_ sender: UIButton) {
        mapView.zoomIn()
    }

    @IBAction func zoomOutClick(_ sender: UIButton) {
        mapView.zoomOut()
    }

    @IBAction func setZoomClick(_ sender: UIButton) {
        mapView.setZoom(15)
    }

    @IBAction func addMarkersClick(_ sender: UIButton) {
        addMarkers()
    }

    @IBAction func removeAllMarkersClick(_ sender: UIButton) {
        mapView.removeAllMarkers()
    }

    @IBAction func getBoundsClick(_ sender: UIButton) {
        mapView.getBounds { mapBounds in
            if let mapBounds = mapBounds {
                print("map bounds = \(mapBounds)")
            } else {
                print("map bounds unavailable")
            }
        }
    }

    @IBAction func showHomeClick(_ sender: UIButton) {
        mapView.showHome(iconId: "home", latitude: 55.738683, longitude: 37.578835)
    }

    @IBAction func hideHomeClick(_ sender: UIButton) {
        mapView.hideHome()
    }

    @IBAction func showLocationClick(_ sender: UIButton) {
        locationManager.startLocation()
    }

    @IBAction func moveLocationClick(_ sender: UIButton) {
        mapView.moveUserLocation(latitude: 55.756111, longitude: 37.625420)
    }

    @IBAction func hideLocationClick(_ sender: UIButton) {
        mapView.hideUserLocation()
    }
}


extension ViewController: LocationManagerDelegate {
    
    func locationDefined(_ userLocation: CLLocationCoordinate2D) {
        mapView.showUserLocation(iconId: "user", latitude: userLocation.latitude, longitude: userLocation.longitude)
    }

    func locationError(_ error: LocationError) {
        switch error {
        case .serviceDisabled:
            showMessageGeolocationDisabled()
        case .serviceRestricted:
            showMessageGeolocationRestricted()
        case .accessDenied:
            showOfferToAcccessGeolocation()
        default:
            print("Location error: \(error)")
        }
    }

    private func showMessageGeolocationDisabled() {
        let alertController = UIAlertController(title: "Службы геолокации отключены на устройстве", message: "Для определения Вашего местоположения нужно включить службы геолокации в настройках устройства.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Закрыть", style: .default, handler: nil))

        present(alertController, animated: true)
    }

    private func showMessageGeolocationRestricted() {
        let alertController = UIAlertController(title: "", message: "Сервисы геолокации недоступны.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Закрыть", style: .default, handler: nil))

        present(alertController, animated: true)
    }

    private func showOfferToAcccessGeolocation() {
        let alertController = UIAlertController(title: "У приложения нет доступа к службам геолокации", message: "Перейти к настройкам приложения, для включения доступа к службам геолокации?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in self?.showApplicationSettings() }))
        alertController.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }

    private func showApplicationSettings() {
        let settingUrl = URL(string: UIApplication.openSettingsURLString)
        DispatchQueue.main.async {
            UIApplication.shared.open(settingUrl!, options: [:], completionHandler: nil)
        }
    }
}
