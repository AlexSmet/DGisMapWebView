//
//  ViewController.swift
//  Example2GisApi
//
//  Created by Aleksandr Smetannikov on 27/12/2019.
//  Copyright © 2019 Aleksandr Smetannikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DGisWebViewDelegate{


    @IBOutlet weak var mapView: DGisWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.initMap()
    }

    func mapLoaded() {
        print("2Gis map loaded!")
        addIcons()
        addMarkers()
    }

    func mapError(_ errorMessage: String) {
        print("2Gis map error: \(errorMessage)")
    }

    func markerClicked(_ id: String, latitude: Float, longitude: Float) {
        mapView.setView(latitude: latitude, longitude: longitude)
        let alert = UIAlertController(title: nil, message: " MarkerId: \(id) \n Latitude: \(latitude) \n Longitude: \(longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func addIcons() {
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
        for i in 0..<200 {
            let lat = Float.random(in: 55.71...55.78)
            let lng = Float.random(in: 37.5...37.7)
            mapView.addMarker(id: "\(i)", iconId: "\(i%10)", latitude: lat, longitude: lng)
        }
        mapView.addMarker(id: "1", iconId: "0", latitude: 55.756111, longitude: 37.625420)
        mapView.addMarker(id: "2", iconId: "0", latitude: 55.753570, longitude: 37.632286)
        mapView.addMarker(id: "3", iconId: "1", latitude: 55.738538, longitude: 37.633853)
        mapView.addMarker(id: "4", iconId: "1", latitude: 55.743089, longitude: 37.561240)
        mapView.addMarker(id: "5", iconId: "9", latitude: 55.722845, longitude: 37.621493)
        mapView.addMarker(id: "6", iconId: "9", latitude: 55.738683, longitude: 37.578835)
    }

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
}

