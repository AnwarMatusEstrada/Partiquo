import Foundation
import CoreBluetooth
import SwiftUI
internal import Combine
import CoreLocation
import AVFoundation

let letTam : CGFloat = 18

struct Conf: Codable, Equatable {
    
    var pm2_5C = true
    var pm10C = true
    
    var pm1 = false
    var pm2_5 = false
    var pm4 = false
    var pm10 = false
    
    var cn0_5 = false
    var cn1 = false
    var cn2_5 = false
    var cn4 = false
    var cn10 = false
    
    var psize = false

    init() {}

    enum CodingKeys: String, CodingKey {
        case pm2_5C, pm10C
        case pm1, pm2_5, pm4, pm10
        case cn0_5, cn1, cn2_5, cn4, cn10
        case psize
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pm2_5C = try c.decodeIfPresent(Bool.self, forKey: .pm2_5C) ?? true
        pm10C  = try c.decodeIfPresent(Bool.self, forKey: .pm10C)  ?? true

        pm1    = try c.decodeIfPresent(Bool.self, forKey: .pm1)    ?? false
        pm2_5  = try c.decodeIfPresent(Bool.self, forKey: .pm2_5)  ?? false
        pm4    = try c.decodeIfPresent(Bool.self, forKey: .pm4)    ?? false
        pm10   = try c.decodeIfPresent(Bool.self, forKey: .pm10)   ?? false

        cn0_5  = try c.decodeIfPresent(Bool.self, forKey: .cn0_5)  ?? false
        cn1    = try c.decodeIfPresent(Bool.self, forKey: .cn1)    ?? false
        cn2_5  = try c.decodeIfPresent(Bool.self, forKey: .cn2_5)  ?? false
        cn4    = try c.decodeIfPresent(Bool.self, forKey: .cn4)    ?? false
        cn10   = try c.decodeIfPresent(Bool.self, forKey: .cn10)   ?? false

        psize  = try c.decodeIfPresent(Bool.self, forKey: .psize)  ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(pm2_5C, forKey: .pm2_5C)
        try c.encode(pm10C,  forKey: .pm10C)

        try c.encode(pm1,   forKey: .pm1)
        try c.encode(pm2_5, forKey: .pm2_5)
        try c.encode(pm4,   forKey: .pm4)
        try c.encode(pm10,  forKey: .pm10)

        try c.encode(cn0_5, forKey: .cn0_5)
        try c.encode(cn1,   forKey: .cn1)
        try c.encode(cn2_5, forKey: .cn2_5)
        try c.encode(cn4,   forKey: .cn4)
        try c.encode(cn10,  forKey: .cn10)

        try c.encode(psize, forKey: .psize)
    }
}

extension Conf: RawRepresentable {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Conf.self, from: data)
        else { return nil }
        self = result
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8)
        else { return "{}" }
        return string
    }
}

struct DevicePicker: View {
    let names: [CBPeripheral]
    @Binding var selection: CBPeripheral?
    @State private var isOpen = false
    
    var body: some View {
        Button {
            isOpen.toggle()
        } label: {
            HStack {
                Text(selection?.name ?? "Seleccione dispositivo")
                Image(systemName: "chevron.up.chevron.down")
            }.foregroundStyle(Color.letraBott).padding(5).background(Color.bkBott).cornerRadius(5).font(.system(size: letTam)).padding(20)
        }
        .popover(isPresented: $isOpen) {
            List(names, id: \.identifier) { peri in
                Button(peri.name ?? "Unknown") {
                    selection = peri
                    isOpen = false
                }.foregroundStyle(Color.black).padding(5).background(Color.clear).cornerRadius(5).font(.system(size: letTam))
            }
            .frame(minWidth: 220, minHeight: 600)
            .presentationCompactAdaptation(.popover)
        }
    }
}

func DocDir() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    print(paths)
    return paths[0]
}



struct BLETestView: View {
    
    //@StateObject private var ble: BLE = BLE()
    @StateObject var recvData = BLE.shared
    
    //@State var sta: String = ""
    @State var fin: String = ""
    
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    
    @State var tokens: Set<AnyCancellable> = []
    
    @State var fn: String = "default.csv"
    
    @AppStorage("NoMedicGraph") private var maxread: Int = 3600

//    @State var names: [String] = []
//    @State var name: String = ""
    @State var peris: [CBPeripheral] = []
    @State var selectedPeri: CBPeripheral? = nil
    
    @AppStorage("IntervaloMin") private var Minu = 0
    @AppStorage("IntervaloSeg") private var Seg = 5
    
    @State var lastdate: String = ""
    
    @FocusState private var nameIsFocused: Bool
    
    @State private var showAlert:Bool = false
    @State var showAlert2:Bool = false
    @State var showAlert3:Bool = false
    
