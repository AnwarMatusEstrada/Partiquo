//
//  ConfView.swift
//  Partiquo
//
//  Created by Anwar Matus Estrada on 08/11/26.
//

import SwiftUI
import MapKit


struct ConfView: View {
    
    @Binding var conf: Conf
    
    var body: some View {
        NavigationStack {
            
            Form{
                Section("Mediciones calibradas contra MiniVol"){
                    Toggle("PM2.5C", isOn: $conf.pm2_5C)
                    Toggle("PM10C", isOn: $conf.pm10C)
                }
                
                Section("Material particulado concentración de masa."){
                    Toggle("PM1", isOn: $conf.pm1)
                    Toggle("PM2.5", isOn: $conf.pm2_5)
                    Toggle("PM4", isOn: $conf.pm4)
                    Toggle("PM10", isOn: $conf.pm10)
                }
                Section("Material particulado concentración de número."){
                    Toggle("CN1", isOn: $conf.cn1)
                    Toggle("CN2.5", isOn: $conf.cn2_5)
                    Toggle("CN4", isOn: $conf.cn4)
                    Toggle("CN10", isOn: $conf.cn10)
                    Toggle("CN0.5", isOn: $conf.cn0_5)
                }
                
                Section("Tamaño típico de partícula"){
                    Toggle("PSize", isOn: $conf.psize)
                }
                
            }.navigationTitle("Configuración")
        }
    }
}
