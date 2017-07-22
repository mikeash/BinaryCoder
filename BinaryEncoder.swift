
import CoreFoundation


public protocol BinaryEncodable: Encodable {
    func binaryEncode(to: BinaryEncoder) throws
}

public extension BinaryEncodable {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try self.encode(to: encoder)
    }
}

public class BinaryEncoder {
    fileprivate var data: [UInt8] = []
    
    public init() {}
}

public extension BinaryEncoder {
    static func encode(_ value: BinaryEncodable) throws -> [UInt8] {
        let encoder = BinaryEncoder()
        try value.binaryEncode(to: encoder)
        return encoder.data
    }
}

public extension BinaryEncoder {
    enum Error: Swift.Error {
        case typeNotConformingToBinaryEncodable(Encodable.Type)
    }
}

public extension BinaryEncoder {
    func encode(_ value: BinaryEncodable) throws {
        try value.binaryEncode(to: self)
    }
    
    func encode<T: FixedWidthInteger>(_ value: T) {
        switch value {
        case let v as Int:
            encode(Int64(v))
        case let v as UInt:
            encode(UInt64(v))
        default:
            appendBytes(of: value.bigEndian)
        }
    }
    
    func encode(_ value: Float) {
        appendBytes(of: CFConvertFloatHostToSwapped(value))
    }
    
    func encode(_ value: Double) {
        appendBytes(of: CFConvertDoubleHostToSwapped(value))
    }
    
    func encode(_ string: String) {
        let bytes = Array(string.utf8)
        encode(bytes.count)
        data.append(contentsOf: bytes)
    }
    
    func encodeEncodable(_ encodable: Encodable) throws {
        guard let binaryEncodable = encodable as? BinaryEncodable else {
            throw Error.typeNotConformingToBinaryEncodable(type(of: encodable))
        }
        try binaryEncodable.binaryEncode(to: self)
    }
}

private extension BinaryEncoder {
    func appendBytes<T>(of: T) {
        var target = of
        withUnsafeBytes(of: &target) {
            data.append(contentsOf: $0)
        }
    }
}

extension BinaryEncoder: Encoder {
    public var codingPath: [CodingKey?] { return [] }
    
    public var userInfo: [CodingUserInfoKey : Any] { return [:] }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: BinaryEncoder
        
        var codingPath: [CodingKey?] { return [] }
        
        mutating func encode(_ value: Bool, forKey key: Key) throws {
            encoder.encode(value ? 1 : 0 as UInt8)
        }
        
        mutating func encode(_ value: Int, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Int8, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Int16, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Int32, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Int64, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: UInt, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Float, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: Double, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode(_ value: String, forKey key: Key) throws {
            encoder.encode(value)
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            try encoder.encodeEncodable(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
}
