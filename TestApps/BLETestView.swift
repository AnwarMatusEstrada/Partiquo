import Foundation
import CoreBluetooth
import SwiftUI
internal import Combine

struct BLETestView: View {
    @StateObject private var ble: BLE = BLE()
    @State var sta: String = "no data"
    @State var cbuuid: String = "no data"
    @State var r: Bool = false
    
    var body: some View {
        VStack{
            Button("Iniciar mediciones") {
                ble.sign = "Start"
                if r == false {
                    ble.TimerToggle(peripheral_s: ble.peripheral_s)
                }
                r = true
                cbuuid = "\(ble.getCBUUID())"
                sta = "\(ble.centralManager.state)"
            }
            Text(ble.fin)
            Text(sta)
            Text(cbuuid)
            
            Button("Detener mediciones") {
                ble.sign = "Stop"
                r = false
                ble.TimerToggle(peripheral_s: ble.peripheral_s)
            }
        }
    }
}

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject{
    
    
    var centralManager : CBCentralManager!
    @Published var peripheral_s: CBPeripheral!
    
    required override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        
    }
    @Published var chara: [CBCharacteristic] = []
    @Published var sign: String = ""
    @Published var fin: String = "- -"
    @Published var timer: Timer = Timer()
    
    
    @objc func restart() {
        sign = "Start"
        self.centralManager = CBCentralManager(delegate: nil, queue: nil)
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        ActivityStart()
    }
    
    func TimerToggle(peripheral_s: CBPeripheral) {
        
        if sign == "Start" {
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {_ in
                self.Conn(peripheral_s  )
                self.ActivityStart()
            }
        }
        if sign == "Stop" {
            timer.invalidate()
        }
    }
    
    func ActivityStart() {
        var chara1 = chara.first!
        var chara2 = chara.last!
        var msg: String = "$\(sign)$"
        peripheral_s.setNotifyValue(true, for: chara1)
        peripheral_s.writeValue(msg.data(using: .utf8)!, for: chara2, type: .withResponse)
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
        print("Scanning: \(centralManager.isScanning)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Periph. available: \(peripheral)")
        //print("ID Data:\(peripheral)")
        if ((peripheral.identifier) == UUID(uuidString: "F3DEFC13-3F91-8011-07EE-ED63B11804F7")) {
            print("ID Data:\(peripheral.identifier), \(peripheral.name!)")
            //print("\(peripheral) =? \(peripheral)")
            peripheral_s = peripheral
            peripheral_s.delegate = self
            Conn(peripheral_s)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral_s: CBPeripheral) {
        print("Connected to peripheral: \(peripheral_s.name!)")
        peripheral_s.discoverServices(nil)
        
        //for i in 0...100 {
            
        //}
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
    func Conn(_ peripheral_s: CBPeripheral){
        print("Connecting")
        centralManager?.connect(peripheral_s, options: nil)
    }
    
    func peripheral(_ peripheral_s: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        chara = service.characteristics!
        //print("Characteristic: \(chara!)")
        //[<CBCharacteristic: 0x12e14a1c0, UUID = 6E400003-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0x12, value = (null), notifying = NO>, <CBCharacteristic: 0x12e148a80, UUID = 6E400002-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0xC, value = (null), notifying = NO>]
    }
  
    func peripheral(_ peripheral_s: CBPeripheral, didUpdateValueFor chara1: CBCharacteristic, error: Error?) {
        var datas = chara1.value
        var byteData = Data(datas!)
        fin = String(data: byteData, encoding: .utf8)!
        print(fin)
    }
}

