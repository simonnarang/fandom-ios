//
//  RedisClient+Connection.swift
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
    
    /// AUTH password
    ///
    /// Request for authentication in a password-protected Redis server.
    /// Redis can be instructed to require a password before allowing clients to execute commands.
    /// This is done using the requirepass directive in the configuration file.
    /// If password matches the password in the configuration file, the server replies with the OK status code and starts accepting commands. Otherwise, an error is returned and the clients needs to try a new password.
    /// Note: because of the high performance nature of Redis, it is possible to try a lot of passwords in parallel in very short time,
    /// so make sure to generate a strong and very long password so that this attack is infeasible.
    ///
    /// - returns: Simple string reply
    public func auth(password:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("AUTH \(RESPUtilities.respStringFromString(password))",completionHandler: completionHandler)
    }
    //
    
    /// ECHO message
    ///
    /// Returns message.
    ///
    /// - returns: Bulk string reply
    public func echo(message:String, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("ECHO \(RESPUtilities.respStringFromString(message))", completionHandler: completionHandler)
    }
    
    /// PING
    ///
    /// Returns PONG. This command is often used to test if a connection is still alive, or to measure latency.
    ///
    /// - returns: Simple string reply
    public func ping(completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("PING", completionHandler: completionHandler)
    }
    
    /// QUIT
    ///
    /// Ask the server to close the connection. The connection is closed as soon as all pending replies have been written to the client.
    ///
    /// - returns: Simple string reply: always OK.
    public func quit(completionHandler:RedisCommandStringBlock)
    {
        self.closeExpected = true
        self.sendCommandWithStringResponse("QUIT", completionHandler: {[unowned self] (string, error) -> Void in
                self.closeExpected = false
                completionHandler(string: string, error: error)
            })
    }
    
    /// SELECT index
    ///
    /// Select the DB with having the specified zero-based numeric index. New connections always use DB 0.
    ///
    /// - returns: Simple string reply
    public func select(index:UInt, completionHandler:RedisCommandStringBlock) {
        self.sendCommandWithStringResponse("SELECT \(index)", completionHandler: completionHandler)
    }
}