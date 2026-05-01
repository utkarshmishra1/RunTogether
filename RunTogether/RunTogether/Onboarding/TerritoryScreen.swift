//
//  TerritoryScreen.swift
//  RunTogether
//

import SwiftUI
import MapKit

// MARK: - Constants
//
// We pick a small, cleanly-gridded city block (12th Main / 100 Feet Road area in
// Indiranagar, Bangalore — well-mapped walking data). The runner traces the
// real road geometry around it; we fetch the path from MKDirections at runtime.

/// 4 intersection corners of the block, in clockwise order starting NE.
private let BLOCK_CORNERS: [CLLocationCoordinate2D] = [
    .init(latitude: 12.97265, longitude: 77.64200), // NE
    .init(latitude: 12.97265, longitude: 77.64030), // NW
    .init(latitude: 12.97155, longitude: 77.64030), // SW
    .init(latitude: 12.97155, longitude: 77.64200), // SE
]

private let MAP_CENTER: CLLocationCoordinate2D = {
    let lat = BLOCK_CORNERS.map(\.latitude).reduce(0, +) / Double(BLOCK_CORNERS.count)
    let lng = BLOCK_CORNERS.map(\.longitude).reduce(0, +) / Double(BLOCK_CORNERS.count)
    return .init(latitude: lat, longitude: lng)
}()

/// Captured rectangular territory polygon (auto-derived from block corners).
private let CAPTURE_CORNERS: [CLLocationCoordinate2D] = BLOCK_CORNERS + [BLOCK_CORNERS[0]]

/// Fallback curvy waypoints if MKDirections is unavailable (mirrors HTML behavior).
private let FALLBACK_WAYPOINTS: [CLLocationCoordinate2D] = {
    var w: [CLLocationCoordinate2D] = []
    let corners = BLOCK_CORNERS
    for i in 0..<corners.count {
        let a = corners[i]
        let b = corners[(i + 1) % corners.count]
        // Interpolate 4 substeps per side for a smoother fallback line
        for s in 0...3 {
            let t = Double(s) / 4.0
            w.append(.init(
                latitude: a.latitude + (b.latitude - a.latitude) * t,
                longitude: a.longitude + (b.longitude - a.longitude) * t
            ))
        }
    }
    if let first = corners.first { w.append(first) }
    return w
}()

// MARK: - Screen

struct TerritoryScreen: View {
    let activationToken: Int

    @State private var distance: Double = 0
    @State private var captured: Bool = false
    @State private var showFlash: Bool = false
    @State private var showChevronPop: Bool = false
    @State private var showToast: Bool = false
    @State private var territoryPulse: Bool = false

    @State private var mapController = TerritoryMapController()

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Capture your city").eyebrow()
                    .padding(.bottom, 10)

                Text("Run a block, own a block").headline()
                    .padding(.bottom, 10)

                Text("Loop a block to claim it. The bigger your territory, the higher you climb.")
                    .subcopy()
                    .padding(.bottom, 14)

                mapStack
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(OnboardingTheme.orange.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 12)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 70)
            .padding(.bottom, 110)
        }
        // The screen lives in the ZStack the whole time. We only kick off the
        // run when the user actually lands on it — onboarding bumps the
        // activation token whenever screen 3 becomes the current page.
        .onAppear {
            // Make sure the map is empty before the user reaches it; without
            // this, a stale partial route would flash in for one frame as
            // the screen slides into view.
            mapController.reset()
            distance = 0
            captured = false
            showFlash = false
            showChevronPop = false
            showToast = false
        }
        .onChange(of: activationToken) { _, _ in restartRun() }
    }

    private var mapStack: some View {
        ZStack(alignment: .top) {
            TerritoryMapView(controller: mapController)
                .background(Color(red: 0x05/255, green: 0x08/255, blue: 0x10/255))

            // Stat overlay
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(format: "%.2f km", distance))
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(OnboardingTheme.orange)
                        .shadow(color: OnboardingTheme.orange.opacity(0.5), radius: 8)
                    Text("DISTANCE")
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(0.8)
                        .foregroundColor(OnboardingTheme.textSoft)
                }
                Spacer()
                HStack(spacing: 6) {
                    PulseDot()
                    Text("LIVE")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(
                    Capsule().fill(OnboardingTheme.orange)
                )
                .shadow(color: OnboardingTheme.orange.opacity(0.6), radius: 7)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(OnboardingTheme.navyDeep.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 9, y: 6)
            )
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Capture flash radial
            if showFlash {
                RadialGradient(
                    colors: [OnboardingTheme.orange.opacity(0.65), .clear],
                    center: .center, startRadius: 0, endRadius: 280
                )
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Brand mark pop
            if showChevronPop {
                BrandMark(size: 96)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
            }

            // Toast
            if showToast {
                Text("Territory claimed")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [OnboardingTheme.orange, OnboardingTheme.orangeDeep],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: OnboardingTheme.orange.opacity(0.6), radius: 11, y: 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 22)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 380)
    }

    // MARK: - Animation orchestration

    private func restartRun() {
        distance = 0
        captured = false
        showFlash = false
        showChevronPop = false
        showToast = false

        mapController.reset()
        mapController.onProgress = { km in
            self.distance = km
        }
        mapController.onCaptureLoopClosed = {
            self.triggerCapture()
        }
        // Slight delay so the map has time to lay out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.mapController.startRun()
        }
    }

    private func triggerCapture() {
        withAnimation(.easeOut(duration: 0.3)) { showFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) { showFlash = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                showChevronPop = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) { showToast = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.35)) { showChevronPop = false }
        }
    }
}