    @AppStorage("ConfMediciones") var conf = Conf()
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay(
                    Image("Cielo1")
                        .resizable()
                        .scaledToFill()          // keeps proportions, fills the whole area
                )
                .clipped()                       // crops the overflow
                .ignoresSafeArea()
            NavigationStack{
                
                VStack(spacing: 0){
                    HStack{
                        DevicePicker(names: peris, selection: $selectedPeri)
                        VStack{
                            NavigationLink(destination:{ConfView(conf: $conf)}){
                                Image(systemName: "gear")
                            }.foregroundStyle(Color.letraBott).background(.black, in: Circle()).font(.system(size: letTam))
                            
                            Text("Configuración").foregroundStyle(Color.letraBott).font(.system(size: letTam-3))
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    VStack{
                        Text("Si su Partiquo no aparece, presione Reset").padding(5).font(.system(size: letTam-3))
                            .background(.bkLetr.opacity(0))
                            .cornerRadius(5)
                            .foregroundStyle(.black)
                        Button("Reset") {
                            recvData.sign = "Start"
                            fin = "Resetting..."
                            recvData.restart()
                            fin = "Wait and press initiate"
                        }.foregroundStyle(Color.letraBott).padding(5).background(Color.bkBott).cornerRadius(5).font(.system(size: letTam))
                    }.frame(maxWidth: 300 )
                
                    
                    Spacer(minLength: 0)
                    
                    VStack {
                        Text("Mediciones cada: ").font(.system(size: letTam))
                            .foregroundStyle(Color.letra)
                        //                        TextField("", value: $Seg, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3)).font(.system(size: letTam))
                        //                            .cornerRadius(5).focused($nameIsFocused).frame(maxWidth: 40, maxHeight: .infinity)
                        //                        Text(" segundos.").font(.system(size: letTam))
                        //                            .background(.bkLetr.opacity(0))
                        //                            .cornerRadius(5)
                        //                            .foregroundStyle(Color.letra)
                        HStack{
                            Picker("Minutos", selection: $Minu) {
                                ForEach(0..<60, id: \.self) {
                                    Text("\($0)")
                                        .tag($0)
                                        .font(.system(size: letTam-3))
                                    //.background(.gray.opacity(0.75))
                                    //.cornerRadius(5)
                                        .foregroundStyle(Color.letra.opacity(0.75))
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: 70)
                            //                                .fixedSize(horizontal: true, vertical: false)
                            .clipped()
                            
                            Text("min")
                                .foregroundStyle(Color.letra.opacity(0.87))
                        
                        
                            Picker("Segundos", selection: $Seg) {
                                ForEach(2..<60, id: \.self) {
                                    Text(String(format: "%02d", $0))
                                        .tag($0)
                                        .font(.system(size: letTam-3))
                                    //.background(.gray.opacity(0.75))
                                    //.cornerRadius(5)
                                        .foregroundStyle(Color.letra.opacity(0.75))
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: 70)
//                                .fixedSize(horizontal: true, vertical: false)
                            .clipped()
                            
                            Text("seg")
                                .foregroundStyle(Color.letra.opacity(0.87))
                        }
                        
                    }.frame(maxWidth: 350, maxHeight: 150).background(.gray .opacity(0.5)).cornerRadius(20)
                    
                    Spacer(minLength: 0)
                    
                    VStack{
                        HStack (spacing: 10) {
                            Button {
                                recvData.sign = "Start"
                                fin = "iniciando..."
                                if let peri = selectedPeri {
                                    if peri.state != .connected {
                                        recvData.Conn(peri: peri)
                                        recvData.TimerToggle(seg: Double(Seg) + (Double(Minu)*60))
                                        self.showAlert3 = true
                                    } else {
                                        fin = "Dispositivo ya conectado, espere..."
                                        recvData.TimerToggle(seg: Double(Seg) + (Double(Minu)*60))
                                        self.showAlert3 = true
                                    }
                                } else {
                                    fin = "Seleccione un dispositivo valido"
                                }
                                //sta = "\(recvData.centralManager.state)"
                            } label: {
                                Label("Iniciar", systemImage: "play.fill" )
                                
                            }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5).font(.system(size: letTam))
                                .alert("Tiempo de medición", isPresented: $showAlert3) { // Binds to the state variable
                                    Button("OK") {
                                        // Action to perform when dismissed (optional)
                                    }
                                } message: {
                                    Text("Se pedirán mediciones cada \(Minu) minutos y \(Seg) segundos.").font(.system(size: letTam))
                                }
                            
                            Button {
                                recvData.sign = "Stop"
                                fin = "- -"
                                recvData.TimerToggle(seg: Double(Seg) + (Double(Minu)*60))
                            } label: {
                                Label("Detener", systemImage: "stop.fill" )
                            }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5).font(.system(size: letTam))
                        }
                    }
                        
                        
                    if fin != ""{
                        Spacer(minLength: 0)
                        Text(fin)
                            .foregroundStyle(.resul)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.8))
                            .cornerRadius(20)
                    }
                    
                    
                    //Text("\(coordinates.lat)")
                    //Text("\(coordinates.lon)")
                    //Text(sta)
                    
                    
                    Spacer(minLength: 0)
                    
                    HStack{
                        Button("Mapa"){
                            self.showAlert2 = true
                        }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5).font(.system(size: letTam))
                            .alert("Inserte el numero de mediciones a graficar (Máximo Todas las del dia)", isPresented: $showAlert2) { // Binds to the state variable
                                TextField("", value: $maxread, format: .number).keyboardType(.numberPad).background(.indigo.opacity(0.3))
                                    .cornerRadius(5).focused($nameIsFocused).frame(maxWidth: 80, maxHeight:
                                            .infinity)
                                    .font(.system(size: letTam))
                                Button("Regresar") {
                                    // Action to perform when dismissed (optional)
                                }
                                NavigationLink(destination:{MapView(fn: fn, maxread: $maxread)}){
                                    Text("Vamos!").font(.system(size: letTam))
                                }
                            }
                        
                        NavigationLink(destination:{MenuArchView()}){
                            Text("Archivo").font(.system(size: letTam))
                        }.foregroundStyle(Color.letraBott).padding(10).background(Color.bkBott).cornerRadius(5)
                        
                    }.frame(maxWidth: .infinity)
                    
                }.onAppear {
                    observe()
                    
                }.alert("PM peligroso", isPresented: $showAlert) { // Binds to the state variable
                    Button("OK") {
                        // Action to perform when dismissed (optional)
                    }
                } message: {
                    Text(fin).font(.system(size: letTam))
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())          // makes empty areas tappable too
                    .onTapGesture {
                        nameIsFocused = false           // collapses the keyboard
                    }
                    .navigationTitle("Monitoreo de PM")
            }
        }
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
        }
        return false
    }
    
