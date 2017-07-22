
import Foundation


public protocol BinaryDecodable: Decodable {
    init(fromBinary decoder: BinaryDecoder) throws
}

public extension BinaryDecodable {
    public init(fromBinary decoder: BinaryDecoder) throws {
        try self.init(from: decoder)
    }
}

public class BinaryDecoder {
    fileprivate let data: [UInt8]
    fileprivate var cursor = 0
    
    public init(data: [UInt8]) {
        self.data = data
    }
}

public extension BinaryDecoder {
    static func decode<T: BinaryDecodable>(_ type: T.Type, data: [UInt8]) throws -> T {
        return try BinaryDecoder(data: data).decode(T.self)
    }
}

public extension BinaryDecoder {
    enum Error: Swift.Error {
        case prematureEndOfData
        
        case typeNotConformingToBinaryDecodable(Decodable.Type)
        
        case intOutOfRange(Int64)
        case uintOutOfRange(UInt64)
        case boolOutOfRange(UInt8)
        case invalidUTF8([UInt8])
    }
}

public extension BinaryDecoder {
    func decode<T: BinaryDecodable>(_ type: T.Type) throws -> T {
        return try T(fromBinary: self)
    }
    
    func decode<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        switch type {
        case is Int.Type:
            let v = try decode(Int64.self)
            if let v = T(exactly: v) {
                return v
            } else {
                throw Error.intOutOfRange(v)
            }
        case is UInt.Type:
            let v = try decode(UInt64.self)
            if let v = T(exactly: v) {
                return v
            } else {
                throw Error.uintOutOfRange(v)
            }
        default:
            var v = T()
            try read(into: &v)
            return T(bigEndian: v)
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        var swapped = CFSwappedFloat32()
        try read(into: &swapped)
        return CFConvertFloatSwappedToHost(swapped)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        var swapped = CFSwappedFloat64()
        try read(into: &swapped)
        return CFConvertDoubleSwappedToHost(swapped)
    }
    
    func decode(_ type: String.Type) throws -> String {
        let utf8 = try decodeDecodable([UInt8].self)
        if let s = String(bytes: utf8, encoding: .utf8) {
            return s
        } else {
            throw Error.invalidUTF8(utf8)
        }
    }
    
    func decodeDecodable<T: Decodable>(_ type: T.Type) throws -> T {
        guard let binaryT = T.self as? BinaryDecodable.Type else {
            throw Error.typeNotConformingToBinaryDecodable(type)
        }
        return try binaryT.init(fromBinary: self) as! T
    }
}

private extension BinaryDecoder {
    func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws {
        if cursor + byteCount > data.count {
            throw Error.prematureEndOfData
        }
        
        data.withUnsafeBytes({
            let from = $0.baseAddress! + cursor
            memcpy(into, from, byteCount)
        })
        
        cursor += byteCount
    }
    
    func read<T>(into: inout T) throws {
        try read(MemoryLayout<T>.size, into: &into)
    }
}

extension BinaryDecoder: Decoder {
    public var codingPath: [CodingKey?] { return [] }
    
    public var userInfo: [CodingUserInfoKey : Any] { return [:] }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError()
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: BinaryDecoder
        
        var codingPath: [CodingKey?] { return [] }
        
        var allKeys: [Key] { return [] }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
            switch try decoder.decode(UInt8.self) {
            case 0: return false
            case 1: return true
            case let x: throw Error.boolOutOfRange(x)
            }
        }
        
        func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
            return try decoder.decode(Int.self)
        }
        
        func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
            return try decoder.decode(Int8.self)
        }
        
        func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
            return try decoder.decode(Int16.self)
        }
        
        func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
            return try decoder.decode(Int32.self)
        }
        
        func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
            return try decoder.decode(Int64.self)
        }
        
        func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
            return try decoder.decode(UInt.self)
        }
        
        func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
            return try decoder.decode(UInt8.self)
        }
        
        func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
            return try decoder.decode(UInt16.self)
        }
        
        func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
            return try decoder.decode(UInt32.self)
        }
        
        func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
            return try decoder.decode(UInt64.self)
        }
        
        func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
            return try decoder.decode(Float.self)
        }
        
        func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
            return try decoder.decode(Double.self)
        }
        
        func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
            return try decoder.decode(String.self)
        }
        
        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            return try decoder.decodeDecodable(T.self)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return decoder
        }
    }
}


