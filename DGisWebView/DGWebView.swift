//
//  DGWebView.swift
//
//
//  Created by Aleksandr Smetannikov on 27/12/2019.
//  Copyright © 2019 Aleksandr Smetannikov. All rights reserved.
//

import Foundation
import WebKit
import MapKit

public protocol DGWebViewDelegate {
    func mapLoaded() -> Void
    func mapMoved(zoom: Float, southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) -> Void
    func mapError(_ :String) -> Void
    func markerClicked(_ :String, latitude: Float, longitude: Float) -> Void
}

public class DGWebView: UIView, WKNavigationDelegate {
    private var webView: WKWebView!

    public var delegate: DGWebViewDelegate?

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
        webView.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 13_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/15E148 Safari/604.1"

        insertSubview(webView, at: 0)
    }

    // MARK: - Методы управления картой

    /// Инициализация карты
    public func initMap() {
        let bundle = Bundle(for: DGWebView.self)
        guard let fileUrl = bundle.url(forResource: "DGMap", withExtension: "html") else {
            delegate?.mapError("Ошибка при загрузке карты: нет доступа к ресурсам")
            return
        }
        let urlRequest = URLRequest(url: fileUrl)

        webView.load(urlRequest)
    }

    public func zoomIn() {
        webView.evaluateJavaScript("zoomIn()")
    }

    public func zoomOut() {
        webView.evaluateJavaScript("zoomOut()")
    }

    public func setZoom(_ value: Int) {
        webView.evaluateJavaScript("setZoom(\(value))")
    }

    /// Позиционирование с центром в указанных координатах
    public func setView(latitude: Float, longitude: Float, zoom: Int? = nil) {
        if let zoom = zoom {
            webView.evaluateJavaScript("setView(\(latitude), \(longitude), \(zoom))")
        } else {
            webView.evaluateJavaScript("setView(\(latitude), \(longitude))")
        }
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

    /// Добавление маркера
    public func addMarker(id: String, iconId: String, latitude: Float, longitude: Float) {
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
        webView.evaluateJavaScript("initMoscow()")
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

        guard let zoom = Float(zoomString),
              let southWestLat = Double(southWestLatString), let southWestLng = Double(southWestLngString),
              let northEastLat = Double(northEastLatString), let northEastLng = Double(northEastLngString)
        else { return }

        delegate?.mapMoved(zoom: zoom, southWest: CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLng), northEast: CLLocationCoordinate2D(latitude: northEastLat, longitude: northEastLng))
    }

    private func markerClicked(queryItems: [URLQueryItem]?) {
        guard let queryItems = queryItems, queryItems.count == 3 else { return }
        guard let markerId = queryItems[0].value, let latitudeString = queryItems[1].value, let longitudeString = queryItems[2].value else { return }
        guard let latitude = Float(latitudeString), let longitude = Float(longitudeString) else { return }

        delegate?.markerClicked(markerId, latitude: latitude, longitude: longitude)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.mapError("Ошибка при загрузке карты")
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegate?.mapError("Ошибка при загрузке карты")
    }
}
