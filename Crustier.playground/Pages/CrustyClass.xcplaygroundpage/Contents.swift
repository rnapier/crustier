/// Crustier, using classes.

/// The point of this file is to demonstate how the same structural approach
/// from Crusty can be implemented in OOP. It's presented in contrast to
/// CrustierJoke. The problem I'm discussing isn't value/reference or
/// conform/inherit. It's push/pull. Designing your interfaces based on your
/// use-cases rather than based on your model. Where protocols really shine
/// here is that different protocols can be built to solve different use
/// cases, and the same models can conform to those different protcols in
/// different ways without changing the model's implementation. With (single)
/// inheritance, the model has to choose a single way to "be." And if different
/// use cases require different interfaces, then you need adapters (see
/// CGContextRenderer below).

import CoreGraphics

///
/// Abstract classes.
/// The fact that these crash when not implemented, IMO, should not be seen as
/// a problem with inheritance or classes. It's just a missing Swift feature.
/// Many languages support compiler-checked abstract methods.
///
func abstract(file: StaticString = #file, line: UInt = #line, function: String = #function) -> Never {
    fatalError("Implement \(function)", file: file, line: line)
}

class Drawable {
    func draw(in renderer: Renderer) { abstract() }
}

class Renderer {
    func move(to position: CGPoint) { abstract() }
    func addLine(to point: CGPoint) { abstract()}
    func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) { abstract() }
}

extension Renderer {
    func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    }
}
///
/// Implementations
///

class Circle: Drawable {
    var center: CGPoint
    var radius: CGFloat
    override func draw(in renderer: Renderer) {
        renderer.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi*2)
    }
    init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
}

class Polygon: Drawable {
    var corners: [CGPoint]

    override func draw(in renderer: Renderer) {
        renderer.move(to: corners.last!)
        for p in corners { renderer.addLine(to: p) }
    }

    init(corners: [CGPoint]) { self.corners = corners }
}

class Diagram: Drawable {
    var elements: [Drawable]

    override func draw(in renderer: Renderer) {
        for f in elements {
            f.draw(in: renderer)
        }
    }

    init(elements: [Drawable]) { self.elements = elements }
}

class TestRenderer: Renderer {
    var operations: [String] = []
    override func move(to p: CGPoint) {
        operations.append("moveTo(\(p.x), \(p.y))")
    }

    override func addLine(to p: CGPoint) {
        operations.append("lineTo(\(p.x), \(p.y))")
    }

    override func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        operations.append("arcAt(\(center), radius: \(radius)," +
            " startAngle: \(startAngle), endAngle: \(endAngle), clockwise: \(clockwise))")
    }
}

// CGContext cannot itself become a Renderer. We have to wrap it into a CGContextRenderer. :(
// This, IMO, *should* be seen as a failure of inheritance.
// extension CGContext: Renderer {}

class CGContextRenderer: Renderer {
    var context: CGContext
    override func move(to p: CGPoint) {
        context.move(to: p)
    }

    override func addLine(to p: CGPoint) {
        context.addLine(to: p)
    }

    override func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }
    init(context: CGContext) { self.context = context }
}

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

diagram.draw(in: renderer)
print(renderer.operations.joined(separator: "\n"))


/// Note that we need to rewrap CGContext here
showCoreGraphicsDiagram(title: "Diagram") {
    let renderer = CGContextRenderer(context: $0)
    diagram.draw(in: renderer)
}

