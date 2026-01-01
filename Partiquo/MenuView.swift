//
//  MenuView.swift
//  TestApps
//
//  Created by Lourdes Estrada Terres on 19/12/25.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationStack{
            NavigationLink(destination:{BLETestView()}){
                Text("Partiquo")
            }
        }
    }
}

#Preview {
    MenuView()
}
