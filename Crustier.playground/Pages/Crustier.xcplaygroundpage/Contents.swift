/// Crustier
///

/*:
 IMO, a bit Crustier version of Crustacean that better implements value types.
 This version of TestRenderer captures the operations applied, which is more
 appropriate for unit testing than printing. This means that the renderer
 changes state (which is also true of CGContext). Renderers should either be
 reference types, or their methods should be mutating. I think value types are
 the better answer, so this implement mutating.

 It does raise an interesting problem, however. CGContext is a reference type.
 Generic methods can't rely on the value-ness of things they receive, which can
 lead to confusion. It's possible to require AnyObject, but it's not possible to
 forbid it. See [Does It Value?](Does%20It%20Value%3F)
*/

import CoreGraphics

///
/// Interfaces
///
protocol Drawable {
    func draw<R: Renderer>(in renderer: inout R)
    func isEqual(to other: Drawable) -> Bool
}

extension Drawable where Self: Equatable {
    func isEqual(to other: Drawable) -> Bool {
        if let other = other as? Self { return self == other }
        return false
    }
}

protocol Renderer {
    mutating func move(to position: CGPoint)
    mutating func addLine(to point: CGPoint)
    mutating func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool)
}

extension Renderer {
    mutating func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    }
}
///
/// Implementations
///

struct Circle: Equatable, Drawable {
    var center: CGPoint
    var radius: CGFloat
    func draw<R: Renderer>(in renderer: inout R) {
        renderer.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi*2)
    }
}

struct Polygon: Equatable, Drawable {
    var corners: [CGPoint]

    func draw<R: Renderer>(in renderer: inout R) {
        renderer.move(to: corners.last!)
        for p in corners { renderer.addLine(to: p) }
    }
}

struct Diagram: Equatable, Drawable {
    var elements: [Drawable]

    func draw<R: Renderer>(in renderer: inout R) {
        for f in elements {
            f.draw(in: &renderer)
        }
    }

    static func ==(lhs: Diagram, rhs: Diagram) -> Bool {
        return lhs.elements.count == rhs.elements.count &&
            zip(lhs.elements, rhs.elements).allSatisfy { $0.0.isEqual(to: $0.1) }
    }
}

struct TestRenderer: Renderer {
    var operations: [String] = []
    mutating func move(to p: CGPoint) {
        operations.append("moveTo(\(p.x), \(p.y))")
    }

    mutating func addLine(to p: CGPoint) {
        operations.append("lineTo(\(p.x), \(p.y))")
    }

    mutating func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        operations.append("arcAt(\(center), radius: \(radius)," +
            " startAngle: \(startAngle), endAngle: \(endAngle), clockwise: \(clockwise))")
    }
}

extension CGContext: Renderer {}

///
/// Usage
///
var renderer = TestRenderer()
let circle = Circle(center: CGPoint(x: 187.5, y: 333.5), radius: 93.75)

let triangle = Polygon(corners: [
    CGPoint(x: 187.5, y: 427.25),
    CGPoint(x: 268.69, y: 286.625),
    CGPoint(x: 106.31, y: 286.625)
    ])

let diagram = Diagram(elements: [circle, triangle])

diagram.draw(in: &renderer)
print(renderer.operations.joined(separator: "\n"))

showCoreGraphicsDiagram(title: "Diagram") { diagram.draw(in: &$0) }

