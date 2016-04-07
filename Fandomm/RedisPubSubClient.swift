//
//  RedisPubSubClient.swift
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

/// RedisPubSubClient
///
/// A Redis client used specifically for Subscribe, Unsubscribe and Quit.
/// After subscribing to a channel it will pass all the messages to the messange handler.
public class RedisPubSubClient
{
    private var _quitHandler:((success:Bool)->Void)!
    lazy private var _pubSubCommander:RedisPubSubCommander = RedisPubSubCommander(host: self._serverHost, port: self._serverPort, loggingBlock: self._loggingBlock, responseHandler:{[unowned self] (message,error) in
            self.performBlockOnDelegateQueue({ () -> Void in
                if error != nil
                {
                    if error.code == 1
                    {
                        if self._quitHandler != nil {
                            self._quitHandler(success: true)
                        }
                        self._quitHandler = nil
                        self._pubSubCommander._closeExpected = false
                    }
                    else {
                        self._errorHandler(error: error)
                    }
                }
                else {
                    self._messageHandler(message: message)
                }
            })
        })
    private let _loggingBlock:RedisLoggingBlock
    private let _messageHandler:((message: [AnyObject]) -> Void)
    private let _delegateQueue:NSOperationQueue!
    private let _serverHost:String!
    private let _serverPort:Int!
    private let _authPassword:String!
    let _errorHandler:((error:NSError) -> Void)
    
    public init(host: String, port: Int, authPassword:String? = nil, loggingBlock: RedisLoggingBlock?, delegateQueue: NSOperationQueue?, messageHandler:(message: [AnyObject]) -> Void, errorHandler:(error:NSError) -> Void)
    {
        self._serverHost = host
        self._serverPort = port
        self._authPassword = authPassword
        self._messageHandler = messageHandler
        self._errorHandler = errorHandler
        
        if loggingBlock == nil
        {
            self._loggingBlock = {(redisClient:AnyObject, message:String, severity:RedisLogSeverity) in
                switch(severity)
                {
                    case .Critical, .Error:
                        print(message)
                    default: break
                }
            }
        }
        else {
            self._loggingBlock = loggingBlock!
        }
        
        if delegateQueue == nil {
            self._delegateQueue = NSOperationQueue.mainQueue()
        }
        else {
            self._delegateQueue = delegateQueue
        }
    }
    
    private func log(message:String, severity:RedisLogSeverity)
    {
        if NSThread.isMainThread() {
            self._loggingBlock!(redisClient: self, message: message, severity: severity)
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                self._loggingBlock!(redisClient: self, message: message, severity: severity)
            })
        }
    }
    
    private func performBlockOnDelegateQueue(block:dispatch_block_t) -> Void {
        self._delegateQueue.addOperationWithBlock(block)
    }
    
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
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString("AUTH \(RESPUtilities.respStringFromString(password))"), stringResponseHandler: { (string, error) -> Void in
            self.performBlockOnDelegateQueue({ () -> Void in
               completionHandler(string: string, error: error)
            })
        })
    }
    
    /// SUBSCRIBE channel [channel ...]
    ///
    /// Subscribes the client to the specified channels.
    /// Once the client enters the subscribed state it is not supposed to issue any other commands, 
    /// except for additional SUBSCRIBE, PSUBSCRIBE, UNSUBSCRIBE and PUNSUBSCRIBE commands.
    public func subscribe(channels:[String])
    {
        var command:String = "SUBSCRIBE"
        for channel in channels {
            command = command + " \(RESPUtilities.respStringFromString(channel))"
        }
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString(command))
    }
    
    /// UNSUBSCRIBE [channel [channel ...]]
    ///
    /// Unsubscribes the client from the given channels, or from all of them if none is given.
    /// When no channels are specified, the client is unsubscribed from all the previously subscribed channels. 
    /// In this case, a message for every unsubscribed channel will be sent to the client.
    public func unsubscribe(channels:[String])
    {
        var command:String = "UNSUBSCRIBE"
        for channel in channels {
            command = command + " \(RESPUtilities.respStringFromString(channel))"
        }
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString(command))
    }
    
    /// PSUBSCRIBE pattern [pattern ...]
    ///
    /// Subscribes the client to the given patterns.
    /// Supported glob-style patterns:
    /// h?llo subscribes to hello, hallo and hxllo
    /// h*llo subscribes to hllo and heeeello
    /// h[ae]llo subscribes to hello and hallo, but not hillo
    /// Use \ to escape special characters if you want to match them verbatim.
    public func pSubscribe(patterns:[String])
    {
        var command:String = "PSUBSCRIBE"
        for pattern in patterns {
            command = command + " \(RESPUtilities.respStringFromString(pattern))"
        }
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString(command))
    }
    
    /// PUNSUBSCRIBE [pattern [pattern ...]]
    ///
    /// Unsubscribes the client from the given patterns, or from all of them if none is given.
    /// When no patterns are specified, the client is unsubscribed from all the previously subscribed patterns. 
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    public func pUnsubscribe(patterns:[String])
    {
        var command:String = "PUNSUBSCRIBE"
        for pattern in patterns {
            command = command + " \(RESPUtilities.respStringFromString(pattern))"
        }
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString(command))
    }
    
    /// QUIT
    ///
    /// Ask the server to close the connection. The connection is closed as soon as all pending replies have been written to the client.
    /// 
    /// - returns: Simple string reply: always OK.
    public func quit(completionHandler:(success:Bool)->Void)
    {
        self._quitHandler = completionHandler
        self._pubSubCommander._closeExpected = true
        self._pubSubCommander.sendCommand(RESPUtilities.commandToRequestString("QUIT"))
    }
}

