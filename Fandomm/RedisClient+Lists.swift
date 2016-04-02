//
//  RedisClient+Lists.swift
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

public enum PivotType : String
{
    case Before = "BEFORE"
    case After = "AFTER"
}

extension RedisClient
{
    /// BLPOP key [key ...] timeout
    ///
    /// BLPOP is a blocking list pop primitive. It is the blocking version of LPOP because it blocks the connection when there are no elements to pop from any of the given lists.
    /// An element is popped from the head of the first list that is non-empty, with the given keys being checked in the order that they are given.
    ///
    /// - returns: Array reply: specifically: A nil multi-bulk when no element could be popped and the timeout expired. A two-element multi-bulk with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    public func blPop(keys:[String], timeout:UInt = 0, completionHandler:RedisCommandArrayBlock)
    {
        var command = "BLPOP"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        command += " \(timeout)"
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// BRPOP key [key ...] timeout
    ///
    /// BRPOP is a blocking list pop primitive. It is the blocking version of RPOP because it blocks the connection when there are no elements to pop from any of the given lists. 
    /// An element is popped from the tail of the first list that is non-empty, with the given keys being checked in the order that they are given.
    /// See the BLPOP documentation for the exact semantics, since BRPOP is identical to BLPOP with the only difference being that it pops elements from the tail of a list instead of popping from the head.
    ///
    /// - returns: Array reply: specifically: A nil multi-bulk when no element could be popped and the timeout expired. A two-element multi-bulk with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    public func brPop(keys:[String], timeout:UInt = 0, completionHandler:RedisCommandArrayBlock)
    {
        var command = "BRPOP"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        command += " \(timeout)"
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// LINDEX key index
    ///
    /// Returns the element at index index in the list stored at key. The index is zero-based, so 0 means the first element, 1 the second element and so on. 
    /// Negative indices can be used to designate elements starting at the tail of the list. Here, -1 means the last element, -2 means the penultimate and so forth.
    /// When the value at key is not a list, an error is returned.
    ///
    /// - returns: Bulk string reply: the requested element, or nil when index is out of range.
    public func lIndex(key:String, index:Int, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("LINDEX \(RESPUtilities.respStringFromString(key)) \(index)", completionHandler: completionHandler)
    }
    
    /// LINSERT key BEFORE|AFTER pivot value
    ///
    /// Inserts value in the list stored at key either before or after the reference value pivot.
    /// When key does not exist, it is considered an empty list and no operation is performed.
    /// An error is returned when key exists but does not hold a list value.
    ///
    /// - returns: Integer reply: the length of the list after the insert operation, or -1 when the value pivot was not found.
    public func lInsert(key:String, pivotType:PivotType, pivot:String, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("LINSERT \(RESPUtilities.respStringFromString(key)) \(pivotType.rawValue) \(RESPUtilities.respStringFromString(pivot)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// LLEN key
    ///
    /// Returns the length of the list stored at key. If key does not exist, it is interpreted as an empty list and 0 is returned. An error is returned when the value stored at key is not a list.
    /// - returns: Integer reply: the length of the list at key.
    public func lLen(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("LLEN \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// LPOP key
    ///
    /// Removes and returns the first element of the list stored at key.
    ///
    /// - returns: Bulk string reply: the value of the first element, or nil when key does not exist.
    public func lPop(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("LPOP \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// LPUSH key value [value ...]
    ///
    /// Insert all the specified values at the head of the list stored at key. If key does not exist, it is created as empty list before performing the push operations. When key holds a value that is not a list, an error is returned.
    /// It is possible to push multiple elements using a single command call just specifying multiple arguments at the end of the command. Elements are inserted one after the other to the head of the list, from the leftmost element to
    /// the rightmost element. So for instance the command LPUSH mylist a b c will result into a list containing c as first element, b as second element and a as third element.
    ///
    /// - returns: Integer reply: the length of the list after the push operations.
    public func lPush(key:String, values:[String], completionHandler:RedisCommandIntegerBlock) {
        var command = "LPUSH \(RESPUtilities.respStringFromString(key))"
        for value in values {
            command += " \(RESPUtilities.respStringFromString(value))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// LPUSHX key value
    ///
    /// Inserts value at the head of the list stored at key, only if key already exists and holds a list. In contrary to LPUSH, no operation will be performed when key does not yet exist.
    ///
    /// - returns: Integer reply: the length of the list after the push operation.
    public func lPushX(key:String, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("LPUSHX \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// LRANGE key start stop
    ///
    /// Returns the specified elements of the list stored at key. The offsets start and stop are zero-based indexes, with 0 being the first element of the list (the head of the list), 1 being the next element and so on.
    /// These offsets can also be negative numbers indicating offsets starting at the end of the list. For example, -1 is the last element of the list, -2 the penultimate, and so on.
    /// 
    /// - returns: Array reply: list of elements in the specified range.
    public func lRange(key:String, start:Int, stop:Int, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("LRANGE \(RESPUtilities.respStringFromString(key)) \(start) \(stop)", completionHandler: completionHandler)
    }
    
    /// LREM key count value
    ///
    /// Removes the first count occurrences of elements equal to value from the list stored at key. The count argument influences the operation in the following ways:
    /// count > 0: Remove elements equal to value moving from head to tail.
    /// count < 0: Remove elements equal to value moving from tail to head.
    /// count = 0: Remove all elements equal to value.
    /// For example, LREM list -2 "hello" will remove the last two occurrences of "hello" in the list stored at list.
    /// Note that non-existing keys are treated like empty lists, so when key does not exist, the command will always return 0.
    ///
    /// - returns: 
    public func lRem(key:String, count:Int, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("LREM \(RESPUtilities.respStringFromString(key)) \(count) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// LSET key index value
    ///
    /// Sets the list element at index to value. For more information on the index argument, see LINDEX.
    /// An error is returned for out of range indexes.
    /// 
    /// - returns: Simple string reply
    public func lSet(key:String, index:Int, value:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("LSET \(RESPUtilities.respStringFromString(key)) \(index) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
    
    /// LTRIM key start stop
    ///
    /// Trim an existing list so that it will contain only the specified range of elements specified. Both start and stop are zero-based indexes, where 0 is the first element of the list (the head), 1 the next element and so on.
    /// For example: LTRIM foobar 0 2 will modify the list stored at foobar so that only the first three elements of the list will remain.
    /// start and end can also be negative numbers indicating offsets from the end of the list, where -1 is the last element of the list, -2 the penultimate element and so on.
    /// Out of range indexes will not produce an error: if start is larger than the end of the list, or start > end, the result will be an empty list (which causes key to be removed). 
    /// If end is larger than the end of the list, Redis will treat it like the last element of the list.
    /// 
    /// - returns: Simple string reply
    public func lTrim(key:String, start:Int, stop:Int, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("LTRIM \(RESPUtilities.respStringFromString(key)) \(start) \(stop)", completionHandler: completionHandler)
    }
    
    /// RPOP key
    ///
    /// Removes and returns the last element of the list stored at key.
    ///
    /// - returns: Bulk string reply: the value of the last element, or nil when key does not exist.
    public func rPop(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("RPOP \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// RPOPLPUSH source destination
    ///
    /// Atomically returns and removes the last element (tail) of the list stored at source, and pushes the element at the first element (head) of the list stored at destination.
    /// For example: consider source holding the list a,b,c, and destination holding the list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.
    /// If source does not exist, the value nil is returned and no operation is performed. If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, 
    /// so it can be considered as a list rotation command.
    /// 
    /// - returns: Bulk string reply: the element being popped and pushed.
    public func rPopLPush(source:String, destination:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("RPOPLPUSH \(RESPUtilities.respStringFromString(source)) \(RESPUtilities.respStringFromString(destination))", completionHandler: completionHandler)
    }
    
    /// RPUSH key value [value ...]
    ///
    /// Insert all the specified values at the tail of the list stored at key. If key does not exist, it is created as empty list before performing the push operation. When key holds a value that is not a list, an error is returned.
    /// It is possible to push multiple elements using a single command call just specifying multiple arguments at the end of the command. Elements are inserted one after the other to the tail of the list, from the leftmost element
    /// to the rightmost element. So for instance the command RPUSH mylist a b c will result into a list containing a as first element, b as second element and c as third element.
    ///
    /// - returns: Integer reply: the length of the list after the push operation.
    public func rPush(key:String, values:[String], completionHandler:RedisCommandIntegerBlock) {
        var command = "RPUSH \(RESPUtilities.respStringFromString(key))"
        for value in values {
            command += " \(RESPUtilities.respStringFromString(value))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// RPUSHX key value
    ///
    /// Inserts value at the tail of the list stored at key, only if key already exists and holds a list. In contrary to RPUSH, no operation will be performed when key does not yet exist.
    ///
    /// - returns: Integer reply: the length of the list after the push operation.
    public func rPushX(key:String, value:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("RPUSHX \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(value))", completionHandler: completionHandler)
    }
}