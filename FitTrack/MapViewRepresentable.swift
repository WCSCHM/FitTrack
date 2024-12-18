import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var pathCoordinates: [CLLocationCoordinate2D]
    @Binding var userLocation: CLLocationCoordinate2D?
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        // Renderer for polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .red
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update region
        if uiView.region.center.latitude != region.center.latitude ||
            uiView.region.center.longitude != region.center.longitude {
            uiView.setRegion(region, animated: true)
        }
        
        // Update user location
        if let userLocation = userLocation {
            // Center map on user location
            uiView.setCenter(userLocation, animated: true)
        }
        
        // Update path
        if pathCoordinates.count > 1 {
            // Remove existing polylines
            let existingOverlays = uiView.overlays
            uiView.removeOverlays(existingOverlays)
            
            // Add new polyline
            let polyline = MKPolyline(coordinates: pathCoordinates, count: pathCoordinates.count)
            uiView.addOverlay(polyline)
        }
    }
}
