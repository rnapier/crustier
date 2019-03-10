/*:
 There's no way for a protocol to require value types, so it can't rely on the
 behaviors of values. In particular, you can't assume copies are non-aliases.
 ObjC had a similar problem with mutable/immutable, which was solved with
 defensive copying. But there's no equiqivalent in Swift. Making a protocol
 copyable has a major impact on the entire system because it makes the protocol
 a PAT (due to Self).
 */

import Foundation

// Something that can have a timestamp applied
protocol Timestamped {
    var timestamp: TimeInterval? { get set }
}

// Return a version with the timestamp.
// Does this modify the original object? It depends on if it's a value or
// reference, and there's no way for this method to warn its caller of its side
// effects except documentation.
extension Timestamped {
    func withTimestamp() -> Self {
        var timestamped = self      // What does this line of code do?
        timestamped.timestamp = Date().timeIntervalSince1970
        return timestamped
    }
}

func process(record: Timestamped & CustomStringConvertible) {
    print("Processed: \(record.withTimestamp())")
}

//
// A struct, works as expected.
//
struct Record: Timestamped, CustomStringConvertible {
    var name: String
    var timestamp: TimeInterval?
    init(name: String) { self.name = name }
    var description: String {
        if let timestamp = timestamp { return "\(name): \(timestamp)" }
        else { return "\(name): Unsent" }
    }
}

let record = Record(name: "Alice")
print("Record before process: \(record)")
process(record: record)
print("Record after process: \(record)")    // No change here


//
// Exactly the same thing, just a class.
//
class Packet: Timestamped, CustomStringConvertible {
    var name: String
    var timestamp: TimeInterval?
    init(name: String) { self.name = name }
    var description: String {
        if let timestamp = timestamp { return "\(name): \(timestamp)" }
        else { return "\(name): Unsent" }
    }
}

print("----")
let packet = Packet(name: "Alice")
print("Packet before process: \(packet)")
process(record: packet)
print("Packet after process: \(packet)")    // Packet has been changed behind our back.

//
// It's possible to work around this by adding Copyable, but it's really ugly.
//

protocol Copyable {
    init(copy: Self)
}

// It's tempting to do this, but it's dangerous. This only works for value
// types, and if we forget to apply it to refererence types, it'll quietly alias.
//
//        extension Copyable {
//            init(copy: Self) { self = copy }
//        }
//
// We could add the following to protect against that, but... o_O
//
//        extension Copyable where Self: AnyObject {
//            init(copy: Self) { fatalError() }
//        }


// Even so, not too hard for structs
extension Record: Copyable {
    init(copy: Record) { self = copy }
}

// But for non-final classes, it's not possible in an extension. init(copy:) is
// `required`, so it has to be added in the original definition. If we don't
// control the original definition, we have to subclass, which often isn't possible,
// particularly for types you don't control.

class CopyablePacket: Packet, Copyable {
    required init(copy: CopyablePacket) { super.init(name: copy.name) }
    // And we need to reimplement this one because we've added a required init.
    override init(name: String) { super.init(name: name) }
}

// Using that would look like this:

extension Timestamped where Self: Copyable {
    func withTimestampCopy() -> Self {
        var timestamped = type(of: self).init(copy: self)
        timestamped.timestamp = Date().timeIntervalSince1970
        return timestamped
    }
}

// Since Copyable is a PAT, this now has to be generic.
func copyProcess<R>(record: R) where R: Timestamped & CustomStringConvertible & Copyable {
    print("Processed (with copy): \(record.withTimestampCopy())")
}

print("----")

print("Record before process: \(record)")
copyProcess(record: record)
print("Record after process: \(record)")

print("----")
let copyPacket = CopyablePacket(name: "Alice")
print("Packet before process: \(copyPacket)")
copyProcess(record: copyPacket)
print("Packet after process: \(copyPacket)")

