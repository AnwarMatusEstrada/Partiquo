import Foundation
import CoreBluetooth
internal import Combine
import CoreLocation

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CLLocationManagerDelegate, ObservableObject{
    
    var BLEPublisher = PassthroughSubject<String, Error>()
    var locationPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    
    var centralManager : CBCentralManager!
    var peripheral_s: CBPeripheral!
    
    var chara: [CBCharacteristic] = []
    @Published var sign: String = ""
    @Published var timer: Timer = Timer()
    
    required override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }


    private lazy var locationManager: CLLocationManager = {
        
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        return manager
    }()
    
    static let shared = BLE()
    
    func requestLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization( )
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func restart() {
        self.centralManager = CBCentralManager(delegate: nil, queue: nil)
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }
    
    func TimerToggle() {
        
        if sign == "Start" {
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {_ in
                self.ActivityStart()
            }
            print("Started Timer")
        }
        if sign == "Stop" {
            timer.invalidate()
            print("Invalidated Timer")
        }
    }
    
    @objc func ActivityStart() {
        if sign != "Stop" {
            while chara.isEmpty {
                print("empty chara")
            }
            let chara1 = chara.first!
            let chara2 = chara.last!
            let msg: String = "$\(sign)$"
            peripheral_s.setNotifyValue(true, for: chara1)
            peripheral_s.writeValue(msg.data(using: .utf8)!, for: chara2, type: .withResponse)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
       var consoleLog = ""

       switch central.state {
       case .poweredOff:
           consoleLog = "BLE is powered off"
       case .poweredOn:
           consoleLog = "BLE is poweredOn"
           print(consoleLog)
           Scan()
           return
       case .resetting:
           consoleLog = "BLE is resetting"
       case .unauthorized:
           consoleLog = "BLE is unauthorized"
       case .unknown:
           consoleLog = "BLE is unknown"
       case .unsupported:
           consoleLog = "BLE is unsupported"
       default:
           consoleLog = "default"
       }
        print(consoleLog)
        
    }
    
    func Scan() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //print("Scanning: \(centralManager.isScanning)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Periph. available: \(peripheral)")
        //print("ID Data:\(peripheral)")
        if ((peripheral.identifier) == UUID(uuidString: "F3DEFC13-3F91-8011-07EE-ED63B11804F7")) {
            print("ID Data:\(peripheral.identifier), \(peripheral.name!)")
            //print("\(peripheral) =? \(peripheral)")
            peripheral_s = peripheral
            peripheral_s.delegate = self
            //let FIN = "\(peripheral_s.identifier)"
            //BLEPublisher.send(FIN)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral_s: CBPeripheral) {
        print("Connected to peripheral: \(peripheral_s.name!)")
        peripheral_s.discoverServices(nil)
    }
    
    func peripheral(_ peripheral_s: CBPeripheral, didDiscoverServices  error: Error?){
        //print("Servicios: \(peripheral_s.services!)")
        //Servicios: [<CBService: 0x132f02180, isPrimary = YES, UUID = 6E400001-B5A3-F393-E0A9-E50E24DCCA9E>]
        centralManager.stopScan()
        peripheral_s.discoverCharacteristics(nil, for: peripheral_s.services!.first!)
    }
    
    func isOn() -> String{
        let sta: String = "\(centralManager.state)"
        return sta
    }
        
    func getCBUUID() -> CBUUID {
        let CBUUIDConst = CBUUID(string: "F3DEFC13-3F91-8011-07EE-ED63B11804F7")
        //print("\(CBUUIDConst)")
        return CBUUIDConst
    }
    func Conn(){
        print("Connecting")
        do {
            try centralManager.connect(peripheral_s)
        } catch {
            restart()
            self.Conn()
        }
    }
    
    func peripheral(_ peripheral_s: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        //BLEPublisher.send(service.characteristics!)
        chara = service.characteristics!
        //BLEPublisher.send(service.characteristics!)
        //publish(asgn: chara, data:service.characteristics!)
        //print("Characteristic: \(chara!)")
        //[<CBCharacteristic: 0x12e14a1c0, UUID = 6E400003-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0x12, value = (null), notifying = NO>, <CBCharacteristic: 0x12e148a80, UUID = 6E400002-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0xC, value = (null), notifying = NO>]
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            
        default:
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationPublisher.send(location.coordinate)
        //print("\(location.coordinate)")
    }
  
    func peripheral(_ peripheral_s: CBPeripheral, didUpdateValueFor chara1: CBCharacteristic, error: Error?) {
        //let datas = chara1.value
        //let byteData = Data(datas!)
        let FIN = String(data: Data(chara1.value!), encoding: .utf8)!
        BLEPublisher.send(FIN)
        //print(FIN)
        //publish(asgn: fin, data: String(data: byteData, encoding: .utf8)! )
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral_s: CBPeripheral, error: (any Error)?) {
        let FIN = "Failed to connect"
        BLEPublisher.send(FIN)
        restart()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral_s: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        let FIN = "Disconnected"
        BLEPublisher.send(FIN)
        if isReconnecting {
            Conn()
        } else {
            restart()
        }
    }
}

