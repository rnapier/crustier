/// THIS IS A JOKE; DO NOT USE THIS CODE

/*:

 Crustier than Crusty. Crustacean uses 2 protocols. This uses 7, plus 2 protocol
 extensions, so clearly this is more protocol oriented....

 Actually what this is doing is recreating class inheritance using protocols,
 and it drags in all the problems of inheritance in the process. In particular,
 note the Square-Rectange problem that shows up in both Arc/Circle and
 Polygon/Triangle. If these were mutable protocols, this whole approach would
 break because Circles have different invariants than Arcs.

 Also note the fatalError in Renderer because it reinvents enums on top of the
 protocols.

 This was an exploration of what I've called "pull" vs "push" protocols. I'm not
 necessarily happy with those names, but they're helping me think though it all.

 [Twitter thread](https://twitter.com/cocoaphony/status/1104114274950176769)

 Crusty's Drawable pulls. It starts with the use case, the Renderer, and it asks
 other types for what it needs for that use case. (I'm not suggesting single-use
 protocols; multi-use protocols are better, but the point is starting with a
 use-case.) Any type can conform to Drawable and particpate.

 In this example, Shape pushes. It starts by categorizing various kinds of
 Shapes that exist, defining the protocol in terms of the properties of the
 model. With that in place, Renderer is led to as-casting, because the protocols
 are about the model, not about the caller. This means that if another module
 wants to add new kinds of shapes, it needs to implement a new Renderer that
 understands those shapes.

 Obviously Crusty's system could be effectively built with inheritance without
 creating all these problems. What I'm really exploring here is the impact of
 starting from the model, rather than starting from the consumer of the model.

 */

/// THIS IS A JOKE; DO NOT USE THIS CODE

import CoreGraphics

///
/// Interfaces
/// THIS IS A JOKE; DO NOT USE THIS CODE
///

//
// Models
//
protocol Shape {}

protocol Arc: Shape {
    var center: CGPoint { get }
    var radius: CGFloat { get }
    var startAngle: CGFloat { get }
    var endAngle: CGFloat { get }
}

protocol Circle: Arc {}

extension Circle {
    var startAngle: CGFloat { return 0 }
    var endAngle: CGFloat { return .pi * 2 }
}

protocol Polygon: Shape {
    var corners: [CGPoint] { get }
}

protocol Triangle: Polygon {
    var point1: CGPoint { get }
    var point2: CGPoint { get }
    var point3: CGPoint { get }
}

extension Triangle {
    var corners: [CGPoint] { return [point1, point2, point3] }
}

protocol Diagram: Shape {
    var elements: [Shape] { get }
}

protocol Renderer {
    func draw(arc: Arc)
    func move(to: CGPoint)
    func addLine(to: CGPoint)
}

extension Renderer {
    func draw(shape: Shape) {
        switch shape {
        case let arc as Arc:
            draw(arc: arc)
            
        case let polygon as Polygon:
            guard let firstPoint = polygon.corners.last else { return }
            move(to: firstPoint)
            
            for p in polygon.corners {
                addLine(to: p)
            }
            
        case let diagram as Diagram:
            for element in diagram.elements {
                draw(shape: element)
            }
            
        default:
            fatalError("Unknown shape: \(shape)")
        }
    }
}

///
/// Implementations
/// THIS IS A JOKE; DO NOT USE THIS CODE
///

struct CircleImpl: Circle {
    let center: CGPoint
    let radius: CGFloat
}

struct TriangleImpl: Triangle {
    let point1, point2, point3: CGPoint
}

struct DiagramImpl: Diagram {
    let elements: [Shape]
}

struct TestRenderer: Renderer {
    func draw(arc: Arc) {
        print("arcAt(\(arc.center), radius: \(arc.radius)," +
            " startAngle: \(arc.startAngle), endAngle: \(arc.endAngle))")
    }
    
    func move(to p: CGPoint) {
        print("moveTo(\(p.x), \(p.y))")
    }
    
    func addLine(to p: CGPoint) {
        print("lineTo(\(p.x), \(p.y))")
    }
}

extension CGContext: Renderer {
    func draw(arc: Arc) {
        addArc(center: arc.center, radius: arc.radius,
               startAngle: arc.startAngle, endAngle: arc.endAngle,
               clockwise: true)
    }
}

///
/// Usage
/// THIS IS A JOKE; DO NOT USE THIS CODE
///
let renderer = TestRenderer()
let circle = CircleImpl(center: CGPoint(x: 187.5, y: 333.5), radius: 93.75)

let triangle = TriangleImpl(
    point1: CGPoint(x: 187.5, y: 427.25),
    point2: CGPoint(x: 268.69, y: 286.625),
    point3: CGPoint(x: 106.31, y: 286.625))

let diagram = DiagramImpl(elements: [circle, triangle])

renderer.draw(shape: diagram)

showCoreGraphicsDiagram(title: "Diagram") { $0.draw(shape: diagram) }

//// THIS IS A JOKE; DO NOT USE THIS CODE
