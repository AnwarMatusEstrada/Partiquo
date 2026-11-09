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
        print(Arr.joined(separator: "\n"))
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
            let hora = dat.split(separator: ",")[0].split(separator: " ")[1]
            let latt = dat.split(separator: ",")[1]
            let lonn = dat.split(separator: ",")[2]
            let PM10 = dat.split(separator: ",")[4]
            let PM2_5 = dat.split(separator: ",")[3]
            
            if Double(PM10) == nil || Double(PM2_5) == nil{
                continue
            }
            
            TodoCoordinates.append("\(latt),\(lonn),\(PM2_5),\(PM10),\(hora)")
        }
        
        
        return TodoCoordinates
    }

    var body: some View {
        Map() {
            let TodoCo = AllMarkers(dataTodo)
            if TodoCo != [""] {
                ForEach(TodoCo, id: \.self) { dato in
                    let lat = dato.split(separator: ",")[0]
                    let lon = dato.split(separator: ",")[1]
                    let pm_10 = dato.split(separator: ",")[3]
                    let pm_2_5 = dato.split(separator: ",")[2]
                    let hor = dato.split(separator: ",")[4]
                    let Msize:CGFloat = 12
                    let latslons = CLLocationCoordinate2D(latitude: Double(lat)!, longitude: Double(lon)!)
                    
                    
                    if Double(pm_10)! > 213 {
                        Annotation("Extremo \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "lungs.fill")
                                .font(.system(size: Msize+8))   // works here
                                .foregroundStyle(.red)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
                    if Double(pm_10)! > 132 && Double(pm_10)! <= 213 {
                        Annotation("Peligroso \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "lungs")
                                .font(.system(size: Msize+6))   // works here
                                .foregroundStyle(.red)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
                    if Double(pm_10)! <= 132 && Double(pm_10)! >= 50 {
                        Annotation("Severo \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: Msize+4))   // works here
                                .foregroundStyle(.orange)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
                    if Double(pm_10)! < 50 && Double(pm_10)! >= 45{
                        Annotation("Moderado \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: Msize+2))   // works here
                                .foregroundStyle(.yellow)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
                    if Double(pm_10)! < 45 && Double(pm_10)! >= 25{
                        Annotation("Aceptable \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "engine.emission.and.exclamationmark")
                                .font(.system(size: Msize))   // works here
                                .foregroundStyle(.green)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }

                    if Double(pm_10)! < 25 && Double(pm_10)! >= 10{
                        Annotation("Buena \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                                .font(.system(size: Msize))   // works here
                                .foregroundStyle(.blue)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
                    if Double(pm_10)! < 10{
                        Annotation("Limpio \(pm_2_5),\(pm_10),\(hor)", coordinate: latslons) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: Msize))   // works here
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(.clear, in: Circle())
                        }
                    }
//                    if Double(pm_10)! < 10{
//                        let Labe = "Limpio \(pm_2_5),\(pm_10),\(hor)"
//                        Marker(Labe, systemImage: "checkmark.circle", coordinate: latslons).tint(Color.white)
//                    }
                }
            }
        }.onAppear() {
            dataTodo = readFromHist(filen: fn, maxRead: self.maxread)
        }
    }
}
