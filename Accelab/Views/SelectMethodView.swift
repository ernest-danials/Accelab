//
//  SelectMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI

/// Where the method is chosen for the experiment chosen on the home screen. Each method is one tile, and the
/// whole tile is the button: a drawing of what is done with the iPhone, the method's name, and the graph its
/// data is for, which is where the two differ most.
struct SelectMethodView: View {
    @Environment(MethodManager.self) private var methodManager

    var body: some View {
        let experiment = methodManager.experiment

        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading) {
                StepTitleView(title: experiment.rawValue, subtitle: "Choose a method for", description: experiment.methodChoiceHint, isProminent: true, isInline: true)
                    // Where the other screens' titles are: 30 from the edges, of which `padding()` gives 16.
                    .padding([.top, .leading], 14)

                Spacer(minLength: 16)

                GlassIconButton(systemImage: "chevron.backward", label: "Back") {
                    methodManager.show(.home)
                }
            }
            .frame(maxWidth: 200, maxHeight: .infinity, alignment: .leading)

            ForEach(Method.allCases) { method in
                MethodTile(experiment: experiment, method: method) {
                    methodManager.show(.method(method))
                }
            }
        }
        .padding()
    }
}

/// One method's tile, which is the button that opens it. A method that can't do the experiment keeps its
/// tile, not glass and with its drawing and name dimmed, with the reason, left readable, where the graph and the
/// columns would be.
private struct MethodTile: View {
    let experiment: Experiment
    let method: Method
    let onChoose: () -> Void

    private static let cornerRadius: CGFloat = 28

    private var isAvailable: Bool {
        experiment.supports(method)
    }

