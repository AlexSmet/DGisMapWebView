//
//  DGisWebView.swift
//
//
//  Created by Aleksandr Smetannikov on 27/12/2019.
//  Copyright © 2019 Aleksandr Smetannikov. All rights reserved.
//

import Foundation
import WebKit

public protocol DGisWebViewDelegate {
    func mapLoaded() -> Void
    func mapError(_ :String) -> Void
    func markerClicked(_ :String, latitude: Float, longitude: Float) -> Void
}

public class DGisWebView: UIView, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!

    public var delegate: DGisWebViewDelegate?

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
    public func initMap() {
        let bundle = Bundle(for: DGisWebView.self)
        guard let fileUrl = bundle.url(forResource: "DGisMap", withExtension: "html") else {
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
        case "markerClicked":
            if (queryItems?.count ?? 0 > 2), let markerId = queryItems?[0].value, let latitudeString = queryItems?[1].value,  let longitudeString = queryItems?[2].value {
                if let latitude = Float(latitudeString), let longitude = Float(longitudeString) {
                    delegate?.markerClicked(markerId, latitude: latitude, longitude: longitude)
                }
            }
        default: break
        }

        decisionHandler(.cancel)
    }
}
