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
            Image("PartiquoBk")
                .resizable()
                .scaledToFit()// adjust the size
                .frame(maxWidth: .infinity, maxHeight: .infinity)   // centers it in the screen
                .background(Color.black.ignoresSafeArea())          // background color, change as needed
                .overlay(alignment: .bottom) {
                    NavigationLink(destination:{BLETestView()}){
                        Text("Iniciar").foregroundStyle(Color.letraBott).padding(20).background(Color.bkBott).cornerRadius(20)
                    }.padding(.bottom, 80)
                }
        }
    }
}

#Preview {
    MenuView()
}