// MARK: - Pulse dot

private struct PulseDot: View {
    @State private var on = false
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
            .scaleEffect(on ? 1.5 : 1)
            .opacity(on ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}

// MARK: - Map controller (drives MKMapView)

@Observable
final class TerritoryMapController {
    weak var mapView: MKMapView?
    var onProgress: ((Double) -> Void)?
    var onCaptureLoopClosed: (() -> Void)?

    private var routeCoords: [CLLocationCoordinate2D] = []
    private var routeHaloOverlay: MKPolyline?
    private var routeGlowOverlay: MKPolyline?
    private var routeCoreOverlay: MKPolyline?
    private var territoryOverlay: TerritoryPolygon?
    private var runnerAnnotation: RunnerAnnotation?

    /// The road-following path that the runner is actually tracing.
    /// Captured polygon at the end is the closed version of this path.
    private var tracedPath: [CLLocationCoordinate2D] = []

    private var stepTimer: Timer?
    private var totalKm: Double = 0
    private var captured: Bool = false

    func reset() {
        captured = false
        stepTimer?.invalidate(); stepTimer = nil
        routeCoords = []
        tracedPath = []
        guard let mapView else { return }
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        routeHaloOverlay = nil
        routeGlowOverlay = nil
        routeCoreOverlay = nil
        territoryOverlay = nil
        runnerAnnotation = nil

        // Recenter
        let camera = MKMapCamera(
            lookingAtCenter: MAP_CENTER,
            fromDistance: 700,
            pitch: 58,
            heading: -28
        )
        mapView.setCamera(camera, animated: false)
        onProgress?(0)
    }

    func startRun() {
        // Reset and place the runner at the starting corner so it doesn't sit
        // off-frame while we await the directions response.
        captured = false
        routeCoords = [BLOCK_CORNERS[0]]
        guard let mapView else { return }
        let annot = RunnerAnnotation(coordinate: BLOCK_CORNERS[0])
        runnerAnnotation = annot
        mapView.addAnnotation(annot)

        Task { @MainActor in
            let path = (try? await self.fetchRoadFollowingRoute()) ?? FALLBACK_WAYPOINTS
            self.runRunner(along: path)
        }
    }

    /// Fetch a sequence of walking-direction polylines connecting BLOCK_CORNERS
    /// in order, then concatenate them into one road-following path.
    private func fetchRoadFollowingRoute() async throws -> [CLLocationCoordinate2D] {
        var loop = BLOCK_CORNERS
        loop.append(BLOCK_CORNERS[0]) // close the loop

        var combined: [CLLocationCoordinate2D] = []
        for i in 0..<(loop.count - 1) {
            let req = MKDirections.Request()
            req.transportType = .walking
            req.source      = MKMapItem(placemark: MKPlacemark(coordinate: loop[i]))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: loop[i + 1]))
            req.requestsAlternateRoutes = false

