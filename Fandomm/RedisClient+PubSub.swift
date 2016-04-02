//
//  RedisClient+PubSub.swift
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
    /// PUBLISH channel message
    ///
    /// Posts a message to the given channel.
    ///
    /// - returns: Integer reply: the number of clients that received the message.
    public func publish(channel:String, message:String, completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PUBLISH \(RESPUtilities.respStringFromString(channel)) \(RESPUtilities.respStringFromString(message))", completionHandler: completionHandler)
    }
    
    /// PUBSUB CHANNELS [pattern]
    ///
    /// Lists the currently active channels. An active channel is a Pub/Sub channel with one or more subscribers (not including clients subscribed to patterns).
    /// If no pattern is specified, all the channels are listed, otherwise if pattern is specified only channels matching the specified glob-style pattern are listed.
    ///
    /// - returns: Array reply: a list of active channels, optionally matching the specified pattern.
    public func pubSubChannels(patterns:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "PUBSUB CHANNELS"
        for pattern in patterns {
            command = command + " \(RESPUtilities.respStringFromString(pattern))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// PUBSUB NUMSUB [channel-1 ... channel-N]
    ///
    /// Returns the number of subscribers (not counting clients subscribed to patterns) for the specified channels.
    ///
    /// - returns: Array reply: a list of channels and number of subscribers for every channel. The format is channel, count, channel, count, ..., so the list is flat. The order in which the channels are listed is the same as the order of the channels specified in the command call. Note that it is valid to call this command without channels. In this case it will just return an empty list.
    public func pubSubNumSub(channels:[String], completionHandler:RedisCommandArrayBlock)
    {
        var command = "PUBSUB NUMSUB"
        for channel in channels {
            command = command + " \(RESPUtilities.respStringFromString(channel))"
        }
        self.sendCommandWithArrayResponse(command, completionHandler: completionHandler)
    }
    
    /// PUBSUB NUMPAT
    ///
    /// Returns the number of subscriptions to patterns (that are performed using the PSUBSCRIBE command). Note that this is not just the count of clients subscribed to patterns but the total number of patterns all the clients are subscribed to.
    ///
    /// - returns: Integer reply: the number of patterns all the clients are subscribed to.
    public func pubSubNumPat(completionHandler:RedisCommandIntegerBlock) {
        self.sendCommandWithIntegerResponse("PUBSUB NUMPAT", completionHandler: completionHandler)
    }
}