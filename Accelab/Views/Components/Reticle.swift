//
//  Reticle.swift
//  Accelab
//

import SwiftUI

/// A ring with a dot at its centre, for pointing at an exact spot on the clip without covering it.
struct Reticle: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(.black.opacity(0.5), lineWidth: 3.5)

            Circle()
                .stroke(.yellow, lineWidth: 2)

            Circle()
                .fill(.yellow)
                .stroke(.black.opacity(0.5), lineWidth: 0.5)
                .frame(width: 4, height: 4)
        }
        .frame(width: size, height: size)
    }
}
