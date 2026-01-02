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
    @State var maxread: Int = 3600
    @State var showAlert:Bool = false
    @State var peris: [CBPeripheral] = []
    @State var names: [String] = []
    @State var name: String = "MPY ESP32"
    @State var selectedPeri: CBPeripheral? = nil
    @State var Seg: Double = 5.0
    @State var lastdate: String = ""
    @FocusState private var nameIsFocused: Bool
    
    
    var body: some View {
        VStack{
            
            Text("Monitoreo de PM").bold()
                .padding(10)
            
            HStack{
                Button("RetraerTeclado") {
                    nameIsFocused = false
                }.foregroundStyle(Color.letraBott)
                    .padding(10)
                    .background(Color.bkBott)
                    .cornerRadius(5)
                    .frame(maxWidth: 135, maxHeight: 25, alignment: .trailing)
            }.frame(maxWidth: 135, maxHeight: 25, alignment: .trailing)
            HStack {
                Text("Seleccione su ESP").keyboardType(.numberPad).padding(10)
                    .background(.bkLetr.opacity(0.3))
                    .cornerRadius(5)
                    .foregroundStyle(Color.letra)
                Picker("Selecciona un dispositivo:", selection: $name) {
                    ForEach(names, id: \.self) { name in
                        Text(name).tag(name) }
                }.pickerStyle(.menu)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            HStack (spacing: 20){
                Text("Inserte el no de seg entre mediciones").keyboardType(.numberPad).padding(10)
                    .background(.bkLetr.opacity(0.3))
                    .cornerRadius(5)
                    .foregroundStyle(Color.letra)
                TextField("", value: $Seg, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3))
                    .cornerRadius(5).focused($nameIsFocused).frame(maxWidth: 40, maxHeight: .infinity)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            HStack{
                VStack (spacing: 20) {
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
                    }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
                    
                    Button("Stop meditions") {
                        
                        recvData.sign = "Stop"
                        fin = "- -"
                        recvData.TimerToggle(seg: Seg)
                    }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
                }
                Text(fin).foregroundStyle(.resul)
                
            }.frame(maxWidth: .infinity, minHeight: 120)
            
            //Text("\(coordinates.lat)")
            //Text("\(coordinates.lon)")
            //Text(sta)
            
            HStack (spacing: 20){
                Text("Si su ESP no aparece, presione Reset").keyboardType(.numberPad).padding(10)
                    .background(.bkLetr.opacity(0.3))
                    .cornerRadius(5)
                    .foregroundStyle(Color.letra)
                Button("Reset Bluetooth") {
                    recvData.sign = "Start"
                    fin = "Resetting..."
                    recvData.restart()
                    fin = "Wait and press initiate"
                }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
            }.frame(maxWidth: 300, maxHeight: .infinity, alignment: .center)
            
            HStack (spacing: 20){
                Text("Inserte el numero de mediciones a graficar (Max Todas las del dia)").keyboardType(.numberPad).padding(10)
                    .background(.bkLetr.opacity(0.3))
                    .cornerRadius(5)
                    .foregroundStyle(Color.letra)
                TextField("", value: $maxread, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3))
                    .cornerRadius(5).focused($nameIsFocused).frame(maxWidth: 80, maxHeight: .infinity)
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            NavigationStack{
                NavigationLink(destination:{MapView(fn: fn, maxread: $maxread)}){
                    Text("Mapa")
                }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
                
                NavigationLink(destination:{MenuArchView(maxread: $maxread)}){
                    Text("Archivo")
                }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
        }.onAppear {
            observe()
            
        }.alert("PM peligroso", isPresented: $showAlert) { // Binds to the state variable
            Button("OK") {
                // Action to perform when dismissed (optional)
            }
        } message: {
            Text(fin)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(.bkGnd)
    }
    
    func writeToHist(msg: Data, fname: String) -> Bool{
        print("writeToHist")
        let Dir: URL = DocDir()
        let file: URL = Dir.appendingPathComponent(fname)
        do {
            let fileHandle = try FileHandle(forWritingTo: file)
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            let currdate = String(String(data: msg, encoding: .utf8)!.split(separator: ",").first!)
            //print(lastdate)
            //print(currdate)
            if currdate == lastdate{
                return true
            }
            try fileHandle.write(contentsOf: msg)
            lastdate = currdate
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
                print(FIN)
                if (FIN.split(separator: ",").count >= 2){
                    var dt = formattedTime()
                    var lat = "\(self.coordinates.lat)"
                    var lon = "\(self.coordinates.lon)"
                    print(lat)
                    if (lat != "\(0.0)") || (lon != "\(0.0)") {
                        var todo = "\(dt),\(lat),\(lon),\(FIN)\n"
                        self.fin = "\(dt)\n\(lat)\n\(lon)\nPM10: \(FIN.split(separator: ",")[0])     PM2.5: \(FIN.split(separator: ",")[1])\n"
                        print("written to file?: \(writeToHist(msg: todo.data(using: .utf8)!, fname: fn)) \(fn)")
                        if ((Int(FIN.split(separator: ",")[0])!) > 100){
                            self.showAlert = true
                            feedback.impactOccurred()
                            let systemSoundID: SystemSoundID = 1016
                            AudioServicesPlaySystemSound(systemSoundID)
                        }
                    }
                } else {
                    if (FIN != nil){
                        fin = FIN
                        print("\(FIN)")
                    }
                }
            }
            .store(in: &tokens)
    }
}
