//
//  SelectMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI

struct SelectMethodView: View {
    @Environment(MethodManager.self) private var methodManager

    @State private var focusedMethod: Method? = Method.allCases.first
    /// Scroll position in pages (0 = first method, 1 = second, fractional mid-swipe).
    @State private var scrollProgress: CGFloat = 0
    @State private var isHeaderCollapsed: Bool = false
    @State private var headerExpandTask: Task<Void, Never>? = nil
    
    @State private var isShowingSettingsView: Bool = false
    @State private var isShowingWhatIsAccelabView: Bool = false
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Method.allCases) { method in
                    methodPage(for: method)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $focusedMethod)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            guard geometry.containerSize.width > 0 else { return 0 }
            return (geometry.contentOffset.x + geometry.contentInsets.leading) / geometry.containerSize.width
        } action: { _, newValue in
            // Clamped so rubber-banding past the first or last page doesn't register as a swipe.
            scrollProgress = min(max(newValue, 0), CGFloat(Method.allCases.count - 1))
            
            if scrollProgress > 0.01 {
                isHeaderCollapsed = true
            }
        }
        .onScrollPhaseChange { _, newPhase in
            // Re-expand the header only once the scroll has come to rest on the first page, after a short pause.
            headerExpandTask?.cancel()
            
            guard newPhase == .idle, scrollProgress <= 0.01 else { return }
            
            headerExpandTask = Task {
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { return }
                isHeaderCollapsed = false
            }
        }
        .ignoresSafeArea()
        .sensoryFeedback(.selection, trigger: focusedMethod)
        .background { glowBackground }
        .overlay(alignment: .topLeading) {
            header
                .padding(.horizontal, 30)
                .padding(.top, 20)
        }
        .overlay(alignment: .bottom) {
            pageIndicator
                .padding(.bottom, 12)
        }
        .overlay(alignment: .bottomLeading) {
            GlassIconButton(systemImage: "questionmark", label: "What is Accelab?") {
                self.isShowingWhatIsAccelabView = true
            }
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            GlassIconButton(systemImage: "gearshape", label: "Settings") {
                self.isShowingSettingsView = true
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isShowingSettingsView) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $isShowingWhatIsAccelabView) {
            WhatIsAccelabView()
        }
    }
    
    /// Collapses into a single compact line as soon as the carousel is scrolled; expands again once it rests on the first page.
    private var header: some View {
        let layout = isHeaderCollapsed ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6)) : AnyLayout(VStackLayout(alignment: .leading))
        
        return layout {
            if !isHeaderCollapsed {
                Text("Welcome to")
                    .customFont(.title3)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .blurReplace))
            }
            
            Text("Accelab")
                .customFont(isHeaderCollapsed ? .subheadline : .largeTitle, weight: .bold)
            
            Text("Please select your method.")
                .customFont(isHeaderCollapsed ? .subheadline : .body)
                .foregroundStyle(.secondary)
        }
        .animation(.smooth, value: isHeaderCollapsed)
    }
    
    /// A stationary glow that is strongest at the centre and gone by the screen edges; each method's colour cross-fades in as its page approaches.
    private var glowBackground: some View {
        ZStack {
            ForEach(Array(Method.allCases.enumerated()), id: \.element) { index, method in
                EllipticalGradient(colors: [method.color.opacity(0.4), method.color.opacity(0.12), method.color.opacity(0)], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                    .opacity(pageWeight(for: index))
            }
        }
        .scaleEffect(1 - 0.1 * swipeAmount)
        .ignoresSafeArea()
    }
    
    private func methodPage(for method: Method) -> some View {
        VStack(spacing: 18) {
            // The fade and tilt are applied to the symbol only: glass distorts when it is faded, scaled or blurred, so the glass itself just slides.
            Image(systemName: method.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(method.color)
                .symbolEffect(.bounce, value: focusedMethod)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0)
                        .rotationEffect(.degrees(phase.value * 20))
                }
                .frame(width: 76, height: 76)
                .glassEffect(.regular, in: .circle)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    content.offset(x: phase.value * 30)
                }
            
            VStack(spacing: 6) {
                Text(method.rawValue)
                    .customFont(.title, weight: .bold)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content.offset(x: phase.value * 70)
                    }
                
                Text(method.description)
                    .customFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content.offset(x: phase.value * 130)
                    }
            }
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0)
                    .scaleEffect(phase.isIdentity ? 1 : 0.85)
                    .blur(radius: phase.isIdentity ? 0 : 6)
            }
            
            GlassButton(text: "Use \(method.rawValue)", textFont: .headline) {
                methodManager.changeMethod(to: method)
            }
            .tint(method.color)
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content.offset(x: phase.value * 190)
            }
        }
        .padding(30)
        .containerRelativeFrame([.horizontal, .vertical])
    }
    
    /// Tracks the swipe continuously: the capsules stretch and shrink with the finger rather than snapping once the page settles.
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Array(Method.allCases.enumerated()), id: \.element) { index, method in
                let weight = pageWeight(for: index)
                
                Capsule()
                    .fill(.primary.opacity(0.25 + 0.75 * weight))
                    .frame(width: 6 + 14 * weight, height: 6)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.smooth) {
                            focusedMethod = method
                        }
                    }
            }
        }
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .capsule)
        .scaleEffect(1 + 0.08 * swipeAmount)
    }
    
    /// How "current" the page at `index` is: 1 when it is centred, falling to 0 once a neighbouring page is.
    private func pageWeight(for index: Int) -> CGFloat {
        max(0, 1 - abs(scrollProgress - CGFloat(index)))
    }
    
    /// 0 when resting on a page, peaking at 1 halfway between two pages.
    private var swipeAmount: CGFloat {
        let fraction = scrollProgress - scrollProgress.rounded(.down)
        return sin(fraction * .pi)
    }
}

#Preview {
    SelectMethodView()
        .environment(MethodManager())
}