            let response = try await MKDirections(request: req).calculate()
            guard let route = response.routes.first else {
                throw NSError(domain: "TerritoryMap", code: 1)
            }
            let pts = route.polyline.points()
            for j in 0..<route.polyline.pointCount {
                let c = pts[j].coordinate
                if let last = combined.last,
                   abs(last.latitude - c.latitude) < 1e-7,
                   abs(last.longitude - c.longitude) < 1e-7 {
                    continue
                }
                combined.append(c)
            }
        }
        guard combined.count >= 2 else {
            throw NSError(domain: "TerritoryMap", code: 2)
        }
        return combined
    }

    /// Animate the runner along the supplied coordinates (already snapped to roads).
    private func runRunner(along path: [CLLocationCoordinate2D]) {
        guard mapView != nil else { return }
        guard path.count >= 2 else { return }

        // Remember the traced path so the captured polygon matches it exactly.
        tracedPath = path

        // Reset draw state to start of new path
        routeCoords = [path[0]]
        rebuildRouteOverlays()
        runnerAnnotation?.coordinate = path[0]
        totalKm = lineLengthKm(path)
        onProgress?(0)

        let totalSegments = path.count - 1
        let TARGET_STEPS = 220.0
        let stepsPerSeg = max(1, Int(round(TARGET_STEPS / Double(totalSegments))))
        var segIdx = 0
        var progress = 0
        let startBearing: Double = -28
        let bearingDelta: Double = 45

        stepTimer = Timer.scheduledTimer(withTimeInterval: 0.032, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            guard let mapView = self.mapView else { timer.invalidate(); return }

            if segIdx >= totalSegments {
                timer.invalidate()
                self.captureLoop()
                return
            }
            let a = path[segIdx]
            let b = path[segIdx + 1]
            let t = Double(progress) / Double(stepsPerSeg)
            let pos = CLLocationCoordinate2D(
                latitude: a.latitude + (b.latitude - a.latitude) * t,
                longitude: a.longitude + (b.longitude - a.longitude) * t
            )

            self.runnerAnnotation?.coordinate = pos
            self.routeCoords.append(pos)
            self.rebuildRouteOverlays()

            let pct = (Double(segIdx) + t) / Double(totalSegments)
            self.onProgress?(pct * self.totalKm)

            let newBearing = startBearing + pct * bearingDelta
            let pitch: CGFloat = 58 + CGFloat(sin(pct * .pi)) * 4
            let camera = MKMapCamera(
                lookingAtCenter: pos,
                fromDistance: 600,
                pitch: pitch,
                heading: newBearing
            )
            mapView.setCamera(camera, animated: false)

            progress += 1
            if progress > stepsPerSeg {
                progress = 0
                segIdx += 1
            }
        }
    }

    private func rebuildRouteOverlays() {
        guard let mapView else { return }
        // Remove existing
        if let h = routeHaloOverlay { mapView.removeOverlay(h) }
        if let g = routeGlowOverlay { mapView.removeOverlay(g) }
        if let c = routeCoreOverlay { mapView.removeOverlay(c) }

        let coords = routeCoords
        guard coords.count >= 2 else {
            // Just one point — no line yet
            return
        }
        let halo = HaloPolyline(coordinates: coords, count: coords.count)
        let glow = GlowPolyline(coordinates: coords, count: coords.count)
        let core = CorePolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(halo, level: .aboveLabels)
        mapView.addOverlay(glow, level: .aboveLabels)
        mapView.addOverlay(core, level: .aboveLabels)
        routeHaloOverlay = halo
        routeGlowOverlay = glow
        routeCoreOverlay = core
    }

    private func captureLoop() {
        guard let mapView else { return }
        captured = true

        // The captured polygon = the actual road path the runner traced (closed).
        // Falls back to the rectangular block corners only if for some reason
        // the traced path is empty.
        var polygonCoords: [CLLocationCoordinate2D] = tracedPath.isEmpty
            ? (BLOCK_CORNERS + [BLOCK_CORNERS[0]])
            : tracedPath
        if let first = polygonCoords.first, let last = polygonCoords.last,
           (abs(first.latitude - last.latitude) > 1e-7 ||
            abs(first.longitude - last.longitude) > 1e-7) {
            polygonCoords.append(first)
        }

        let polygon = TerritoryPolygon(coordinates: polygonCoords, count: polygonCoords.count)
        territoryOverlay = polygon
        mapView.addOverlay(polygon, level: .aboveRoads)

        // Centroid of the traced path — used as the camera orbit pivot.
        let centerCoord = centroid(of: polygonCoords)

        var t: Double = 0
        let bearingStart = mapView.camera.heading
        let dur: Double = 3.2
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] tm in
            guard let self else { tm.invalidate(); return }
            guard let mapView = self.mapView else { tm.invalidate(); return }
            t += 1.0/30.0
            let progress = min(1, t / dur)
            let camera = MKMapCamera(
                lookingAtCenter: centerCoord,
                fromDistance: 650,
                pitch: 60,
                heading: bearingStart + 6 * t
            )
            mapView.setCamera(camera, animated: false)
            if progress >= 1 { tm.invalidate() }
        }
        _ = timer

        onCaptureLoopClosed?()
    }

    private func centroid(of coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        guard !coords.isEmpty else { return MAP_CENTER }
        let lat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let lng = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return .init(latitude: lat, longitude: lng)
    }
}

// MARK: - Custom polyline subclasses (for differentiated rendering)

private class HaloPolyline: MKPolyline {}
private class GlowPolyline: MKPolyline {}
private class CorePolyline: MKPolyline {}
private class TerritoryPolygon: MKPolygon {}

// MARK: - Runner annotation

private class RunnerAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate }
}

