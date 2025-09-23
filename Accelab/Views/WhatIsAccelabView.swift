//
//  WhatIsAccelabView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-22.
//

import SwiftUI

struct WhatIsAccelabView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Have you ever done a lab at school that requires you to collect time-distance data of a cart sliding down an air track? If you have, you would definately agree that it is a very tedious task. Setting up the air track at the right angle, recording a video with a stopwatch, writing down the distance the cart travelled at a certain point in time, and repeating this process... That's where Accelab comes in! Using your iPhone's sensors, Accelab can:")
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("⋅ Make sure that your air track is set up with the angle you chose")
                        Text("⋅ Collect the time-distance data of your cart as it travels down the air track")
                        Text("⋅ Create a CSV file with the collected data so it's easy for analysis")
                    }
                    
                    Text("In fact, Accelab is an open-source project developed by a student! You can find its source code on [GitHub](https://github.com/ernest-danials/Accelab). If you're a developer yourself, Accelab is open for contributions.")
                    
                    Text("Hope Accelab can be of use to you!")
                }
                .padding(.horizontal)
            }
            .navigationTitle("What is Accelab?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    WhatIsAccelabView()
}
