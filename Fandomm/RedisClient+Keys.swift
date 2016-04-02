//
//  RedisClient+Keys.swift
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

public enum RedisMigrationType:String
{
    case Copy = "COPY"
    case Replace = "REPLACE"
}

public enum RedisObjectSubCommand:String
{
    case RefCount = "REFCOUNT"
    case Encoding = "ENCODING"
    case IdleTime = "IDLETIME"
}

extension RedisClient
{
    
    /// DEL key [key ...] Removes the specified keys. A key is ignored if it does not exist.
    ///
    /// - returns: Integer reply: The number of keys that were removed.
    public func delete(keys:[String], completionHandler:RedisCommandIntegerBlock)
    {
        var command:String = "DEL"
        for(_, key) in keys.enumerate() {
            command = command + " " + RESPUtilities.respStringFromString(key)
        }
        self.sendCommandWithIntegerResponse(command, completionHandler: completionHandler)
    }
    
    /// DUMP key
    ///
    /// Serialize the value stored at key in a Redis-specific format and return it to the user. The returned value can be synthesized back into a Redis key using the RESTORE command.
    /// The serialization format is opaque and non-standard, however it has a few semantical characteristics:
    /// It contains a 64-bit checksum that is used to make sure errors will be detected. The RESTORE command makes sure to check the checksum before synthesizing a key using the serialized value.
    /// Values are encoded in the same format used by RDB.
    /// An RDB version is encoded inside the serialized value, so that different Redis versions with incompatible RDB formats will refuse to process the serialized value.
    /// The serialized value does NOT contain expire information. In order to capture the time to live of the current value the PTTL command should be used.
    /// If key does not exist a nil bulk reply is returned.
    ///
    /// - returns: Bulk string reply: the serialized value.  *NOTE* This is not fully tested and doesn't encode directly to UTF-8
    public func dump(key:String, completionHandler:RedisCommandDataBlock)
    {
        self.sendCommandWithDataResponse("DUMP \(RESPUtilities.respStringFromString(key))", completionHandler: { (data, error) -> Void in
            if error != nil {
                completionHandler(data: nil, error: error)
            }
            else //custom parsing for binary data, not UTF-8 compliant
            {
                let customData:NSData = data
                let clrfData:NSData = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
                let crlfFirstRange:NSRange = customData.rangeOfData(clrfData, options: NSDataSearchOptions(), range: NSMakeRange(0, customData.length))
                if crlfFirstRange.location != NSNotFound //simple check for the first \r\n
                {
                    let crlfEndRange:NSRange = customData.rangeOfData(clrfData, options: NSDataSearchOptions.Backwards, range: NSMakeRange(0, customData.length))
                    if crlfEndRange.location != crlfFirstRange.location //assuming found last \r\n
                    {
                        let serialzedData:NSData = customData.subdataWithRange(NSMakeRange(crlfFirstRange.location+crlfFirstRange.length, customData.length-(crlfFirstRange.location+crlfFirstRange.length)-(crlfFirstRange.length)))
                        completionHandler(data: serialzedData, error: nil)
                        return
                    }
                }
                completionHandler(data: nil, error: NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:"Unexpected response format"]))
            }
        })
    }
    
    /// EXISTS key
    ///
    /// Returns if key exists.
    ///
    /// - returns: Integer reply, specifically: 1 if the key exists. 0 if the key does not exist.
    public func exists(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("EXISTS \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// EXPIRE key seconds
    ///
    /// Set a timeout on key. After the timeout has expired, the key will automatically be deleted. A key with an associated timeout is
    /// often said to be volatile in Redis terminology.
    /// The timeout is cleared only when the key is removed using the DEL command or overwritten using the SET or GETSET commands.
    /// This means that all the operations that conceptually alter the value stored at the key without replacing it with a new one will
    /// leave the timeout untouched. For instance, incrementing the value of a key with INCR, pushing a new value into a list with LPUSH,
    /// or altering the field value of a hash with HSET are all operations that will leave the timeout untouched.
    /// The timeout can also be cleared, turning the key back into a persistent key, using the PERSIST command.
    /// If a key is renamed with RENAME, the associated time to live is transferred to the new key name.
    /// If a key is overwritten by RENAME, like in the case of an existing key Key_A that is overwritten by a call like RENAME Key_B Key_A,
    /// it does not matter if the original Key_A had a timeout associated or not, the new key Key_A will inherit all the characteristics of Key_B.
    ///
    /// Refreshing expires
    ///
    /// It is possible to call EXPIRE using as argument a key that already has an existing expire set. In this case the time to live of a key is
    /// updated to the new value. There are many useful applications for this, an example is documented in the Navigation session pattern section below.
    ///
    /// - returns: Integer reply, specifically: 1 if the timeout was set. 0 if key does not exist or the timeout could not be set.
    public func expire(key:String, timeoutInSeconds:Int, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("EXPIRE \(RESPUtilities.respStringFromString(key)) \(timeoutInSeconds)", completionHandler: completionHandler)
    }
    
    /// EXPIREAT key timestamp
    ///
    /// EXPIREAT has the same effect and semantic as EXPIRE, but instead of specifying the number of seconds representing the TTL (time to live),
    /// it takes an absolute Unix timestamp (seconds since January 1, 1970).
    /// Please for the specific semantics of the command refer to the documentation of EXPIRE.
    ///
    /// - returns: Integer reply, specifically: 1 if the timeout was set. 0 if key does not exist or the timeout could not be set (see: EXPIRE).
    public func expire(key:String, at date:NSDate, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("EXPIREAT \(RESPUtilities.respStringFromString(key)) \(Int(date.timeIntervalSince1970))", completionHandler: completionHandler)
    }
    
    /// KEYS pattern
    ///
    /// Returns all keys matching pattern.
    /// While the time complexity for this operation is O(N), the constant times are fairly low. For example,
    /// Redis running on an entry level laptop can scan a 1 million key database in 40 milliseconds.
    /// Warning: consider KEYS as a command that should only be used in production environments with extreme care.
    /// It may ruin performance when it is executed against large databases. This command is intended for debugging and special operations,
    /// such as changing your keyspace layout. Don't use KEYS in your regular application code. If you're looking for a way to find keys in a subset of your keyspace,
    /// consider using SCAN or sets.
    /// Supported glob-style patterns:
    ///
    ///     h?llo matches hello, hallo and hxllo
    ///
    ///     h*llo matches hllo and heeeello
    ///
    ///     h[ae]llo matches hello and hallo, but not hillo
    ///
    ///     Use \ to escape special characters if you want to match them verbatim.
    ///
    /// - returns: Array reply: list of keys matching pattern.
    public func keys(pattern:String, completionHandler:RedisCommandArrayBlock) {
        self.sendCommandWithArrayResponse("KEYS \(RESPUtilities.respStringFromString(pattern))", completionHandler: completionHandler)
    }
    
    /// MIGRATE host port key destination-db timeout [COPY] [REPLACE]
    ///
    /// Atomically transfer a key from a source Redis instance to a destination Redis instance. On success the key is deleted from the
    /// original instance and is guaranteed to exist in the target instance.
    /// The command is atomic and blocks the two instances for the time required to transfer the key, at any given time the key will
    /// appear to exist in a given instance or in the other instance, unless a timeout error occurs.
    /// The command internally uses DUMP to generate the serialized version of the key value, and RESTORE in order to synthesize the key in the target instance.
    /// The source instance acts as a client for the target instance. If the target instance returns OK to the RESTORE command, the source instance deletes the key using DEL.
    /// The timeout specifies the maximum idle time in any moment of the communication with the destination instance in milliseconds.
    /// This means that the operation does not need to be completed within the specified amount of milliseconds,
    /// but that the transfer should make progresses without blocking for more than the specified amount of milliseconds.
    /// MIGRATE needs to perform I/O operations and to honor the specified timeout. When there is an I/O error during the transfer or if the timeout
    /// is reached the operation is aborted and the special error - IOERR returned. When this happens the following two cases are possible:
    /// The key may be on both the instances.
    /// The key may be only in the source instance.
    /// It is not possible for the key to get lost in the event of a timeout, but the client calling MIGRATE, in the event of a timeout error,
    /// should check if the key is also present in the target instance and act accordingly.
    /// When any other error is returned (starting with ERR) MIGRATE guarantees that the key is still only present in the originating instance
    /// (unless a key with the same name was also already present on the target instance).
    ///
    /// - returns: Simple string reply: On success OK is returned.
    public func migrate(host:String, port:Int, key:String, destinationDB:String, timeoutInMilliseconds:Int, migrationType:RedisMigrationType, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("MIGRATE \(host) \(port) \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(destinationDB)) \(timeoutInMilliseconds) \(migrationType.rawValue)", completionHandler: completionHandler)
    }
    
    /// MOVE key db
    ///
    /// Move key from the currently selected database (see SELECT) to the specified destination database.
    /// When key already exists in the destination database, or it does not exist in the source database,
    /// it does nothing. It is possible to use MOVE as a locking primitive because of this.
    ///
    /// - returns: Integer reply, specifically: 1 if key was moved. 0 if key was not moved.
    public func move(key:String, db:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("MOVE \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(db))", completionHandler: completionHandler)
    }
    
    /// OBJECT REFCOUNT key
    ///
    /// The OBJECT command allows to inspect the internals of Redis Objects associated with keys. It is useful for debugging or to understand if your keys
    /// are using the specially encoded data types to save space. Your application may also use the information reported by the OBJECT command to implement
    /// application level key eviction policies when using Redis as a Cache.
    ///
    /// - returns: Interger reply: The number of references of the value associated with the specified key. This command is mainly useful for debugging.
    public func objectRefCount(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("OBJECT REFCOUNT \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// OBJECT ENCODING key
    ///
    /// The OBJECT command allows to inspect the internals of Redis Objects associated with keys. It is useful for debugging or to understand if your keys
    /// are using the specially encoded data types to save space. Your application may also use the information reported by the OBJECT command to implement
    /// application level key eviction policies when using Redis as a Cache.
    ///
    /// Objects can be encoded in different ways:
    /// Strings can be encoded as raw (normal string encoding) or int (strings representing integers in a 64 bit signed interval are encoded in this way in order to save space).
    /// Lists can be encoded as ziplist or linkedlist. The ziplist is the special representation that is used to save space for small lists.
    /// Sets can be encoded as intset or hashtable. The intset is a special encoding used for small sets composed solely of integers.
    /// Hashes can be encoded as zipmap or hashtable. The zipmap is a special encoding used for small hashes.
    /// Sorted Sets can be encoded as ziplist or skiplist format. As for the List type small sorted sets can be specially encoded using ziplist,
    /// while the skiplist encoding is the one that works with sorted sets of any size.
    ///
    /// - returns: Bulk string reply: The kind of internal representation used in order to store the value associated with a key.
    public func objectEncoding(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("OBJECT ENCODING \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// PERSIST key
    ///
    /// Remove the existing timeout on key, turning the key from volatile (a key with an expire set) to persistent (a key that will never expire as no timeout is associated).
    ///
    /// - returns: Integer reply, specifically: 1 if the timeout was removed. 0 if key does not exist or does not have an associated timeout.
    public func persist(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PERSIST \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// PEXPIRE key milliseconds
    ///
    /// This command works exactly like EXPIRE but the time to live of the key is specified in milliseconds instead of seconds.
    ///
    /// - returns: Integer reply, specifically: 1 if the timeout was set. 0 if key does not exist or the timeout could not be set.
    public func pExpire(key:String, timeoutInMilliseconds:UInt, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PEXPIRE \(RESPUtilities.respStringFromString(key)) \(timeoutInMilliseconds)", completionHandler: completionHandler)
    }
    
    /// PEXPIREAT key milliseconds-timestamp
    ///
    /// PEXPIREAT has the same effect and semantic as EXPIREAT, but the Unix time at which the key will expire is specified in milliseconds instead of seconds.
    ///
    /// - returns: Integer reply, specifically: 1 if the timeout was set. 0 if key does not exist or the timeout could not be set (see: EXPIRE).
    public func pExpire(key:String, at date:NSDate, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PEXPIREAT \(RESPUtilities.respStringFromString(key)) \(Int(date.timeIntervalSince1970*1000))", completionHandler: completionHandler)
    }
    
    /// PTTL key
    ///
    /// Like TTL this command returns the remaining time to live of a key that has an expire set,
    /// with the sole difference that TTL returns the amount of remaining time in seconds while PTTL returns it in milliseconds.
    ///
    /// In Redis 2.6 or older the command returns -1 if the key does not exist or if the key exist but has no associated expire.
    /// Starting with Redis 2.8 the return value in case of error changed:
    /// The command returns -2 if the key does not exist.
    /// The command returns -1 if the key exists but has no associated expire.
    ///
    /// - returns: Integer reply: TTL in milliseconds, or a negative value in order to signal an error (see the description above).
    public func pttl(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PTTL \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// RANDOMKEY
    ///
    /// Return a random key from the currently selected database.
    ///
    /// - returns: Bulk string reply: the random key, or nil when the database is empty.
    public func randomKey(completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("RANDOMKEY", completionHandler: completionHandler)
    }
    
    /// RENAME key newkey
    ///
    /// Renames key to newkey. It returns an error when the source and destination names are the same, or when key does not exist.
    /// If newkey already exists it is overwritten, when this happens RENAME executes an implicit DEL operation, so if the deleted
    /// key contains a very big value it may cause high latency even if RENAME itself is usually a constant-time operation.
    ///
    /// - returns: Simple string reply
    public func rename(key:String, newKey:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("RENAME \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(newKey))", completionHandler: completionHandler)
    }
    
    /// RENAMENX key newkey
    ///
    /// Renames key to newkey if newkey does not yet exist. It returns an error under the same conditions as RENAME.
    ///
    /// - returns: Integer reply, specifically: 1 if key was renamed to newkey. 0 if newkey already exists.
    public func renameNX(key:String, newKey:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("RENAMENX \(RESPUtilities.respStringFromString(key)) \(RESPUtilities.respStringFromString(newKey))", completionHandler: completionHandler)
    }
    
    /// RESTORE key ttl serialized-value
    ///
    /// Create a key associated with a value that is obtained by deserializing the provided serialized value (obtained via DUMP).
    /// If ttl is 0 the key is created without any expire, otherwise the specified expire time (in milliseconds) is set.
    /// RESTORE checks the RDB version and data checksum. If they don't match an error is returned.
    ///
    /// - returns: Simple string reply: The command returns OK on success.
    public func restore(key:String, ttl:UInt = 0, serializedValue:NSData, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("RESTORE \(RESPUtilities.respStringFromString(key)) \(ttl)", data:serializedValue, completionHandler: completionHandler)
    }
    
    // SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
    // TODO:
    
    /// TTL key
    ///
    /// Returns the remaining time to live of a key that has a timeout. This introspection capability allows a Redis client to check how many seconds a given key will continue to be part of the dataset.
    /// In Redis 2.6 or older the command returns -1 if the key does not exist or if the key exist but has no associated expire.
    /// Starting with Redis 2.8 the return value in case of error changed:
    /// The command returns -2 if the key does not exist.
    /// The command returns -1 if the key exists but has no associated expire.
    /// See also the PTTL command that returns the same information with milliseconds resolution (Only available in Redis 2.6 or greater).
    ///
    /// - returns: Integer reply: TTL in seconds, or a negative value in order to signal an error (see the description above).
    public func ttl(key:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("TTL \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// TYPE key
    ///
    /// Returns the string representation of the type of the value stored at key. The different types that can be returned are: string, list, set, zset and hash.
    ///
    /// - returns: Simple string reply: type of key, or none when key does not exist.
    public func type(key:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("TYPE \(RESPUtilities.respStringFromString(key))", completionHandler: completionHandler)
    }
    
    /// SCAN cursor [MATCH pattern] [COUNT count]
    ///
    /// SCAN basic usage
    ///
    /// SCAN is a cursor based iterator. This means that at every call of the command, the server returns an updated cursor that the user
    /// needs to use as the cursor argument in the next call.
    ///
    /// Scan guarantees
    ///
    /// The SCAN command, and the other commands in the SCAN family, are able to provide to the user a set of guarantees associated to full iterations.
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
    /// While SCAN does not provide guarantees about the number of elements returned at every iteration,
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
    /// - returns: SCAN return a two elements multi-bulk reply, where the first element is a string representing an unsigned 64 bit number (the cursor), and the second element is a multi-bulk with an array of elements. SCAN array of elements is a list of keys.
    public func scan(cursor:UInt, pattern:String? = nil, count:UInt? = nil, completionHandler:RedisCommandArrayBlock)
    {
        var command:String = "SCAN \(cursor)"
        if pattern != nil {
            command = command + " MATCH \(RESPUtilities.respStringFromString(pattern!))"
        }
        if count != nil {
            command = command + " COUNT \(count!)"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
}