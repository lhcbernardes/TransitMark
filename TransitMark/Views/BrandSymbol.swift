//
//  BrandSymbol.swift
//  TransitMark
//

import SwiftUI

struct BrandSymbol: View {
    var color: Color = .primary
    var glowing: Bool = false

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let cx = size.width / 2
            let cy = size.height / 2

            var axis = Path()
            axis.move(to: CGPoint(x: cx, y: cy - s * 0.40))
            axis.addLine(to: CGPoint(x: cx, y: cy + s * 0.40))
            context.stroke(
                axis,
                with: .color(color.opacity(0.55)),
                style: StrokeStyle(lineWidth: s * 0.012, lineCap: .round)
            )

            var curve = Path()
            let p0 = CGPoint(x: cx - s * 0.40, y: cy + s * 0.23)
            let p1 = CGPoint(x: cx + s * 0.05, y: cy + s * 0.23)
            let p2 = CGPoint(x: cx - s * 0.05, y: cy - s * 0.23)
            let p3 = CGPoint(x: cx + s * 0.40, y: cy - s * 0.23)
            curve.move(to: p0)
            curve.addCurve(to: p3, control1: p1, control2: p2)

            if glowing {
                context.stroke(
                    curve,
                    with: .color(color.opacity(0.30)),
                    style: StrokeStyle(lineWidth: s * 0.105, lineCap: .round)
                )
            }
            context.stroke(
                curve,
                with: .color(color),
                style: StrokeStyle(lineWidth: s * 0.045, lineCap: .round)
            )

            let dotR = s * 0.045
            context.fill(
                Path(ellipseIn: CGRect(
                    x: cx - dotR,
                    y: cy - dotR,
                    width: dotR * 2,
                    height: dotR * 2
                )),
                with: .color(color)
            )
        }
        .accessibilityHidden(true)
    }
}

enum Brand {
    static let amber = Color(red: 0.965, green: 0.835, blue: 0.62)
    static let amberDeep = Color(red: 0.65, green: 0.43, blue: 0.17)
    static let darkBackground = Color(red: 0.094, green: 0.094, blue: 0.094)
}

#Preview("Glow") {
    BrandSymbol(color: Brand.amber, glowing: true)
        .frame(width: 200, height: 200)
        .padding(40)
        .background(Brand.darkBackground)
}

#Preview("Flat") {
    BrandSymbol(color: .secondary)
        .frame(width: 120, height: 120)
        .padding(40)
}
