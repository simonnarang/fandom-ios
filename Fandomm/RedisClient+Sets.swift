//
//  RedisClient+Sets.swift
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
    /// SADD key member [member ...]
    ///
    /// Add the specified members to the set stored at key. Specified members that are already a member of this set are ignored. If key does not exist, a new set is created before adding the specified members.
    /// An error is returned when the value stored at key is not a set.
    /// 
    /// - returns: Integer reply: the number of elements that were added to the set, not including all the elements already present into the set.
    public func sAdd(key:String, members:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "SADD \(RESPUtilities.respStringFromString(key))"
        for member in members {
            command += " \(RESPUtilities.respStringFromString(member))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// SCARD key
    /// 
    /// Returns the set cardinality (number of elements) of the set stored at key.
    ///
    /// - returns: Integer reply: the cardinality (number of elements) of the set, or 0 if key does not exist.
    public func sCard(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("SCARD \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// SDIFF key [key ...]
    ///
    /// Returns the members of the set resulting from the difference between the first set and all the successive sets.
    ///
    /// - returns: Array reply: list with members of the resulting set.
    public func sDiff(key:String, keys:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "SDIFF \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// SDIFFSTORE destination key [key ...]
    ///
    /// This command is equal to SDIFF, but instead of returning the resulting set, it is stored in destination.
    /// If destination already exists, it is overwritten.
    ///
    /// - returns: Integer reply: the number of elements in the resulting set.
    public func sDiffStore(destination:String, key:String, keys:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "SDIFFSTORE \(RESPUtilities.respStringFromString(destination)) \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// SINTER key [key ...]
    ///
    /// Returns the members of the set resulting from the intersection of all the given sets.
    /// Keys that do not exist are considered to be empty sets. With one of the keys being an empty set, the resulting set is also empty (since set intersection with an empty set always results in an empty set).
    ///
    /// - returns: Array reply: list with members of the resulting set.
    public func sInter(key:String, keys:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "SINTER \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// SINTERSTORE destination key [key ...]
    ///
    /// This command is equal to SINTER, but instead of returning the resulting set, it is stored in destination.
    /// If destination already exists, it is overwritten.
    ///
    /// - returns: Integer reply: the number of elements in the resulting set.
    public func sIncrStore(destination:String, key:String, keys:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "SINTERSTORE \(RESPUtilities.respStringFromString(destination)) \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// SISMEMBER key member
    ///
    /// Returns if member is a member of the set stored at key.
    ///
    /// Integer reply, specifically. 1 if the element is a member of the set. 0 if the element is not a member of the set, or if key does not exist.
    public func sIsMember(key:String, member:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("SISMEMBER \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(member))", completionHandler: completionHandler)
    }
    
    /// SMEMBERS key
    ///
    /// Returns all the members of the set value stored at key. This has the same effect as running SINTER with one argument key.
    ///
    /// - returns: Array reply: all elements of the set.
    public func sMembers(key:String, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("SMEMBERS \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// SMOVE source destination member
    ///
    /// Move member from the set at source to the set at destination. This operation is atomic. In every given moment the element will appear to be a member of source or destination for other clients.
    /// If the source set does not exist or does not contain the specified element, no operation is performed and 0 is returned. Otherwise, the element is removed from the source set and added to the destination set. 
    /// When the specified element already exists in the destination set, it is only removed from the source set.
    /// An error is returned if source or destination does not hold a set value.
    ///
    /// - returns: Integer reply, specifically: 1 if the element is moved. 0 if the element is not a member of source and no operation was performed.
    public func sMove(source:String, destination:String, member:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("SMOVE \(RESPUtilities.respStringFromString(source)) \(RESPUtilities.respStringFromString(destination)) \(RESPUtilities.respStringFromString(member))", completionHandler: completionHandler)
    }
    
    /// SPOP key
    ///
    /// Removes and returns one or more random elements from the set value store at key.
    /// This operation is similar to SRANDMEMBER, that returns one or more random elements from a set but does not remove it.
    /// The count argument will be available in 3.0 and is not available in 2.6 or 2.8
    ///
    /// - returns: Bulk string reply: the removed element, or nil when key does not exist.
    public func sPop(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("SPOP \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// SRANDMEMBER key
    /// 
    /// When called with just the key argument, return a random element from the set value stored at key.
    /// Starting from Redis version 2.6, when called with the additional count argument, return an array of count distinct elements if count is positive. 
    /// If called with a negative count the behavior changes and the command is allowed to return the same element multiple times. In this case the number of returned elements is the absolute value of the specified count.
    /// When called with just the key argument, the operation is similar to SPOP, however while SPOP also removes the randomly selected element from the set, SRANDMEMBER will just return a random element without altering the original set in any way.
    /// 
    /// - returns: Bulk string reply: without the additional count argument the command returns a Bulk Reply with the randomly selected element, or nil when key does not exist.
    public func sRandMember(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("SRANDMEMBER \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// SRANDMEMBER key [count]
    ///
    /// When called with just the key argument, return a random element from the set value stored at key.
    /// Starting from Redis version 2.6, when called with the additional count argument, return an array of count distinct elements if count is positive.
    /// If called with a negative count the behavior changes and the command is allowed to return the same element multiple times. In this case the number of returned elements is the absolute value of the specified count.
    /// When called with just the key argument, the operation is similar to SPOP, however while SPOP also removes the randomly selected element from the set, SRANDMEMBER will just return a random element without altering the original set in any way.
    ///
    /// - returns: Array reply: when the additional count argument is passed the command returns an array of elements, or an empty array when key does not exist.

    public func sRandMember(key:String, count:Int, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("SRANDMEMBER \(RESPUtilities.respStringFromString(key)) \(count)", completionHandler: completionHandler)
    }
    
    /// SREM key member [member ...]
    ///
    /// Remove the specified members from the set stored at key. Specified members that are not a member of this set are ignored. If key does not exist, it is treated as an empty set and this command returns 0.
    /// An error is returned when the value stored at key is not a set.
    ///
    /// - returns: Integer reply: the number of members that were removed from the set, not including non existing members.
    public func sRem(key:String, members:[String], completionHandler:RedisCommandIntegerBlock) {
        var command = "SREM \(RESPUtilities.respStringFromString(key))"
        for member in members {
            command += " \(RESPUtilities.respStringFromString(member))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// SSCAN key cursor [MATCH pattern] [COUNT count]
    ///
    /// SSCAN basic usage
    ///
    /// SSCAN is a cursor based iterator. This means that at every call of the command, the server returns an updated cursor that the user
    /// needs to use as the cursor argument in the next call.
    ///
    /// Scan guarantees
    ///
    /// The SSCAN command, and the other commands in the SCAN family, are able to provide to the user a set of guarantees associated to full iterations.
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
    /// While SSCAN does not provide guarantees about the number of elements returned at every iteration,
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
    /// - returns: SSCAN return a two elements multi-bulk reply, where the first element is a string representing an unsigned 64 bit number (the cursor), and the second element is a multi-bulk with an array of elements. SSCAN array of elements is a list of keys.
    public func sScan(key:String, cursor:UInt, pattern:String? = nil, count:UInt? = nil, completionHandler:RedisCommandArrayBlock)
    {
        var command:String = "SSCAN \(RESPUtilities.respStringFromString(key)) \(cursor)"
        if pattern != nil {
            command = command + " MATCH \(RESPUtilities.respStringFromString(pattern!))"
        }
        if count != nil {
            command = command + " COUNT \(count!)"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// SUNION key [key ...]
    ///
    /// Returns the members of the set resulting from the union of all the given sets.
    ///
    /// - returns: Array reply: list with members of the resulting set.
    public func sUnion(key:String, keys:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "SUNION \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// SUNIONSTORE destination key [key ...]
    ///
    /// This command is equal to SUNION, but instead of returning the resulting set, it is stored in destination.
    /// If destination already exists, it is overwritten.
    /// 
    /// - returns: Integer reply: the number of elements in the resulting set.
    public func sUnionStore(destination:String, key:String, keys:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command = "SUNIONSTORE \(RESPUtilities.respStringFromString(destination)) \(RESPUtilities.respStringFromString(key))"
        for key in keys {
            command += " \(RESPUtilities.respStringFromString(key))"
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
}