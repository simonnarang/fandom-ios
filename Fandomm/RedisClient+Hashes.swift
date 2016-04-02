//
//  RedisClient+Hashes.swift
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

extension RedisClient
{
    
    /// HDEL key field [field ...]
    ///
    /// Removes the specified fields from the hash stored at key. Specified fields that do not exist within this hash are ignored.
    /// If key does not exist, it is treated as an empty hash and this command returns 0.
    ///
    /// - returns: Integer reply: the number of fields that were removed from the hash, not including specified but non existing fields.
    public func hDel(key:String, fields:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "HDEL \(RESPUtilities.respStringFromString(key))"
        for field in fields {
            command = command + " \(RESPUtilities.respStringFromString(field))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// HEXISTS key field
    ///
    /// Returns if field is an existing field in the hash stored at key.
    ///
    /// - returns: Integer reply, specifically: 1 if the hash contains field. 0 if the hash does not contain field, or key does not exist.
    public func hExists(key:String, field:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("HEXISTS \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field))", completionHandler: completionHandler)
    }
    
    /// HGET key field
    ///
    /// Returns the value associated with field in the hash stored at key.
    ///
    /// - returns: Bulk string reply: the value associated with field, or nil when field is not present in the hash or key does not exist.
    public func hGet(key:String, field:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("HGET \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field))", completionHandler: completionHandler)
    }
    
    /// HGETALL key
    ///
    /// Returns all fields and values of the hash stored at key. In the returned value, every field name is followed by its value,
    /// so the length of the reply is twice the size of the hash.
    ///
    /// - returns: Array reply: list of fields and their values stored in the hash, or an empty list when key does not exist.
    public func hGetAll(key:String, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("HGETALL \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    ///// HSTRLEN key field
    /////
    ///// Returns the string length of the value associated with field in the hash stored at key. If the key or the field do not exist, 0 is returned.
    /////
    ///// - returns: Integer reply: the string length of the value associated with field, or zero when field is not present in the hash or key does not exist at all.
    //    public func hStrlen(key:String, field:String, completionHandler:RedisCommandIntegerBlock)
    //    {
    //        self.sendCommandWithIntegerResponse("HSTRLEN \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field))", completionHandler: completionHandler)
    //    }
    
    /// HINCRBY key field increment
    ///
    /// Increments the number stored at field in the hash stored at key by increment. If key does not exist, a new key holding a hash is created. If field does not exist the value is set to 0 before the operation is performed.
    /// The range of values supported by HINCRBY is limited to 64 bit signed integers.
    ///
    /// - returns: Integer reply: the value at field after the increment operation.
    public func hIncr(key:String, field:String, by:Int, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("HINCRBY \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field)) \(by)", completionHandler: completionHandler)
    }
    
    /// HINCRBYFLOAT key field increment
    ///
    /// Increment the specified field of an hash stored at key, and representing a floating point number, by the specified increment.
    /// If the field does not exist, it is set to 0 before performing the operation. An error is returned if one of the following conditions occur:
    /// The field contains a value of the wrong type (not a string).
    /// The current field content or the specified increment are not parsable as a double precision floating point number.
    /// The exact behavior of this command is identical to the one of the INCRBYFLOAT command, please refer to the documentation of INCRBYFLOAT for further information.
    ///
    /// - returns: Bulk string reply: the value of field after the increment.
    public func hIncr(key:String, field:String, byFloat:Double, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("HINCRBYFLOAT \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field)) \(byFloat)", completionHandler: completionHandler)
    }
    
    /// HKEYS key
    ///
    /// Returns all field names in the hash stored at key.
    ///
    /// - returns: Array reply: list of fields in the hash, or an empty list when key does not exist.
    public func hKeys(key:String, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("HKEYS \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// HLEN key
    ///
    /// Returns the number of fields contained in the hash stored at key.
    ///
    /// - returns: Integer reply: number of fields in the hash, or 0 when key does not exist.
    public func hLen(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("HLEN \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// HMGET key field [field ...]
    ///
    /// Returns the values associated with the specified fields in the hash stored at key.
    /// For every field that does not exist in the hash, a nil value is returned. Because a non-existing keys are treated as empty hashes,
    /// running HMGET against a non-existing key will return a list of nil values.
    ///
    /// - returns: Array reply: list of values associated with the given fields, in the same order as they are requested.
    public func hMGet(key:String, fields:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "HMGET \(RESPUtilities.respStringFromString(key))"
        for field:String in fields {
            command = command + " \(RESPUtilities.respStringFromString(field))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// HMSET key field value [field value ...]
    ///
    /// Sets the specified fields to their respective values in the hash stored at key. This command overwrites any existing fields in the hash.
    /// If key does not exist, a new key holding a hash is created.
    ///
    /// - returns: Simple string reply
    public func hMSet(key:String, fieldAndValues:[(field:String, value:String)], completionHandler:RedisCommandStringBlock)
    {
        var command = "HMSET \(RESPUtilities.respStringFromString(key))"
        for (field, value): (String, String) in fieldAndValues {
            command = command + " \(RESPUtilities.respStringFromString(field)) \(RESPUtilities.respStringFromString(value))"
        }
        self.sendCommandWithStringResponse(command, completionHandler: completionHandler)
    }
    
    /// HSET key field value
    ///
    /// Sets field in the hash stored at key to value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
    ///
    /// - returns: Integer reply, specifically: 1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and the value was updated.
    public func hSet(key:String, field:String, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("HSET \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// HSETNX key field value
    ///
    /// Sets field in the hash stored at key to value, only if field does not yet exist. If key does not exist, a new key holding a hash is created. If field already exists, this operation has no effect.
    ///
    /// - returns: Integer reply, specifically: 1 if field is a new field in the hash and value was set. 0 if field already exists in the hash and no operation was performed.
    public func hSetNX(key:String, field:String, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("HSETNX \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(field)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// HVALS key
    ///
    /// Returns all values in the hash stored at key.
    ///
    /// - returns: Array reply: list of values in the hash, or an empty list when key does not exist.
    public func hVals(key:String, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("HVALS \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// HSCAN key cursor [MATCH pattern] [COUNT count]
    ///
    /// HSCAN basic usage
    ///
    /// HSCAN is a cursor based iterator. This means that at every call of the command, the server returns an updated cursor that the user
    /// needs to use as the cursor argument in the next call.
    ///
    /// Scan guarantees
    ///
    /// The HSCAN command, and the other commands in the SCAN family, are able to provide to the user a set of guarantees associated to full iterations.
    /// A full iteration always retrieves all the elements that were present in the collection from the start to the end of a full iteration.
    /// This means that if a given element is inside the collection when an iteration is started, and is still there when an iteration terminates,
    /// then at some point SCAN returned it to the user.
    /// A full iteration never returns any element that was NOT present in the collection from the start to the end of a full iteration.
    /// So if an element was removed before the start of an iteration, and is never added back to the collection for all the time an iteration lasts,
    /// SCAN ensures that this element will never be returned.
    ///
    /// Number of elements returned at every SCAN call
    ///
    /// SCAN family functions do not guarantee that the number of elements returned per call are in a given range.
    /// The commands are also allowed to return zero elements, and the client should not consider the iteration complete as long as the returned cursor is not zero.
    ///
    /// The COUNT option
    ///
    /// While HSCAN does not provide guarantees about the number of elements returned at every iteration,
    /// it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    /// Basically with COUNT the user specified the amount of work that should be done at every call in order to retrieve elements from the collection.
    /// This is just an hint for the implementation, however generally speaking this is what you could expect most of the times from the implementation.
    /// The default COUNT value is 10.
    /// When iterating the key space, or a Set, Hash or Sorted Set that is big enough to be represented by an hash table, assuming no MATCH option is used,
    /// the server will usually return count or a bit more than count elements per call.
    /// When iterating Sets encoded as intsets (small sets composed of just integers), or Hashes and Sorted Sets encoded as ziplists
    /// (small hashes and sets composed of small individual values), usually all the elements are returned in the first SCAN call regardless of the COUNT value.
    ///
    /// The MATCH option
    ///
    /// It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    /// To do so, just append the MATCH <pattern> arguments at the end of the SCAN command (it works with all the SCAN family commands).
    ///
    /// - returns: HSCAN return a two elements multi-bulk reply, where the first element is a string representing an unsigned 64 bit number (the cursor), and the second element is a multi-bulk with an array of elements. HSCAN array of elements is a list of keys.
    public func hScan(key:String, cursor:UInt, pattern:String? = nil, count:UInt? = nil, completionHandler:RedisCommandArrayBlock)
    {
        var command:String = "HSCAN \(RESPUtilities.respStringFromString(key)) \(cursor)"
        if pattern != nil {
            command = command + " MATCH \(RESPUtilities.respStringFromString(pattern!))"
        }
        if count != nil {
            command = command + " COUNT \(count!)"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
}