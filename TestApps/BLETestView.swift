import Foundation
import CoreBluetooth
import SwiftUI
internal import Combine
import CoreLocation
import AVFoundation

struct BLETestView: View {
    
    //@StateObject private var ble: BLE = BLE()
    @StateObject var recvData = BLE.shared
    
    //@State var sta: String = ""
    @State var fin: String = ""
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    @State var tokens: Set<AnyCancellable> = []
    @State var fn: String = "default.csv"
    @State var maxread: Int = 1000
    @State var showAlert:Bool = false
    @State var peris: [CBPeripheral] = []
    @State var names: [String] = []
    @State var name: String = "Seleccione un dispositivo"
    @State var selectedPeri: CBPeripheral? = nil
    @State var Seg: Double = 2.0
    @FocusState private var nameIsFocused: Bool
    
    
    var body: some View {
        VStack{
            
            HStack{
                Text("Monitoreo de PM")
                Button("RetraerTeclado") {
                    nameIsFocused = false
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Text("Seleccione su ESP").keyboardType(.numberPad).background(.gray.opacity(0.3))
                    .cornerRadius(5)
                Picker("Selecciona un dispositivo:", selection: $name) {
                    Text("\(names)")
                    ForEach(names, id: \.self) { name in
                        Text(name).tag(name) }
                }.pickerStyle(.menu).frame(width: 300, height: 100)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack{
                Text("Inserte el no de seg entre mediciones").padding(10).keyboardType(.numberPad).background(.gray.opacity(0.3))
                    .cornerRadius(5)
                TextField("", value: $Seg, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3))
                    .cornerRadius(5).focused($nameIsFocused)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack{
                VStack{
                    Button("Initiate meditions") {
                        recvData.sign = "Start"
                        selectDev()
                        if selectedPeri != nil {
                            if selectedPeri!.state != .connected {
                                selectDev()
                                recvData.Conn(peri: selectedPeri!)
                                recvData.TimerToggle(seg: Seg)
                            } else {
                                fin = "Dispositivo ya conectado"
                                recvData.TimerToggle(seg: Seg)
                            }
                        } else {
                            fin = "Seleccione un dispositivo valido"
                        }
                        //sta = "\(recvData.centralManager.state)"
                    }
                    
                    Button("Stop meditions") {
                        
                        recvData.sign = "Stop"
                        fin = "- -"
                        recvData.TimerToggle(seg: Seg)
                    }
                }
                Text(fin)

            }.frame(maxWidth: .infinity, minHeight: 120)
            
            //Text("\(coordinates.lat)")
            //Text("\(coordinates.lon)")
            //Text(sta)
            
            HStack{
                Text("Si su ESP no aparece, presione Reset").keyboardType(.numberPad).background(.gray.opacity(0.3))
                    .cornerRadius(5)
                Button("Reset Bluetooth") {
                    recvData.sign = "Start"
                    fin = "Resetting..."
                    recvData.restart()
                    fin = "Wait and press initiate"
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack{
                Text("Inserte el numero de mediciones a graficar (Max Todas las del dia)").keyboardType(.numberPad).background(.gray.opacity(0.3))
                    .cornerRadius(5)
                TextField("", value: $maxread, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3))
                    .cornerRadius(5).focused($nameIsFocused)
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            NavigationStack{
                NavigationLink(destination:{MapView(fn: fn, maxread: $maxread)}){
                    Text("Map")
                }.frame(maxWidth: .infinity, maxHeight: 15)
                
                NavigationLink(destination:{MenuArchView(maxread: $maxread)}){
                    Text("Select file")
                }.frame(maxWidth: .infinity, maxHeight: 15)

            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                
        }.onAppear {
            observe()
            recvData.requestLocationUpdates()
            
        }.alert("PM peligroso", isPresented: $showAlert) { // Binds to the state variable
            Button("OK") {
                // Action to perform when dismissed (optional)
            }
        } message: {
            Text(fin)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.bkGnd)
    }

    
    func writeToHist(msg: Data, fname: String) -> Bool{
        let Dir: URL = DocDir()
        let file: URL = Dir.appendingPathComponent(fname)
        do {
            let fileHandle = try FileHandle(forWritingTo: file)
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            try fileHandle.write(contentsOf: msg)
            return true
        } catch {
            let fileManager = FileManager.default
            let success = fileManager.createFile(atPath: file.path, contents: nil, attributes: nil)
            if !success {
                print("Error: Failed to create file at path: \(file.path)")
                return true
            }
        } catch {
            print("Not written to file: \(error)")
            return false
        }
        return false
    }
    
    func selectDev() {
        for p in peris{
            if p.name == name {
                self.selectedPeri = p
            }
        }
    }
    
    func formattedTime() -> String{
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        fn = "\(components.year!)-\(components.month!)-\(components.day!).csv"
        return "\(components.year!)-\(components.month!)-\(components.day!) \(components.hour!):\(components.minute!):\(components.second!)"
        }
    
    let feedback = UIImpactFeedbackGenerator(style: .heavy)
    
    func observe() {
        recvData.BLEDevPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { perif in
                self.peris.append(perif)
                self.names.append(perif.name ?? "Unknown")
            }
            .store(in: &tokens)
        
        recvData.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { coor in
                self.coordinates = (coor.latitude, coor.longitude)
            }
            .store(in: &tokens)
        
        recvData.BLEPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { FIN in
                var dt = formattedTime()
                var lat = "\(self.coordinates.lat)"
                var lon = "\(self.coordinates.lon)"
                var todo = "\(dt),\(lat),\(lon),\(FIN)\n"
                self.fin = "\(dt)\n\(lat)\n\(lon)\nPM10: \(FIN.split(separator: ",")[0])     PM2.5: \(FIN.split(separator: ",")[1])\n"
                if (FIN != "- -") && (FIN != "Resetting...") && (FIN != "Wait and press initiate") && (FIN != "") && ((Int(FIN.split(separator: ",")[0])!) > 150){
                    self.showAlert = true
                    feedback.impactOccurred()
                    let systemSoundID: SystemSoundID = 1016
                    AudioServicesPlaySystemSound(systemSoundID)
                }
                print("written to file?: \(writeToHist(msg: todo.data(using: .utf8)!, fname: fn)) \(fn)")
            }
            .store(in: &tokens)
    }
}