// MARK: - UIKit map representable

struct TerritoryMapView: UIViewRepresentable {
    var controller: TerritoryMapController

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isUserInteractionEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.showsTraffic = false
        map.pointOfInterestFilter = .excludingAll

        // Standard configuration tuned to feel close to the dark/muted reference.
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.pointOfInterestFilter = .excludingAll
        map.preferredConfiguration = config

        map.overrideUserInterfaceStyle = .dark
        map.delegate = context.coordinator

        // Initial camera
        let camera = MKMapCamera(
            lookingAtCenter: MAP_CENTER,
            fromDistance: 700,
            pitch: 58,
            heading: -28
        )
        map.setCamera(camera, animated: false)

        // Wire controller to map
        controller.mapView = map

        // Register runner annotation view
        map.register(RunnerAnnotationView.self, forAnnotationViewWithReuseIdentifier: RunnerAnnotationView.reuseId)

        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        controller.mapView = uiView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? HaloPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = UIColor(OnboardingTheme.neon).withAlphaComponent(0.35)
                r.lineWidth = 16
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            if let polyline = overlay as? GlowPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = UIColor(OnboardingTheme.orange).withAlphaComponent(0.55)
                r.lineWidth = 10
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            if let polyline = overlay as? CorePolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = UIColor(red: 1, green: 0.84, blue: 0.75, alpha: 1)
                r.lineWidth = 4
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            if let poly = overlay as? TerritoryPolygon {
                let r = MKPolygonRenderer(polygon: poly)
                r.fillColor = UIColor(OnboardingTheme.orange).withAlphaComponent(0.55)
                r.strokeColor = UIColor(OnboardingTheme.orangeGlow)
                r.lineWidth = 2.5
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is RunnerAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: RunnerAnnotationView.reuseId,
                    for: annotation
                )
                return view
            }
            return nil
        }
    }
}

// MARK: - Runner annotation view (pulsing orange dot)

private class RunnerAnnotationView: MKAnnotationView {
    static let reuseId = "RunnerAnnotationView"

    private let core = CALayer()
    private let ring = CALayer()
    private let halo = CALayer()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        backgroundColor = .clear

        halo.frame = bounds
        halo.cornerRadius = 22
        halo.backgroundColor = UIColor(OnboardingTheme.orange).withAlphaComponent(0.20).cgColor
        layer.addSublayer(halo)

        let ringSize: CGFloat = 28
        ring.frame = CGRect(x: (bounds.width - ringSize)/2, y: (bounds.height - ringSize)/2,
                            width: ringSize, height: ringSize)
        ring.cornerRadius = ringSize / 2
        ring.backgroundColor = UIColor.clear.cgColor
        ring.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        ring.borderWidth = 3
        ring.shadowColor = UIColor(OnboardingTheme.orange).cgColor
        ring.shadowRadius = 9
        ring.shadowOpacity = 0.8
        ring.shadowOffset = .zero
        layer.addSublayer(ring)

        let coreSize: CGFloat = 22
        core.frame = CGRect(x: (bounds.width - coreSize)/2, y: (bounds.height - coreSize)/2,
                            width: coreSize, height: coreSize)
        core.cornerRadius = coreSize / 2
        let gradient = CAGradientLayer()
        gradient.frame = core.bounds
        gradient.colors = [
            UIColor.white.cgColor,
            UIColor(OnboardingTheme.orange).cgColor,
            UIColor(OnboardingTheme.orangeDeep).cgColor
        ]
        gradient.locations = [0.0, 0.6, 1.0]
        gradient.cornerRadius = coreSize / 2
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        core.addSublayer(gradient)
        layer.addSublayer(core)

        startPulse()
    }

    private func startPulse() {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.35
        scale.duration = 0.7
        scale.autoreverses = true
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        halo.add(scale, forKey: "pulse-scale")

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.4
        opacity.toValue = 0.0
        opacity.duration = 0.7
        opacity.autoreverses = true
        opacity.repeatCount = .infinity
        opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        halo.add(opacity, forKey: "pulse-opacity")
    }
}

// MARK: - Distance helper

private func lineLengthKm(_ coords: [CLLocationCoordinate2D]) -> Double {
    let R = 6371.0
    var total = 0.0
    for i in 0..<(coords.count - 1) {
        let φ1 = coords[i].latitude * .pi / 180
        let φ2 = coords[i+1].latitude * .pi / 180
        let Δφ = (coords[i+1].latitude - coords[i].latitude) * .pi / 180
        let Δλ = (coords[i+1].longitude - coords[i].longitude) * .pi / 180
        let a = sin(Δφ/2) * sin(Δφ/2) +
                cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        total += 2 * R * asin(sqrt(a))
    }
    return total
}
