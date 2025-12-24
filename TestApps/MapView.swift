//
//  MapView.swift
//  TestApps
//
//  Created by Lourdes Estrada Terres on 23/12/25.
//

import SwiftUI
import MapKit

func readFromHist(filen: String, maxRead: Int) -> String{
    let Dir: URL = DocDir()
    let file: URL = Dir.appendingPathComponent(filen)
    var text: String = ""
    
    do {
        text = try String(contentsOf: file, encoding: .utf8)
        let arr: Array = text.split(separator: "\n", omittingEmptySubsequences: true)
        let Arr = arr.suffix(maxRead)
        return Arr.joined(separator: "\n")
    } catch {
        print("Not read from file")
        return "Not"
    }
}

struct MapView: View {
    
    @Binding var fn: String
    @State var maxread: Int = 100
    @State var dataTodo: String = ""
    
    @State var cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 19.294295593508572, longitude: -99.23436942957238), latitudinalMeters: 2000, longitudinalMeters: 2000))
    
    func AllMarkers(_ dataTodo: String) -> [String]{
        if dataTodo.isEmpty {
            print("dataTodo is empty")
            return [""]
        }
        
        var TodoCoordinates = [String]()
        var datalinea = dataTodo.split(separator: "\n")
        print("dataline is:\n\(datalinea)")
        var ix = 0
        var dataLat = [String]()
        var dataLon = [String]()
        for datan in datalinea {
            
            var datanarr = datan.split(separator: ",")
            print("datalat1 is:\(dataLat)")
            dataLat.append("\(datanarr[1])")
            print("datalat2 is:\(dataLat)")
            dataLon.append("\(datanarr[2])")
            ix += 1
        }

        var i = 0
        for (latt, lonn) in zip(dataLat, dataLon){
            TodoCoordinates.append("\(latt),\(lonn)")
            i += 1
        }
        return TodoCoordinates
    }

    var body: some View {
        Map(initialPosition: cameraPosition) {
            var TodoCo = AllMarkers(dataTodo)
            if TodoCo != [""] {
                ForEach(TodoCo, id: \.self) { latlon in
                    var lat = latlon.split(separator: ",")[0]
                    var lon = latlon.split(separator: ",")[1]
                    var latslons = CLLocationCoordinate2D(latitude: Double(lat)!, longitude: Double(lon)!)
                    Marker("", systemImage: "person.fill", coordinate: latslons)
                }
            }
        }.onAppear() {
            dataTodo = readFromHist(filen: fn, maxRead: maxread)
        }
    }
}

