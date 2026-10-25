//
//  MainView.swift
//  LightControl
//
//  Created by rryu on 2023/1/13.
//

import SwiftUI

struct MainView: View {
    @State private var settingsOpen: Bool  = false
    @AppStorage("lightIp") var lightIp: String = ""
    @AppStorage("lightBrightness") var lightBrightness: Double = 50
    @AppStorage("lightSpeed") var lightSpeed: Double = 50
    @AppStorage("lightTemp") var lightTemp: Double = 4400
    @State var isEditing = false
    @State var lightControl = LightControler()
    
    var body: some View {
        VStack{
            
            if (settingsOpen) {
                LightSetIp(settingsOpen: $settingsOpen, lightIp: $lightIp)
            } else {
                LightControlView(settingsOpen: $settingsOpen, lightBrightness: $lightBrightness, lightSpeed: $lightSpeed,lightTemp: $lightTemp,isEditing: $isEditing, lightControl: $lightControl, lightIp: $lightIp)
            }
            
            HStack(alignment: .center, spacing: 12) {
                
                Button {
                    if (settingsOpen){
                        withAnimation(){
                            settingsOpen.toggle()
                        }
                    } else {
                        withAnimation(){
                            settingsOpen.toggle()
                        }
                    }
                } label: {
                    Image( systemName: settingsOpen ? "chevron.backward.circle.fill" : "gear")
                        .foregroundColor(.primary)
                        .font(.title2)
                }.buttonStyle(.borderless)
                
                Spacer()
                Button {
                    withAnimation(){
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "power.circle.fill")
                        .foregroundColor(.primary)
                        .font(.title2)
                }
                .buttonStyle(.plain).help(Text("help-quit".localized))
            }
            .padding(.horizontal)
            .padding(.vertical,10)
            
        }
        .padding(10)
        .frame(width: 420)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
