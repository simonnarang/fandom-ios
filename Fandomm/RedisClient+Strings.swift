//
//  RedisClient+Strings.swift
//  Redis-Framework
//
//  Copyright (c) 2015, Eric Orion Anderson
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this
//  list of conditions and the following disclaimer in the documentation and/or
//  other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

public enum RedisSetType:String
{
    case Default = "N/A"
    case OnlySetIfKeyDoesNotAlreadyExist = "NX"
    case OnlySetIfKeyAlreadyExists = "XX"
}

public enum RedisBitOpType:String {
    case AND = "AND"
    case OR = "OR"
    case XOR = "XOR"
    case NOT = "NOT"
}

public enum RedisBitType:String {
    case Zero = "0"
    case One = "1"
}

extension RedisClient
{
    /// APPEND key value
    ///
    /// If key already exists and is a string, this command appends the value at the end of the string.
    /// If key does not exist it is created and set as an empty string, so APPEND will be similar to SET in this special case.
    ///
    /// - returns: Integer reply: the length of the string after the append operation.
    public func append(string:String, toKey key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("APPEND \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(string))", completionHandler: completionHandler)
    }
    
    /// BITCOUNT key [start end]
    ///
    /// Count the number of set bits (population counting) in a string.
    /// By default all the bytes contained in the string are examined. It is possible to specify the counting operation only in an interval passing the additional arguments start and end.
    /// Like for the GETRANGE command start and end can contain negative values in order to index bytes starting from the end of the string, where -1 is the last byte, -2 is the penultimate, and so forth.
    /// Non-existent keys are treated as empty strings, so the command will return zero.
    ///
    /// - returns: Integer reply: The number of bits set to 1.
    public func bitCount(key:String, range:(start:Int, end:Int)? = nil, completionHandler:RedisCommandIntegerBlock)
    {
        var command:String = "BITCOUNT \(RESPUtilities.respStringFromString(key))"
        if range != nil {
            command = command + " \(range!.start) \(range!.end)"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// BITOP operation destkey key [key ...]
    ///
    /// Perform a bitwise operation between multiple keys (containing string values) and store the result in the destination key.
    /// The BITOP command supports four bitwise operations: AND, OR, XOR and NOT, thus the valid forms to call the command are:
    /// BITOP AND destkey srckey1 srckey2 srckey3 ... srckeyN
    /// BITOP OR destkey srckey1 srckey2 srckey3 ... srckeyN
    /// BITOP XOR destkey srckey1 srckey2 srckey3 ... srckeyN
    /// BITOP NOT destkey srckey
    /// As you can see NOT is special as it only takes an input key, because it performs inversion of bits so it only makes sense as an unary operator.
    /// The result of the operation is always stored at destkey.
    ///
    /// Handling of strings with different lengths
    /// When an operation is performed between strings having different lengths, all the strings shorter than the longest string in the set are treated as if they were zero-padded up to the length of the longest string.
    /// The same holds true for non-existent keys, that are considered as a stream of zero bytes up to the length of the longest string.
    ///
    /// - returns: Integer reply: The size of the string stored in the destination key, that is equal to the size of the longest input string.
    public func bitOp(bitOpType:RedisBitOpType, destinationKey:String, keys:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "BITOP \(bitOpType.rawValue) \(RESPUtilities.respStringFromString(destinationKey))"
        for key in keys {
            command = command + " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    
    /// BITPOS key bit [start] [end]
    ///
    /// Return the position of the first bit set to 1 or 0 in a string.
    /// The position is returned, thinking of the string as an array of bits from left to right, where the first byte's most significant bit is at position 0,
    /// the second byte's most significant bit is at position 8, and so forth.
    /// The same bit position convention is followed by GETBIT and SETBIT.
    /// By default, all the bytes contained in the string are examined. It is possible to look for bits only in a specified interval passing the additional arguments
    /// start and end (it is possible to just pass start, the operation will assume that the end is the last byte of the string. However there are semantical
    /// differences as explained later). The range is interpreted as a range of bytes and not a range of bits, so start=0 and end=2 means to look at the first three bytes.
    /// Note that bit positions are returned always as absolute values starting from bit zero even when start and end are used to specify a range.
    /// Like for the GETRANGE command start and end can contain negative values in order to index bytes starting from the end of the string, where -1 is the last byte,
    /// -2 is the penultimate, and so forth.
    /// Non-existent keys are treated as empty strings.
    ///
    /// - returns: Integer reply: The command returns the position of the first bit set to 1 or 0 according to the request. If we look for set bits (the bit argument is 1) and the string is empty or composed of just zero bytes, -1 is returned. If we look for clear bits (the bit argument is 0) and the string only contains bit set to 1, the function returns the first bit not part of the string on the right. So if the string is three bytes set to the value 0xff the command BITPOS key 0 will return 24, since up to bit 23 all the bits are 1. Basically, the function considers the right of the string as padded with zeros if you look for clear bits and specify no range or the start argument only. However, this behavior changes if you are looking for clear bits and specify a range with both start and end. If no clear bit is found in the specified range, the function returns -1 as the user specified a clear range and there are no 0 bits in that range.
    public func bitPos(key:String, bitType:RedisBitType, rangeOfBytes range:(start:Int, end:Int?) = (0, nil), completionHandler:RedisCommandIntegerBlock)
    {
        var command:String = "BITPOS \(RESPUtilities.respStringFromString(key)) \(bitType.rawValue) \(range.start)"
        if range.end != nil {
            command = command + " \(range.end!)"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// DECR key
    ///
    /// Decrements the number stored at key by one. If the key does not exist, it is set to 0 before performing the operation.
    /// An error is returned if the key contains a value of the wrong type or contains a string that can not be represented as integer. This operation is limited to 64 bit signed integers.
    /// See INCR for extra information on increment/decrement operations.
    ///
    /// - returns: Integer reply: the value of key after the decrement
    public func decr(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("DECR \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// DECRBY key decrement
    ///
    /// Decrements the number stored at key by decrement. If the key does not exist, it is set to 0 before performing the operation.
    /// An error is returned if the key contains a value of the wrong type or contains a string that can not be represented as integer.
    /// This operation is limited to 64 bit signed integers.
    /// See INCR for extra information on increment/decrement operations.
    ///
    /// - returns: Integer reply: the value of key after the decrement
    public func decr(key:String, by:UInt, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("DECRBY \(RESPUtilities.respStringFromString(key)) \(by)", completionHandler: completionHandler)
    }
    
    /// GET key
    ///
    /// Get the value of key. If the key does not exist the special value nil is returned. An error is returned if the value stored at key is not a string, because GET only handles string values.
    ///
    /// - returns: Bulk string reply: the value of key, or nil when key does not exist.
    public func get(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("GET \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// GETBIT key offset
    ///
    /// Returns the bit value at offset in the string value stored at key.
    /// When offset is beyond the string length, the string is assumed to be a contiguous space with 0 bits.
    /// When key does not exist it is assumed to be an empty string, so offset is always out of range and the value is also assumed to be a contiguous space with 0 bits.
    ///
    /// - returns: Integer reply: the bit value stored at offset.
    public func getBit(key:String, offset:UInt, completionHandler:((bit:RedisBitType!, error:NSError!)->Void))
    {
        self.sendCommandWithIntegerResponse("GETBIT \(RESPUtilities.respStringFromString(key)) \(offset)", completionHandler: { (int, error) -> Void in
            if error != nil
            {
                completionHandler(bit: nil, error: error)
            }
            else
            {
                var bit:RedisBitType
                if int > 0 {
                    bit = RedisBitType.One
                }
                else {
                    bit = RedisBitType.Zero
                }
                completionHandler(bit: bit, error: nil)
            }
        })
    }
    
    /// GETRANGE key start end
    ///
    /// Returns the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    /// Negative offsets can be used in order to provide an offset starting from the end of the string. So -1 means the last character, -2 the penultimate and so forth.
    /// The function handles out of range requests by limiting the resulting range to the actual length of the string.
    ///
    /// - returns: Bulk string reply
    public func getRange(key:String, range:(start:Int, end:Int), completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("GETRANGE \(RESPUtilities.respStringFromString(key)) \(range.start) \(range.end)", completionHandler: completionHandler)
    }
    
    /// GETSET key value
    ///
    /// Atomically sets key to value and returns the old value stored at key. Returns an error when key exists but does not hold a string value.
    /// GETSET can be used together with INCR for counting with atomic reset. For example: a process may call INCR against the key mycounter every
    /// time some event occurs, but from time to time we need to get the value of the counter and reset it to zero atomically.
    ///
    /// - returns: Bulk string reply: the old value stored at key, or nil when key did not exist.
    public func getSet(key:String, value:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("GETSET \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// INCR key
    ///
    /// Increments the number stored at key by one. If the key does not exist, it is set to 0 before performing the operation.
    /// An error is returned if the key contains a value of the wrong type or contains a string that can not be represented as integer. This operation is limited to 64 bit signed integers.
    ///
    /// - returns: Integer reply: the value of key after the increment
    public func incr(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("INCR \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// INCRBY key increment
    ///
    /// Increments the number stored at key by increment. If the key does not exist, it is set to 0 before performing the operation.
    /// An error is returned if the key contains a value of the wrong type or contains a string that can not be represented as integer. This operation is limited to 64 bit signed integers.
    /// See INCR for extra information on increment/decrement operations.
    ///
    /// - returns: Integer reply: the value of key after the increment
    public func incr(key:String, by:UInt, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("INCRBY \(RESPUtilities.respStringFromString(key)) \(by)", completionHandler: completionHandler)
    }
    
    /// INCRBYFLOAT key increment
    ///
    /// Increment the string representing a floating point number stored at key by the specified increment. If the key does not exist,
    /// it is set to 0 before performing the operation. An error is returned if one of the following conditions occur:
    /// The key contains a value of the wrong type (not a string).
    /// The current key content or the specified increment are not parsable as a double precision floating point number.
    /// If the command is successful the new incremented value is stored as the new value of the key (replacing the old one), and returned to the caller as a string.
    /// Both the value already contained in the string key and the increment argument can be optionally provided in exponential notation, however the value computed
    /// after the increment is stored consistently in the same format, that is, an integer number followed (if needed) by a dot, and a variable number of digits
    /// representing the decimal part of the number. Trailing zeroes are always removed.
    /// The precision of the output is fixed at 17 digits after the decimal point regardless of the actual internal precision of the computation.
    ///
    /// - returns: Bulk string reply: the value of key after the increment.
    public func incrFloat(key:String, by:Double, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("INCRBYFLOAT \(RESPUtilities.respStringFromString(key)) \(by)", completionHandler: completionHandler)
    }
    
    /// MGET key [key ...]
    ///
    /// Returns the values of all specified keys. For every key that does not hold a string value or does not exist, the special value nil is returned.
    /// Because of this, the operation never fails.
    ///
    /// - returns: Array reply: list of values at the specified keys.
    public func mGet(keys:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "MGET"
        for key in keys {
            command = command + " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// MSET key value [key value ...]
    ///
    /// Sets the given keys to their respective values. MSET replaces existing values with new values, just as regular SET.
    /// See MSETNX if you don't want to overwrite existing values.
    /// MSET is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.
    ///
    /// - returns: Simple string reply: always OK since MSET can't fail.
    public func mSet(keys:[String], values:[AnyObject], completionHandler:RedisCommandStringBlock)
    {
        var command:String = "MSET"
        for(index, key) in keys.enumerate()
        {
            let value:AnyObject = values[index]
            if value is String {
                command = command + " \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(value as! String))"
            }
            else if value is Int {
                command = command + " \(RESPUtilities.respStringFromString(key)) \(value as! Int))"
            }
        }
        self.sendCommandWithStringResponse(command, completionHandler: completionHandler)
    }
    
    
    
    /// MSETNX key value [key value ...]
    ///
    /// Sets the given keys to their respective values. MSETNX will not perform any operation at all even if just a single key already exists.
    /// Because of this semantic MSETNX can be used in order to set different keys representing different fields of an unique logic object in
    /// a way that ensures that either all the fields or none at all are set.
    /// MSETNX is atomic, so all given keys are set at once. It is not possible for clients to see that some of the keys were updated while others are unchanged.
    ///
    /// - returns: Integer reply, specifically: 1 if the all the keys were set. 0 if no key was set (at least one key already existed).
    public func mSetNX(keys:[String], values:[AnyObject], completionHandler:RedisCommandIntegerBlock)
    {
        var command:String = "MSETNX"
        for(index, key) in keys.enumerate()
        {
            let value:AnyObject = values[index]
            if value is String {
                command = command + " \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(value as! String))"
            }
            else if value is Int {
                command = command + " \(RESPUtilities.respStringFromString(key)) \(value as! Int))"
            }
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    
    // PSETEX key milliseconds value
    //
    // PSETEX works exactly like SETEX with the sole difference that the expire time is specified in milliseconds instead of seconds.
    //
    // NOTE: Not to be implemented, included functionality in similar SET method below
    
    
    /// SET key value [EX seconds] [PX milliseconds] [NX|XX]
    ///
    /// - returns: Simple string reply: OK if SET was executed correctly. Null reply: a Null Bulk Reply is returned if the SET operation was not performed becase the user specified the NX or XX option but the condition was not met.
    public func set(key:String, value:String, expireTimeInSeconds:Int? = nil, expireTimeInMilliseconds:Int? = nil, setType:RedisSetType = .Default, completionHandler:RedisCommandStringBlock)
    {
        var command:String = "SET " + RESPUtilities.respStringFromString(key) + " " + RESPUtilities.respStringFromString(value)
        if expireTimeInSeconds != nil {
            command = command + " EX \(expireTimeInSeconds!)"
        }
        if expireTimeInMilliseconds != nil {
            command = command + " PX \(expireTimeInMilliseconds!)"
        }
        switch(setType)
        {
            case .OnlySetIfKeyAlreadyExists:
                command = command + " \(RedisSetType.OnlySetIfKeyAlreadyExists.rawValue)"
            default: break
        }
        self.sendCommandWithStringResponse(command, completionHandler: completionHandler)
    }
    
    /// SETBIT key offset value
    ///
    /// Sets or clears the bit at offset in the string value stored at key.
    /// The bit is either set or cleared depending on value, which can be either 0 or 1. When key does not exist, a new string value is created. The string is grown to make sure it can hold a bit at offset. The offset argument is required to be greater than or equal to 0, and smaller than 232 (this limits bitmaps to 512MB). When the string at key is grown, added bits are set to 0.
    ///
    /// Warning: When setting the last possible bit (offset equal to 232 -1) and the string value stored at key does not yet hold a string value, or holds a small string value, Redis needs to allocate all intermediate memory which can block the server for some time. On a 2010 MacBook Pro, setting bit number 232 -1 (512MB allocation) takes ~300ms, setting bit number 230 -1 (128MB allocation) takes ~80ms, setting bit number 228 -1 (32MB allocation) takes ~30ms and setting bit number 226 -1 (8MB allocation) takes ~8ms. Note that once this first allocation is done, subsequent calls to SETBIT for the same key will not have the allocation overhead.
    ///
    /// - returns: Integer reply: the original bit value stored at offset.
    public func setBit(key:String, offset:UInt, value:RedisBitType, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("SETBIT \(RESPUtilities.respStringFromString(key)) \(offset) \(value.rawValue)", completionHandler: completionHandler)
    }
    
    //  SETEX key seconds value
    //  Set the value and expiration of a key
    //  NOTE: Not to be implemented, included functionality in similar SET method above
    
    //  SETNX key value
    //  Set the value of a key, only if the key does not exist
    //  NOTE: Not to be implemented, included functionality in similar SET method above
    
    /// SETRANGE key offset value
    ///
    /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value. If the offset is larger than the current length of the string at key, the string is padded with zero-bytes to make offset fit. Non-existing keys are considered as empty strings, so this command will make sure it holds a string large enough to be able to set value at offset.
    ///
    /// Note that the maximum offset that you can set is 229 -1 (536870911), as Redis Strings are limited to 512 megabytes. If you need to grow beyond this size, you can use multiple keys.
    ///
    /// Warning: When setting the last possible byte and the string value stored at key does not yet hold a string value, or holds a small string value, Redis needs to allocate all intermediate memory which can block the server for some time. On a 2010 MacBook Pro, setting byte number 536870911 (512MB allocation) takes ~300ms, setting byte number 134217728 (128MB allocation) takes ~80ms, setting bit number 33554432 (32MB allocation) takes ~30ms and setting bit number 8388608 (8MB allocation) takes ~8ms. Note that once this first allocation is done, subsequent calls to SETRANGE for the same key will not have the allocation overhead.
    ///
    /// - returns: Integer reply: the length of the string after it was modified by the command.
    public func setRange(key:String, offset:Int, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("SETRANGE \(RESPUtilities.respStringFromString(key)) \(offset) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// STRLEN key
    ///
    /// Returns the length of the string value stored at key. An error is returned when key holds a non-string value.
    /// 
    /// - returns: Integer reply: the length of the string at key, or 0 when key does not exist.
    public func strlen(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("STRLEN \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
}