    var body: some View {
        Button {
            Haptics.prominentTap()
            onChoose()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Drawn to one size and scaled to the room the tile has, up to a point.
                GeometryReader { geometry in
                    MethodDrawing(experiment: experiment, method: method)
                        .scaleEffect(MethodDrawing.scale(toFit: geometry.size))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .opacity(isAvailable ? 1 : 0.4)

                // "Recommended" beside the name rather than under it, so that it adds no line to one tile.
                HStack(alignment: .firstTextBaseline) {
                    Text(method.rawValue)
                        .customFont(.title2, weight: .bold)

                    Spacer(minLength: 8)

                    if isAvailable, experiment.recommendedMethod == method {
                        Text("Recommended")
                            .customFont(.footnote, weight: .medium)
                            .foregroundStyle(method.color)
                    }
                }
                .opacity(isAvailable ? 1 : 0.4)

                if isAvailable, let graph = experiment.graph(for: method), let data = experiment.emptyData(for: method) {
                    // The graph first, as it is what the lab is for; the columns it is plotted from under it.
                    GraphBlock(graph: graph, color: method.color)

                    DataColumnsStrip(data: data)
                } else {
                    // In the room the graph and the columns take on the other tile, so the drawings match.
                    Text(experiment.setup(for: method))
                        .customFont(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(height: GraphBlock.height + DataColumnsStrip.height + 6, alignment: .topLeading)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(.rect(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        // Glass because the tile is the button. None on a tile that can't be chosen: it isn't one.
        .glassEffect(isAvailable ? .regular.interactive() : .identity, in: .rect(cornerRadius: Self.cornerRadius))
        .background {
            if !isAvailable {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .accessibilityHint(experiment.setup(for: method))
    }
}

/// What students graph from the method's data, made the most prominent text on the tile after the name: a small
/// plot of the shape the points should make, beside "y against x", with what the graph gives under it.
private struct GraphBlock: View {
    let graph: ExperimentGraph
    let color: Color

    /// The same on both tiles, so that the names line up whatever the note's length.
    static let height: CGFloat = 66

    var body: some View {
        HStack(spacing: 12) {
            GraphGlyph(shape: graph.shape, color: color)
                .frame(width: 46, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .customFont(.title3, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(graph.note)
                    .customFont(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Self.height)
    }

    /// "a_c against ω²": the axes in the weight of the title, the word between them lighter.
    private var title: Text {
        var y = Text(graph.y)
        if let ySubscript = graph.ySubscript {
            y = Text("\(y)\(Text(ySubscript).font(.subheadline.weight(.semibold)).baselineOffset(-4))")
        }

        return Text("\(y) \(Text("against").fontWeight(.regular).foregroundStyle(.secondary)) \(Text(graph.x))")
    }
}

/// A plot too small to read, which only shows the shape the points should make: a pair of axes, and dots along
/// the curve, as plotted points would be. Drawn in the method's colour, as the tile's drawing is.
private struct GraphGlyph: View {
    let shape: ExperimentGraph.Shape
    let color: Color

    private static let dotCount = 7
    private static let dotSize: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            // Inset from the axes, so that no dot sits on them.
            let inset: CGFloat = 6

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                }
                .stroke(.secondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                ForEach(0..<Self.dotCount, id: \.self) { index in
                    let progress = CGFloat(index) / CGFloat(Self.dotCount - 1)
                    let point = CGPoint(x: inset + progress * (size.width - 2 * inset), y: size.height - inset - height(at: progress) * (size.height - 2 * inset))

                    Circle()
                        .fill(color)
                        .frame(width: Self.dotSize, height: Self.dotSize)
                        .position(point)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The curve's height at `progress` across, both from 0 to 1.
    private func height(at progress: CGFloat) -> CGFloat {
        switch shape {
        case .parabola:
            return progress * progress
        case .flight:
            return 1 - pow(2 * progress - 1, 2)
        case .line:
            return progress
        }
    }
}

/// The columns of data the method gives, as the top of a table: each column's symbol over its unit, so the
/// data can be read off at a glance. The same columns, in the same order, as the table, CSV and Desmos export;
/// the full headings are what VoiceOver reads. Not glass: it is something to read, inside a tile that is a button.
private struct DataColumnsStrip: View {
    let data: RunData

    static let height: CGFloat = 50

    private struct Column {
        let symbol: Text
        let unit: String
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                if index > 0 {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 1)
                        .padding(.vertical, 6)
                }

                VStack(spacing: 1) {
                    column.symbol
                        .customFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.primary)

                    Text(column.unit)
                        .customFont(.caption2)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            }
        }
        // One height for every strip, so that a superscript can't put one tile's name out of line with the other's.
        .frame(height: Self.height)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Data: \(DataTableView.columnHeadings(for: data).joined(separator: ", "))")
    }

    private var columns: [Column] {
        switch data {
        case .distance:
            return [Column(symbol: Text("t"), unit: "s"), Column(symbol: Text("d"), unit: "m")]
        case .position:
            return [Column(symbol: Text("t"), unit: "s"), Column(symbol: Text("x"), unit: "m"), Column(symbol: Text("y"), unit: "m")]
        case .circle:
            return [Column(symbol: Text("t"), unit: "s"), Column(symbol: Text("x"), unit: "m"), Column(symbol: Text("y"), unit: "m"), Column(symbol: Text("θ"), unit: "rad"), Column(symbol: Text("r"), unit: "m")]
        case .rotation:
            return [Column(symbol: Text("t"), unit: "s"), Column(symbol: Text("ω"), unit: "rad/s"), Column(symbol: Text("ω²"), unit: "rad²/s²"), Column(symbol: subscripted("a", "c"), unit: "m/s²"), Column(symbol: subscripted("a", "t"), unit: "m/s²")]
        }
    }

    /// A symbol with a subscript, such as a_c for the centripetal acceleration.
    private func subscripted(_ symbol: String, _ index: String) -> Text {
        Text("\(Text(symbol))\(Text(index).font(.caption2.weight(.semibold)).baselineOffset(-3))")
    }
}

/// A small drawing of the experiment done with the method: the same track, flight and circle as the home
/// screen's drawing, with the iPhone where it goes. With the camera it is a square beside what it films, or in
/// the middle of the circle, looking down; with the sensor it is the cart or the object on the turntable,
/// the phone's symbol on it.
private struct MethodDrawing: View {
    let experiment: Experiment
    let method: Method

    /// The size it is drawn to, before `scale(toFit:)`.
    private static let size = CGSize(width: 150, height: 100)
    private static let maximumScale: CGFloat = 1.5

    /// How much to scale the drawing by to fit `available`, no more than `maximumScale`.
    static func scale(toFit available: CGSize) -> CGFloat {
        min(available.width / size.width, available.height / size.height, maximumScale)
    }
    private static let lineWidth: CGFloat = 3
    private static let dotSize: CGFloat = 4

    private static let slope: Angle = .degrees(-20)
    private static let trackLength: CGFloat = 150
    private static let cartSize: CGFloat = 38
    /// The gap the cart floats over the track by: it is an air track.
    private static let trackSpacing: CGFloat = 12

    private static let arcSize = CGSize(width: 140, height: 56)
    private static let projectileSize: CGFloat = 26
    private static let projectileProgress: CGFloat = 0.6

    private static let ringSize: CGFloat = 92
    private static let markerSize: CGFloat = 12
    private static let markerAngle: Angle = .degrees(-60)
    private static let phoneOnTurntableSize: CGFloat = 32

    private static let cameraSize: CGFloat = 34

    var body: some View {
        ZStack {
            switch experiment {
            case .airTrack:
                trackDrawing
            case .projectile:
                flightDrawing
            case .circularMotion:
                circleDrawing
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .foregroundStyle(method.color.gradient)
        .accessibilityHidden(true)
    }

    // MARK: - The three experiments

    private var trackDrawing: some View {
        // The cart above the middle of the track, both tilted about the middle of the drawing.
        let cartRise = (Self.cartSize + Self.lineWidth) / 2 + Self.trackSpacing
        let cartCenter = rotated(CGSize(width: 0, height: -cartRise / 2))
        let trackCenter = rotated(CGSize(width: 0, height: cartRise / 2))

        return ZStack {
            Capsule()
                .frame(width: Self.trackLength, height: Self.lineWidth)
                .rotationEffect(Self.slope)
                .offset(trackCenter)

            object(size: Self.cartSize)
                .offset(cartCenter)

            if method == .camera {
                // Below the track and clear of it, looking up at the cart from the side.
                camera
                    .offset(x: 48, y: 30)
            }
        }
    }

    private var flightDrawing: some View {
        let count = 13
        let center = CGSize(width: (Self.projectileProgress - 0.5) * Self.arcSize.width, height: (arcHeight(at: Self.projectileProgress) - 0.5) * Self.arcSize.height)

        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                let progress = CGFloat(index) / CGFloat(count - 1)

                Circle()
                    .frame(width: Self.dotSize, height: Self.dotSize)
                    .offset(x: (progress - 0.5) * Self.arcSize.width, y: (arcHeight(at: progress) - 0.5) * Self.arcSize.height)
            }

            object(size: Self.projectileSize)
                .offset(center)

            if method == .camera {
                // Under the middle of the arc, clear of the flight, filming it side on.
                camera
                    .offset(x: 0, y: 30)
            }
        }
    }

    @ViewBuilder
    private var circleDrawing: some View {
        let radius = (Self.ringSize - Self.lineWidth) / 2

        switch method {
        case .camera:
            // A marker going round, filmed from straight above the middle.
            ZStack {
                ForEach(0..<24, id: \.self) { index in
                    let angle = Double(index) / 24 * 2 * .pi

                    Circle()
                        .frame(width: Self.dotSize, height: Self.dotSize)
                        .offset(x: radius * cos(angle), y: radius * sin(angle))
                }

                Circle()
                    .frame(width: Self.markerSize, height: Self.markerSize)
                    .offset(x: radius * cos(Self.markerAngle.radians), y: radius * sin(Self.markerAngle.radians))

                camera
            }
        case .sensor:
            // The turntable's rim and spindle, with the phone on it part-way out from the middle.
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: Self.lineWidth)
                    .frame(width: Self.ringSize, height: Self.ringSize)

                Circle()
                    .frame(width: 5, height: 5)

                object(size: Self.phoneOnTurntableSize)
                    .offset(y: -radius / 2)
            }
        }
    }

    // MARK: - Pieces

    /// The cart, the projectile or the phone on the turntable. With the sensor the phone rides on it, so it
    /// carries the phone's symbol.
    private func object(size: CGFloat) -> some View {
        Circle()
            .frame(width: size, height: size)
            .overlay {
                if method == .sensor {
                    Image(systemName: Method.sensor.imageName)
                        .font(.system(size: size * 0.5, weight: .medium))
                        .foregroundStyle(.black.opacity(0.7))
                }
            }
    }

    /// The iPhone filming. Not glass: it is part of the drawing, on a tile that is already glass.
    private var camera: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(width: Self.cameraSize, height: Self.cameraSize)
            .overlay {
                Image(systemName: Method.camera.imageName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black.opacity(0.7))
            }
            .overlay {
                // Cut out of what is behind it, so it reads as in front of the cart.
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.black.opacity(0.35), lineWidth: 2)
            }
    }

    /// The arc's height at `progress` across it, from 1 at the ends to 0 at the top, as on the home screen.
    private func arcHeight(at progress: CGFloat) -> CGFloat {
        pow(1 - 2 * progress, 2)
    }

    /// An offset tilted by the track's slope, as the track and the cart are.
    private func rotated(_ offset: CGSize) -> CGSize {
        let angle = Self.slope.radians
        return CGSize(width: offset.width * cos(angle) - offset.height * sin(angle), height: offset.width * sin(angle) + offset.height * cos(angle))
    }
}

#Preview("Circular Motion") {
    let methodManager = MethodManager()
    methodManager.experiment = .circularMotion

    return SelectMethodView()
        .environment(methodManager)
}

#Preview("Projectile") {
    let methodManager = MethodManager()
    methodManager.experiment = .projectile

    return SelectMethodView()
        .environment(methodManager)
}
