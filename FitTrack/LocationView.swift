import SwiftUI
import MapKit

struct LocationView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if let userLocation = locationManager.userLocation {
                    MapViewRepresentable(
                        region: $locationManager.region,
                        pathCoordinates: $locationManager.pathCoordinates,
                        userLocation: $locationManager.userLocation
                    )
                    .edgesIgnoringSafeArea(.all)
                } else {
                    Text("正在获取位置...")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("位置")
            .onAppear {
                locationManager.startUpdating()
            }
            .onDisappear {
                locationManager.stopUpdating()
            }
        }
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
    }
}
