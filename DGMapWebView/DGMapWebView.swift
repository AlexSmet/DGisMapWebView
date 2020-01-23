//
//  DGMapWebView.swift
//
//
//  Created by Aleksandr Smetannikov on 27/12/2019.
//  Copyright © 2019 Aleksandr Smetannikov. All rights reserved.
//

import Foundation
import WebKit
import MapKit

public struct MapBounds {
    var southWest: CLLocationCoordinate2D
    var northEast: CLLocationCoordinate2D

    init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.southWest = southWest
        self.northEast = northEast
    }

    init(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {
        self.southWest = CLLocationCoordinate2D(latitude: topLeft.latitude, longitude: bottomRight.longitude)
        self.northEast = CLLocationCoordinate2D(latitude: bottomRight.latitude, longitude: topLeft.longitude)
    }

    var topLeft: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: southWest.latitude, longitude: northEast.longitude)
    }

    var bottomRight: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: northEast.latitude, longitude: southWest.longitude)
    }
}

public protocol DGMapWebViewDelegate {
    /// Карта загружена
    func mapLoaded() -> Void
    /// Ошибка при загрузке карты
    func mapError(_ :String) -> Void
    /// Карта была перемещена или был изменен масштаб
    func mapMoved(zoom: Int, bounds: MapBounds) -> Void
    /// Кластер был выбран
    func clusterClicked(zoom: Int, latitude: Double, longitude: Double) -> Void
    /// Маркер был выбран
    func markerClicked(_ :String, latitude: Double, longitude: Double) -> Void
}

public class DGMapWebView: UIView, WKNavigationDelegate {
    private var webView: WKWebView!

    public var delegate: DGMapWebViewDelegate?

    public var userLocationIconUrl: String?

    private var initLatitude: Double!
    private var initLongitude: Double!
    private var initZoom: Int!
    private var minZoom: Int!
    private var disableClusteringAtZoom: Int!
    private var maxClusterRadius: Int!
    private var maxBounds: MapBounds?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self

