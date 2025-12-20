import Foundation
import CoreBluetooth

class BLE: NSObject, CBCentralManagerDelegate {
    
    
    var CM : CBCentralManager!
    
    required override init() {
        super.init()
        CM = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
       var consoleLog = ""

       switch central.state {
       case .poweredOff:
           consoleLog = "BLE is powered off"
       case .poweredOn:
           consoleLog = "BLE is poweredOn"
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
    
    func isOn() -> String{
        var sta: String = "\(self.CM.state)"
        return sta
    }
    
    
}

import SwiftUI

struct BLETestView: View {
    @State var sta: String = "no data"
    var body: some View {
        VStack{
            let ble = BLE()
            Button("Test BT") {
                ble.centralManagerDidUpdateState(ble.CM)
                sta = ble.isOn()

            }
            Text(sta)
        }
    }
}