//    func selectDev() {
//        for p in peris{
//            if p.name == name {
//                self.selectedPeri = p
//            }
//        }
//    }
    
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
                guard !self.peris.contains(where: { $0.identifier == perif.identifier }) else { return }
                self.peris.append(perif)
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
                    let dt = formattedTime()
                    let lat = "\(self.coordinates.lat)"
                    let lon = "\(self.coordinates.lon)"
                    
                    var medicionesTrue = ""
                    let sepa = FIN.split(separator: ",")
                    if conf.pm2_5C == true {
                        medicionesTrue += "PM2.5C: \(sepa[0])"
                    }
                    if conf.pm10C == true {
                        medicionesTrue += "    PM10C: \(sepa[1])"
                    }
                    if conf.pm1 == true {
                        medicionesTrue += "\nPM1: \(sepa[2])"
                    }
                    if conf.pm2_5 == true {
                        medicionesTrue += "    PM2.5: \(sepa[3])"
                    }
                    if conf.pm4 == true {
                        medicionesTrue += "\nPM4: \(sepa[4])"
                    }
                    if conf.pm10 == true {
                        medicionesTrue += "    PM10: \(sepa[5])"
                    }
                    if conf.cn1 == true {
                        medicionesTrue += "\nCN1: \(sepa[6])"
                    }
                    if conf.cn2_5 == true {
                        medicionesTrue += "    CN2.5: \(sepa[7])"
                    }
                    if conf.cn4 == true {
                        medicionesTrue += "\nCN4: \(sepa[8])"
                    }
                    if conf.cn10 == true {
                        medicionesTrue += "    CN10: \(sepa[9])"
                    }
                    if conf.cn0_5 == true {
                        medicionesTrue += "\nCN0.5: \(sepa[10])"
                    }
                    if conf.psize == true {
                        medicionesTrue += "    PSize: \(sepa[11])\n"
                    }
                    
                    print(lat)
                    if (lat != "\(0.0)") || (lon != "\(0.0)") {
                        let todo = "\(dt),\(lat),\(lon),\(FIN)\n"
                        self.fin = "\(dt)\n\(lat)\n\(lon)\n\(medicionesTrue)"
                        print("written to file?: \(writeToHist(msg: todo.data(using: .utf8)!, fname: fn)) \(fn)")
                        if ((Float(FIN.split(separator: ",")[0])!) > 100){
                            self.showAlert = true
                            feedback.impactOccurred()
                            let systemSoundID: SystemSoundID = 1016
                            AudioServicesPlaySystemSound(systemSoundID)
                        }
                    }
                } else {
                    fin = FIN
                    print("\(FIN)")
                }
            }
            .store(in: &tokens)
    }
}