private class RedisPubSubCommander:NSObject, NSStreamDelegate
{
    private let _serverHost:String!
    private let _serverPort:Int!
    private let _loggingBlock:RedisLoggingBlock
    private let _responseHandler:(message:[AnyObject]!, error:NSError!) -> Void
    
    private var _inputStream:NSInputStream!
    private var _outputStream:NSOutputStream!
    private var _incomingData:NSMutableData!
    
    private var _queuedCommands:[String] = [String]()
    private var _closeExpected:Bool = false
    private var _stringResponseHandler:RedisCommandStringBlock!
    
    private func _closeStreams()
    {
        if self._inputStream != nil
        {
            self._inputStream.close()
            self._inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
        
        if self._outputStream != nil
        {
            self._outputStream.close()
            self._outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
    }
    
    private func _openStreams()
    {
        self._closeStreams()
        
        var readStream:NSInputStream? = nil
        var writeStream:NSOutputStream? = nil
        NSStream.getStreamsToHostWithName(self._serverHost, port: self._serverPort, inputStream: &readStream, outputStream: &writeStream)
        self._inputStream = readStream
        self._outputStream = writeStream
        self._inputStream.delegate = self
        self._outputStream.delegate = self
        self._inputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self._outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self._inputStream.open()
        self._outputStream.open()
    }
    
    private func log(message:String, severity:RedisLogSeverity)
    {
        if NSThread.isMainThread() {
            self._loggingBlock!(redisClient: self, message: message, severity: severity)
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                self._loggingBlock!(redisClient: self, message: message, severity: severity)
            })
        }
    }
    
    private init(host:String, port:Int, loggingBlock:RedisLoggingBlock, responseHandler:(message:[AnyObject]!, error:NSError!) -> Void)
    {
        self._serverHost = host
        self._serverPort = port
        self._loggingBlock = loggingBlock
        self._responseHandler = responseHandler
        
        super.init()
        
        self._openStreams()
    }
    
    private func _sendQueuedCommand()
    {
        if !self._queuedCommands.isEmpty
        {
            let queuedCommand = self._queuedCommands.removeAtIndex(0)
            self.log("\t--SENDING COMMAND (\(queuedCommand))---", severity: .Debug)
            let commandStringData:NSMutableData = NSMutableData(data: queuedCommand.dataUsingEncoding(NSUTF8StringEncoding)!)
            let bytesWritten = self._outputStream.write(UnsafePointer<UInt8>(commandStringData.bytes), maxLength: commandStringData.length)
            self.log("\tbytes sent: \(bytesWritten)", severity: .Debug)
        }
    }
    