        insertSubview(webView, at: 0)
    }

    // MARK: - Методы управления картой

    /// Инициализация карты
    public func loadMap(latitude: Double, longitude: Double, zoom: Int = 14, minZoom: Int = 8, disableClusteringAtZoom: Int = 14, maxClusterRadius: Int = 80, maxBounds: MapBounds? = nil) {
        self.initLatitude = latitude
        self.initLongitude = longitude
        self.initZoom = zoom
        self.minZoom = minZoom
        self.disableClusteringAtZoom = disableClusteringAtZoom
        self.maxClusterRadius = maxClusterRadius
        self.maxBounds = maxBounds

        let bundle = Bundle(for: DGMapWebView.self)
        guard let fileUrl = bundle.url(forResource: "DGMap", withExtension: "html") else {
            delegate?.mapError("Ошибка при загрузке карты: нет доступа к ресурсам")
            return
        }
        let urlRequest = URLRequest(url: fileUrl)

        webView.load(urlRequest)
    }

    /// увеличение масштаба
    public func zoomIn() {
        webView.evaluateJavaScript("zoomIn()")
    }

    /// уменьшение масштаба
    public func zoomOut() {
        webView.evaluateJavaScript("zoomOut()")
    }

    /// установка заданного масштаба
    public func setZoom(_ value: Int) {
        webView.evaluateJavaScript("setZoom(\(value))")
    }

    /// получение текущего масштаба карты
    public func getZoom(completion: @escaping (Int?) -> Void) {
        webView.evaluateJavaScript("getZoom()") { (result, error) in
            guard let result = result as? NSNumber else {
                completion(nil)
                return
            }

            let zoom = Int(truncating: result)
            completion(zoom)
        }
    }

    /// получение текущих границ карты
    public func getBounds(completion: @escaping (_: MapBounds?) -> Void) {
        webView.evaluateJavaScript("getBounds()") { (result, error) in
            guard let result = result as? [NSNumber], result.count == 4 else {
                completion(nil)
                return
            }

            let mapBounds = MapBounds(southWest: CLLocationCoordinate2D(latitude: Double(truncating: result[0]), longitude: Double(truncating: result[1])),
                                                northEast: CLLocationCoordinate2D(latitude: Double(truncating: result[2]), longitude: Double(truncating: result[3])))
            completion(mapBounds)
        }
    }

    /// Проверка попадания точки в указанные границы
    public func isBoundsContains(latitude: Double, longitude: Double, complition: @escaping (_: Bool) -> Void)  {
        webView.evaluateJavaScript("boundsContains(\(latitude), \(longitude))") { (result, error) in
            guard let result = result as? Int else {
                return complition(false)
            }

            return complition(result == 1)
        }
    }

    /// Позиционирование с центром в указанных координатах
    public func setView(latitude: Double, longitude: Double, zoom: Int? = nil) {
        if let zoom = zoom {
            webView.evaluateJavaScript("setView(\(latitude), \(longitude), \(zoom))")
        } else {
            webView.evaluateJavaScript("setView(\(latitude), \(longitude))")
        }
    }

    /// Отображение маркера "Дом"
    public func showHome(iconId: String, latitude: Double, longitude: Double) {
        webView.evaluateJavaScript("showHomeMarker(\"\(iconId)\", \(latitude), \(longitude))")
    }

    /// Скрытие маркера "Дом"
    public func hideHome() {
        webView.evaluateJavaScript("removeHomeMarker()")
    }

    /// Позиционирование пользователя в центре карты
    public func showUserLocation(iconId: String, latitude: Double, longitude: Double) {
        webView.evaluateJavaScript("showUserLocationMarker(\"\(iconId)\", \(latitude), \(longitude))")
    }

    /// Перемещение маркера пользователя
    public func moveUserLocation(latitude: Double, longitude: Double) {
        webView.evaluateJavaScript("moveUserLoactionMarker(\(latitude), \(longitude))")
    }

    /// Скрытие маркера положения пользователя на карте
    public func hideUserLocation() {
        webView.evaluateJavaScript("removeUserLocationMarker()")
    }

    /// Добавление иконки
    public func addIcon(id: String, imageUrl: String, height: Int, width: Int) {
        let js = String(format: "addIcon(\"%@\", \"%@\", %d, %d)", id, imageUrl, height, width)
        webView.evaluateJavaScript(js) { [weak self] _, error in
            if let error = error {
                self?.delegate?.mapError("Ошибка при добавлении иконки: \(error)")
            }
        }
    }

    /// Добавление кластера
    public func addCluster(_ text: String, latitude: Double, longitude: Double) {
        let js = String(format: "addCluster(\"%@\", %f, %f)", text, latitude, longitude)
        webView.evaluateJavaScript(js){ [weak self] _, error in
            if let error = error {
                self?.delegate?.mapError("Ошибка при добавлении кластера: \(error)")
            }
        }
    }

    /// Добавление маркера
    public func addMarker(id: String, iconId: String, latitude: Double, longitude: Double) {
        let js = String(format: "addMarker(\"%@\", \"%@\", %f, %f)", id, iconId, latitude, longitude)
        webView.evaluateJavaScript(js){ [weak self] _, error in
            if let error = error {
                self?.delegate?.mapError("Ошибка при добавлении маркера: \(error)")
            }
        }
    }

    /// Удаление всех маркеров
    public func removeAllMarkers() {
        webView.evaluateJavaScript("removeAllMarkers()")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        initMap()
    }

    private func initMap() {
        let mainParams = "latitude: \(initLatitude!), longitude: \(initLongitude!), zoom: \(initZoom!), minZoom: \(minZoom!), disableClusteringAtZoom: \(disableClusteringAtZoom!), maxClusterRadius: \(maxClusterRadius!)"

        var maxBoundsParams: String?
        if let maxBounds = maxBounds {
            maxBoundsParams = ", maxBoundsTopLeftLatitude: \(maxBounds.topLeft.latitude), maxBoundsTopLeftLongitude: \(maxBounds.topLeft.longitude), maxBoundsBottomRightLatitude: \(maxBounds.bottomRight.latitude), maxBoundsBottomRighLongitude: \(maxBounds.bottomRight.longitude)"
        }

        let js = String(format:"init({%@%@})", mainParams, maxBoundsParams ?? "")

        webView.evaluateJavaScript(js)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let request = navigationAction.request

        guard request.url != nil else {
            decisionHandler(.allow)
            return
        }

        let components = NSURLComponents(url: request.url!, resolvingAgainstBaseURL: false)!

        let host = components.host
        let scheme = components.scheme
        let queryItems = components.queryItems

        if host == "2gis.ru" {
            UIApplication.shared.open(request.url!)
            decisionHandler(.cancel)
            return
        }

        guard scheme == "callback" else {
            decisionHandler(.allow)
            return
        }

        switch host! {
        case "mapLoaded":
            delegate?.mapLoaded()
        case "mapUnavailable":
            delegate?.mapError("Карта недоступна")
        case "mapMoved":
            mapMoved(queryItems: queryItems)
        case "clusterClicked":
            clusterClicked(queryItems: queryItems)
        case "markerClicked":
            markerClicked(queryItems: queryItems)
        default: break
        }

        decisionHandler(.cancel)
    }

    private func mapMoved(queryItems: [URLQueryItem]?) {
        guard let queryItems = queryItems, queryItems.count == 5 else { return }

        guard let zoomString = queryItems[0].value,
              let southWestLatString = queryItems[1].value, let southWestLngString = queryItems[2].value,
              let northEastLatString = queryItems[3].value, let northEastLngString = queryItems[4].value
            else { return }

        guard let zoom = Int(zoomString),
              let southWestLat = Double(southWestLatString), let southWestLng = Double(southWestLngString),
              let northEastLat = Double(northEastLatString), let northEastLng = Double(northEastLngString)
        else { return }

        let mapBounds = MapBounds(southWest: CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLng),
                                  northEast: CLLocationCoordinate2D(latitude: northEastLat, longitude: northEastLng))
        delegate?.mapMoved(zoom: zoom, bounds: mapBounds)
    }

    private func clusterClicked(queryItems: [URLQueryItem]?) {
        guard let queryItems = queryItems, queryItems.count == 3 else { return }
        guard let zoomString = queryItems[0].value, let latitudeString = queryItems[1].value, let longitudeString = queryItems[2].value else { return }
        guard let zoom = Int(zoomString), let latitude = Double(latitudeString), let longitude = Double(longitudeString) else { return }

        delegate?.clusterClicked(zoom: zoom, latitude: latitude, longitude: longitude)
    }

    private func markerClicked(queryItems: [URLQueryItem]?) {
        guard let queryItems = queryItems, queryItems.count == 3 else { return }
        guard let markerId = queryItems[0].value, let latitudeString = queryItems[1].value, let longitudeString = queryItems[2].value else { return }
        guard let latitude = Double(latitudeString), let longitude = Double(longitudeString) else { return }

        delegate?.markerClicked(markerId, latitude: latitude, longitude: longitude)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.mapError("Ошибка при загрузке карты")
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegate?.mapError("Ошибка при загрузке карты")
    }
}
