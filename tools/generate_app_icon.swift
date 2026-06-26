#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum Variant {
    case light, dark, tinted

    var filename: String {
        switch self {
        case .light:  return "AppIcon-Light.png"
        case .dark:   return "AppIcon-Dark.png"
        case .tinted: return "AppIcon-Tinted.png"
        }
    }

    var background: CGColor {
        switch self {
        case .light:  return CGColor(srgbRed: 0.965, green: 0.937, blue: 0.886, alpha: 1)
        case .dark:   return CGColor(srgbRed: 0.094, green: 0.094, blue: 0.094, alpha: 1)
        case .tinted: return CGColor(srgbRed: 0.0,   green: 0.0,   blue: 0.0,   alpha: 1)
        }
    }

    var lineColor: CGColor {
        switch self {
        case .light:  return CGColor(srgbRed: 0.65,  green: 0.43,  blue: 0.17,  alpha: 1)
        case .dark:   return CGColor(srgbRed: 0.965, green: 0.835, blue: 0.62,  alpha: 1)
        case .tinted: return CGColor(srgbRed: 1.0,   green: 1.0,   blue: 1.0,   alpha: 1)
        }
    }

    var glowColor: CGColor {
        switch self {
        case .light:  return CGColor(srgbRed: 0.95, green: 0.74, blue: 0.43, alpha: 0.45)
        case .dark:   return CGColor(srgbRed: 0.965, green: 0.78, blue: 0.50, alpha: 0.55)
        case .tinted: return CGColor(srgbRed: 1.0,  green: 1.0,  blue: 1.0,  alpha: 0.35)
        }
    }
}

func makeIcon(variant: Variant, size: CGFloat = 1024) -> CGImage? {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.setFillColor(variant.background)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    let centerX = size / 2
    let axisTop = size * 0.18
    let axisBottom = size * 0.82

    context.setStrokeColor(variant.lineColor)
    context.setLineWidth(size * 0.007)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: centerX, y: axisTop))
    context.addLine(to: CGPoint(x: centerX, y: axisBottom))
    context.strokePath()

    let strokeWidth = size * 0.026

    let p0 = CGPoint(x: size * 0.175, y: size * 0.27)
    let p1 = CGPoint(x: size * 0.547, y: size * 0.27)
    let p2 = CGPoint(x: size * 0.453, y: size * 0.73)
    let p3 = CGPoint(x: size * 0.825, y: size * 0.73)

    context.saveGState()
    context.setShadow(offset: .zero, blur: size * 0.045, color: variant.glowColor)
    context.setStrokeColor(variant.glowColor)
    context.setLineWidth(strokeWidth * 1.9)
    context.setLineCap(.round)
    context.move(to: p0)
    context.addCurve(to: p3, control1: p1, control2: p2)
    context.strokePath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: .zero, blur: size * 0.020, color: variant.lineColor)
    context.setStrokeColor(variant.lineColor)
    context.setLineWidth(strokeWidth)
    context.setLineCap(.round)
    context.move(to: p0)
    context.addCurve(to: p3, control1: p1, control2: p2)
    context.strokePath()
    context.restoreGState()

    let dotRadius = size * 0.030
    context.saveGState()
    context.setShadow(offset: .zero, blur: size * 0.025, color: variant.glowColor)
    context.setFillColor(variant.lineColor)
    context.fillEllipse(in: CGRect(
        x: centerX - dotRadius,
        y: size / 2 - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    ))
    context.restoreGState()

    return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else { return false }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate_app_icon.swift <output_dir>\n".utf8))
    exit(1)
}

let outputDir = URL(fileURLWithPath: arguments[1])

for variant in [Variant.light, .dark, .tinted] {
    guard let image = makeIcon(variant: variant) else {
        FileHandle.standardError.write(Data("failed to render \(variant.filename)\n".utf8))
        exit(2)
    }
    let url = outputDir.appendingPathComponent(variant.filename)
    if writePNG(image, to: url) {
        print("wrote \(url.lastPathComponent)")
    } else {
        FileHandle.standardError.write(Data("failed to write \(variant.filename)\n".utf8))
        exit(3)
    }
}
