import XCTest

import BinaryCoder


class BinaryCoderTests: XCTestCase {
    func testPrimitiveEncoding() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7)
        let data = try BinaryEncoder.encode(s)
        XCTAssertEqual(data, [
            1,
            0, 2,
            0, 0, 0, 3,
            0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 0, 0, 0, 5,
            
            0x40, 0xC0, 0x00, 0x00,
            0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ])
        print(data)
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
        ]
        let s = try BinaryDecoder.decode(Primitives.self, data: data)
        XCTAssertEqual(s.a, 1)
        XCTAssertEqual(s.b, 2)
        XCTAssertEqual(s.c, 3)
        XCTAssertEqual(s.d, 4)
        XCTAssertEqual(s.e, 5)
        XCTAssertEqual(s.f, 6)
        XCTAssertEqual(s.g, 7)
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
}

