import XCTest

import BinaryCoder


class BinaryCoderTests: XCTestCase {
    func testPrimitiveEncoding() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true)
        let data = try BinaryEncoder.encode(s)
        XCTAssertEqual(data, [
            1,
            0, 2,
            0, 0, 0, 3,
            0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 0, 0, 0, 5,
            
            0x40, 0xC0, 0x00, 0x00,
            0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            0x00, 0x01
        ])
    }
    
    func testPrimitiveDecoding() throws {
        let data: [UInt8] = [
            1,
            0, 2,
            0, 0, 0, 3,
            0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 0, 0, 0, 5,
            
            0x40, 0xC0, 0x00, 0x00,
            0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            0x00, 0x01
        ]
        let s = try BinaryDecoder.decode(Primitives.self, data: data)
        XCTAssertEqual(s.a, 1)
        XCTAssertEqual(s.b, 2)
        XCTAssertEqual(s.c, 3)
        XCTAssertEqual(s.d, 4)
        XCTAssertEqual(s.e, 5)
        XCTAssertEqual(s.f, 6)
        XCTAssertEqual(s.g, 7)
        XCTAssertEqual(s.h, false)
        XCTAssertEqual(s.i, true)
    }
    
    func testString() {
        struct WithString: BinaryCodable {
            var a: String
            var b: String
            var c: Int
        }
        AssertRoundtrip(WithString(a: "hello", b: "world", c: 42))
    }
    
    func testComplex() {
        struct Company: BinaryCodable {
            var name: String
            var employees: [Employee]
        }
        
        struct Employee: BinaryCodable {
            var name: String
            var jobTitle: String
            var age: Int
        }
        
        let company = Company(name: "Joe's Discount Airbags", employees: [
            Employee(name: "Joe Johnson", jobTitle: "CEO", age: 27),
            Employee(name: "Stan Lee", jobTitle: "Janitor", age: 87),
            Employee(name: "Dracula", jobTitle: "Dracula", age: 41),
            Employee(name: "Steve Jobs", jobTitle: "Visionary", age: 56),
        ])
        AssertRoundtrip(company)
    }
}

private func AssertEqual<T>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(String(describing: lhs), String(describing: rhs), file: file, line: line)
}

private func AssertRoundtrip<T: BinaryCodable>(_ original: T, file: StaticString = #file, line: UInt = #line) {
    do {
        let data = try BinaryEncoder.encode(original)
        let roundtripped = try BinaryDecoder.decode(T.self, data: data)
        AssertEqual(original, roundtripped, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}

struct Primitives: BinaryCodable {
    var a: Int8
    var b: UInt16
    var c: Int32
    var d: UInt64
    var e: Int
    var f: Float
    var g: Double
    var h: Bool
    var i: Bool
}

