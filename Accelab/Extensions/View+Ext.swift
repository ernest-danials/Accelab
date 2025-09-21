//
//  View+Ext.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

extension View {
    func alignView(to: HorizontalAlignment) -> some View {
        var result: some View {
            HStack {
                if to != .leading {
                    Spacer()
                }
                
                self
                
                if to != .trailing {
                    Spacer()
                }
            }
        }
        
        return result
    }
    
    func alignViewVertically(to: VerticalAlignment) -> some View {
        var result: some View {
            VStack {
                if to != .top {
                    Spacer()
                }
                
                self
                
                if to != .bottom {
                    Spacer()
                }
            }
        }
        
        return result
    }
    
    func customFont(_ style: Font.TextStyle, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        if weight != .regular {
            self.font(.system(style, design: design).weight(weight))
        } else {
            self.font(.system(style, design: design))
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
