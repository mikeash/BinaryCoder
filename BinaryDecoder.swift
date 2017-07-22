
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
    func decode(_ type: Bool.Type) throws -> Bool {
        switch try decode(UInt8.self) {
        case 0: return false
        case 1: return true
        case let x: throw Error.boolOutOfRange(x)
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
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch type {
        case is Int.Type:
            let v = try decode(Int64.self)
            if let v = Int(exactly: v) {
                return v as! T
            } else {
                throw Error.intOutOfRange(v)
            }
        case is UInt.Type:
            let v = try decode(UInt64.self)
            if let v = UInt(exactly: v) {
                return v as! T
            } else {
                throw Error.uintOutOfRange(v)
            }
        case let intT as FixedWidthInteger.Type:
            return try intT.from(decoder: self) as! T
            
        case is Float.Type:
            return try decode(Float.self) as! T
        case is Double.Type:
            return try decode(Double.self) as! T
            
        case is Bool.Type:
            return try decode(Bool.self) as! T
            
        case let binaryT as BinaryDecodable.Type:
            return try binaryT.init(fromBinary: self) as! T
            
        default:
            throw Error.typeNotConformingToBinaryDecodable(type)
        }
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
        
        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            return try decoder.decode(T.self)
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

private extension FixedWidthInteger {
    static func from (decoder: BinaryDecoder) throws -> Self {
        var v = Self.init()
        try decoder.read(into: &v)
        return self.init(bigEndian: v)
    }
}
