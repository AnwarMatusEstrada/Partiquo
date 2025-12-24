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
    //print("file:\(file):")
    do {
        text = try String(contentsOf: file, encoding: .utf8)
        let arr: Array = text.split(separator: "\n", omittingEmptySubsequences: true)
        let Arr = arr.suffix(maxRead)
        return Arr.joined(separator: "\n")
    } catch {
        print("Not read from file: \(file)")
        return "Not"
    }
}

struct MapView: View {
    
    @State var fn: String
    @Binding var maxread: Int
    @State var dataTodo: String = ""
    @State private var showAlert: Bool = false
    @State var Labe: String = "No data"
    @State var cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 19.294295593508572, longitude: -99.23436942957238), latitudinalMeters: 2000, longitudinalMeters: 2000))
    
    func AllMarkers(_ dataTodo: String) -> [String]{
        if dataTodo.isEmpty {
            return [""]
        }
//        var datalinea = dataTodo.split(separator: "\n")
//        var ix = 0
//        var dataLat = [String]()
//        var dataLon = [String]()
//        var pm10 = [String]()
//        var pm2_5 = [String]()
//        
//        for datan in datalinea {
//            
//            var datanarr = datan.split(separator: ",")
//            dataLat.append("\(datanarr[1])")
//            dataLon.append("\(datanarr[2])")
//            pm10.append("\(datanarr[3])")
//            pm2_5.append("\(datanarr[4])")
//            ix += 1
//        }
//
//        var i = 0
//        for (latt, lonn, PM10, PM2_5) in zip(zip(dataLat, dataLon), zip(pm10, pm2_5)).map({ ($0.0, $0.1, $1.0, $1.1) }){
//            TodoCoordinates.append("\(latt),\(lonn),\(PM10),\(PM2_5)")
//            i += 1
//        }
        var TodoCoordinates = [String]()
        for dat in dataTodo.split(separator: "\n") {
            if "\(dat)" == "Not" {
                continue
            }
            //print("\(dat)")
            let latt = dat.split(separator: ",")[1]
            let lonn = dat.split(separator: ",")[2]
            let PM10 = dat.split(separator: ",")[3]
            let PM2_5 = dat.split(separator: ",")[4]
            TodoCoordinates.append("\(latt),\(lonn),\(PM10),\(PM2_5)")
        }
        
        
        return TodoCoordinates
    }

    var body: some View {
        Map() {
            var TodoCo = AllMarkers(dataTodo)
            if TodoCo != [""] {
                ForEach(TodoCo, id: \.self) { dato in
                    var lat = dato.split(separator: ",")[0]
                    var lon = dato.split(separator: ",")[1]
                    var pm_10 = dato.split(separator: ",")[2]
                    var pm_2_5 = dato.split(separator: ",")[3]
                    var latslons = CLLocationCoordinate2D(latitude: Double(lat)!, longitude: Double(lon)!)
                    if Double(pm_10)! > 200 {
                        var Labe = "Contingencia Fase 2 (Extremo) \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "lungs.fill", coordinate: latslons).tint(Color.red)
                    }
                    if Double(pm_10)! > 175 && Double(pm_10)! <= 200 {
                        var Labe = "Contingencia Fase 1 (Peligroso) \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "lungs", coordinate: latslons).tint(Color.red)
                    }
                    if Double(pm_10)! <= 175 && Double(pm_10)! >= 150 {
                        var Labe = "Severo \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "exclamationmark.triangle.fill", coordinate: latslons).tint(Color.orange)
                    }
                    if Double(pm_10)! < 150 && Double(pm_10)! >= 80{
                        var Labe = "Moderado \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "exclamationmark.triangle", coordinate: latslons).tint(Color.yellow)
                    }
                    if Double(pm_10)! < 80 && Double(pm_10)! >= 40{
                        var Labe = "Aceptable \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "engine.emission.and.exclamationmark", coordinate: latslons).tint(Color.green)
                    }
                    if Double(pm_10)! < 40 && Double(pm_10)! >= 25{
                        var Labe = "Buena \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "checkmark.circle.trianglebadge.exclamationmark", coordinate: latslons).tint(Color.blue)
                    }
                    if Double(pm_10)! < 25{
                        var Labe = "Sin contaminación \(pm_10),\(pm_2_5)"
                        Marker(Labe, systemImage: "checkmark.circle", coordinate: latslons).tint(Color.white)
                    }
                }
            }
        }.onAppear() {
            dataTodo = readFromHist(filen: fn, maxRead: self.maxread)
        }
    }
}