    private func parseResponse() //TODO: this is ugly...
    {
        let dataString:String = NSString(data: self._incomingData, encoding: NSUTF8StringEncoding) as! String
        self.log("parsing response: \(dataString)", severity: .Debug)
        
        if dataString.hasPrefix("-") //error
        {
            let error = NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor()))])
            if self._stringResponseHandler != nil
            {
                self._stringResponseHandler(string: nil, error: error)
                self._stringResponseHandler = nil
            }
            else {
                self._responseHandler(message: nil, error: error)
            }
            return
        }
        else if dataString.hasPrefix("+")
        {
            if self._stringResponseHandler != nil
            {
                self._stringResponseHandler(string: dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor())), error: nil)
                self._stringResponseHandler = nil
            }
            return
        }
        else if !dataString.hasPrefix("*") {
            return
        }
        
        var currentIndex:Int = 0
        var stringComponents = dataString.componentsSeparatedByString("\r\n")
        let firstItem:String = stringComponents[0]
        let arraySize:Int = Int(firstItem.substringFromIndex(firstItem.startIndex.successor()))!
        stringComponents.removeAtIndex(0)
        var lastComponent:String! = nil
        if stringComponents.count > 0 {
            lastComponent = stringComponents.removeLast()
        }
        
        var lastValidIndex = 0
        var foundMessages = 0
        while(currentIndex < stringComponents.count) //problem here, assuming every message is an array
        {
            let message = RESPUtilities.arrayFromComponents(&stringComponents, currentIndex: &currentIndex, arraySize: arraySize)
            if message.count == arraySize //got a full message
            {
                self._responseHandler(message: message, error: nil)
                currentIndex += 1
                lastValidIndex = currentIndex
                foundMessages += 1
                
                if currentIndex >= stringComponents.count && lastComponent != "" //fully parsed with extra component
                {
                    self._incomingData = NSMutableData(data: lastComponent.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                    break
                }
                
                currentIndex += 1
            }
            else if foundMessages == 0 //first array incomplete, just break with existing data
            {
                break
            }
            else //non first array incomplete, need to trim full messages
            {
                var incompleteString:String = String()
                currentIndex = lastValidIndex
                
                if currentIndex < stringComponents.count - 1
                {
                    for component in stringComponents[currentIndex ... stringComponents.count - 1]
                    {
                        incompleteString = incompleteString + component + "\r\n"
                    }
                    incompleteString = incompleteString + lastComponent
                }
                else
                {
                    incompleteString = stringComponents[stringComponents.count-1] + "\r\n" + lastComponent
                }
                self._incomingData = NSMutableData(data: incompleteString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                break
            }
        }
    }
    
    @objc private func stream(theStream: NSStream, handleEvent streamEvent: NSStreamEvent)
    {
        switch(streamEvent)
        {
            case NSStreamEvent.HasBytesAvailable:
                if self._inputStream === theStream //reading
                {
                    self.log("\tHasBytesAvailable", severity: .Debug)
                    self.log("\t--READING COMMAND RESPONSE---", severity: .Debug)
                    let bufferSize:Int = 1024
                    var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
                    let bytesRead:Int = self._inputStream.read(&buffer, maxLength: bufferSize)
                    self.log("\tbytes read:\(bytesRead)", severity: .Debug)
                    let data = NSData(bytes: buffer, length: bytesRead)
                    if bytesRead == bufferSize && self._inputStream.hasBytesAvailable //reached the end of the buffer, more to come
                    {
                        if self._incomingData != nil {  //there was existing data
                            self._incomingData.appendData(data)
                        }
                        else {
                            self._incomingData = NSMutableData(data: data)
                        }
                        self.parseResponse()
                    }
                    else if bytesRead > 0 //finished
                    {
                        if self._incomingData != nil {  //there was existing data
                            self._incomingData.appendData(data)
                        }
                        else {  //got it all in one shot
                            self._incomingData = NSMutableData(data: data)
                        }
                        self.log("\tfinished reading", severity: .Debug)
                        self.parseResponse()
                        self._incomingData = nil
                    }
                    else //reading error
                    {
                        if !self._closeExpected {
                            self._responseHandler(message: nil, error: NSError(domain: "com.rareairconsulting.resp", code: 0, userInfo: [NSLocalizedDescriptionKey:"Error occured while reading with code \(bytesRead)"]))
                        }
                        self._incomingData = nil
                    }
                }
            case NSStreamEvent.HasSpaceAvailable: //can send data
                self.log("\tHasSpaceAvailable", severity: .Debug)
                if theStream === self._outputStream && !self._queuedCommands.isEmpty { //writing
                    self._sendQueuedCommand()
                }
            case NSStreamEvent.OpenCompleted:
                self.log("\tOpenCompleted", severity: .Debug)
            case NSStreamEvent.ErrorOccurred:
                self.log("\tErrorOccurred", severity: .Debug)
                self._responseHandler(message: nil, error: theStream.streamError)
                self._incomingData = nil
            case NSStreamEvent.EndEncountered:
                self.log("\tEndEncountered", severity: .Debug)
                self._closeStreams()
                if theStream == self._inputStream && self._closeExpected {
                    self._responseHandler(message: nil, error: NSError(domain: "com.rareairconsulting.resp", code: 1, userInfo: [NSLocalizedDescriptionKey:"Error occured while reading."]))
                }
            default: break
        }
    }
    
    private func sendCommand(command:NSString, stringResponseHandler:RedisCommandStringBlock! = nil)
    {
        self._queuedCommands.append(command as String)
        if stringResponseHandler != nil {
            self._stringResponseHandler = stringResponseHandler
        }
        
        switch(self._inputStream.streamStatus)
        {
            case NSStreamStatus.Closed, NSStreamStatus.Error, NSStreamStatus.AtEnd: //try opening it if closed
                self._openStreams()
            default: break
        }
        switch(self._outputStream.streamStatus)
        {
            case NSStreamStatus.Closed, NSStreamStatus.Error, NSStreamStatus.AtEnd: //try opening it if closed
                self._openStreams()
            case NSStreamStatus.Open:
                self._sendQueuedCommand()
            default: break
        }
    }
}