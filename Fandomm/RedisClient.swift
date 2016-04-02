//
//  RedisClient.swift
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

public let RedisErrorDomain = "com.rareairconsulting.redis"

public enum RedisLogSeverity:String
{
    case Info = "Info"
    case Debug = "Debug"
    case Error = "Error"
    case Critical = "Critical"
}

public typealias RedisLoggingBlock = ((redisClient:AnyObject, message:String, severity:RedisLogSeverity) -> Void)?
public typealias RedisCommandStringBlock = ((string:String!, error:NSError!)->Void)
public typealias RedisCommandIntegerBlock = ((int:Int!, error:NSError!)->Void)
public typealias RedisCommandArrayBlock = ((array:[AnyObject]!, error:NSError!)->Void)
public typealias RedisCommandDataBlock = ((data:NSData!, error:NSError!)->Void)

/// RedisClient
///
/// A simple redis client that can be extended for supported Redis commands.  
/// This client expects a response for each request and acts as a serial queue.
/// See: RedisPubSubClient for publish/subscribe functionality.
public class RedisClient
{
    private let _loggingBlock:RedisLoggingBlock
    private let _delegateQueue:NSOperationQueue!
    private let _serverHost:String!
    private let _serverPort:Int!
    lazy private var _commander:RESPCommander = RESPCommander(redisClient: self)
    internal var closeExpected:Bool = false {
        didSet {
            self._commander._closeExpected = self.closeExpected
        }
    }
    
    public var host:String {
        return self._serverHost
    }
    
    public var port:Int {
        return self._serverPort
    }
    
    internal func performBlockOnDelegateQueue(block:dispatch_block_t) -> Void {
        self._delegateQueue.addOperationWithBlock(block)
    }
    
    public init(host:String, port:Int, loggingBlock:RedisLoggingBlock? = nil, delegateQueue:NSOperationQueue? = nil)
    {
        self._serverHost = host
        self._serverPort = port
        
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
    
    public func sendCommandWithArrayResponse(command: String, data:NSData? = nil, completionHandler: RedisCommandArrayBlock)
    {
        self._commander.sendCommand(RESPUtilities.commandToRequestString(command, data:(data != nil)), completionHandler: { (data, error) -> Void in
            self.performBlockOnDelegateQueue({ () -> Void in
                if error != nil {
                    completionHandler(array: nil, error: error)
                }
                else {
                    let parsingResults:(array:[AnyObject]!, error:NSError!) = RESPUtilities.respArrayFromData(data)
                    completionHandler(array: parsingResults.array, error: parsingResults.error)
                }
            })
        })
    }
    
    public func sendCommandWithIntegerResponse(command: String, data:NSData? = nil, completionHandler: RedisCommandIntegerBlock)
    {
        self._commander.sendCommand(RESPUtilities.commandToRequestString(command, data:(data != nil)), completionHandler: { (data, error) -> Void in
            self.performBlockOnDelegateQueue({ () -> Void in
                if error != nil {
                    completionHandler(int: nil, error: error)
                }
                else {
                    let parsingResults:(int:Int!, error:NSError!) = RESPUtilities.respIntegerFromData(data)
                    completionHandler(int: parsingResults.int, error: parsingResults.error)
                }
            })
        })
    }
    
    public func sendCommandWithStringResponse(command: String, data:NSData? = nil, completionHandler: RedisCommandStringBlock)
    {
        self._commander.sendCommand(RESPUtilities.commandToRequestString(command, data:(data != nil)), data:data, completionHandler: { (data, error) -> Void in
            self.performBlockOnDelegateQueue({ () -> Void in
                if error != nil {
                    completionHandler(string: nil, error: error)
                }
                else {
                    let parsingResults = RESPUtilities.respStringFromData(data)
                    completionHandler(string: parsingResults.string, error: parsingResults.error)
                }
            })
        })
    }
    
    public func sendCommandWithDataResponse(command: String, data:NSData? = nil, completionHandler: RedisCommandDataBlock)
    {
        self._commander.sendCommand(RESPUtilities.commandToRequestString(command, data:(data != nil)), completionHandler: { (data, error) -> Void in
            self.performBlockOnDelegateQueue({ () -> Void in
                completionHandler(data: data, error: error)
            })
        })
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
}

private class RESPCommander:NSObject, NSStreamDelegate
{
    private let _redisClient:RedisClient!
    private var _inputStream:NSInputStream!
    private var _outputStream:NSOutputStream!
    private let _operationQueue:NSOperationQueue!
    private let _commandLock:dispatch_semaphore_t!
    private let _queueLock:dispatch_semaphore_t!
    private var _incomingData:NSMutableData!
    
    private let operationLock:String = "RedisOperationLock"
    private var _queuedCommand:String! = nil
    private var _queuedData:NSData! = nil
    private var _error:NSError?
    
    private var _closeExpected:Bool = false
    
    private func _closeStreams()
    {
        if self._inputStream != nil
        {
            self._inputStream.close()
            self._inputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self._inputStream = nil
        }
        
        if self._outputStream != nil
        {
            self._outputStream.close()
            self._outputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self._outputStream = nil
        }
    }
    
    private func _openStreams()
    {
        self._closeStreams()
        
        var readStream:NSInputStream? = nil
        var writeStream:NSOutputStream? = nil
        NSStream.getStreamsToHostWithName(self._redisClient._serverHost, port: self._redisClient._serverPort, inputStream: &readStream, outputStream: &writeStream)
        self._inputStream = readStream
        self._outputStream = writeStream
        self._inputStream.delegate = self
        self._outputStream.delegate = self
        self._inputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self._outputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self._inputStream.open()
        self._outputStream.open()
    }
    
    init(redisClient: RedisClient)
    {
        self._commandLock = dispatch_semaphore_create(0);
        self._queueLock = dispatch_semaphore_create(1)
        self._operationQueue = NSOperationQueue()
        self._redisClient = redisClient
        super.init()
        
        self._openStreams()
    }
    
    @objc func stream(theStream: NSStream, handleEvent streamEvent: NSStreamEvent)
    {
        switch(streamEvent)
        {
            case NSStreamEvent.HasBytesAvailable:
                if self._inputStream === theStream //reading
                {
                    self._redisClient.log("\tHasBytesAvailable", severity: .Debug)
                    self._redisClient.log("\t--READING COMMAND RESPONSE---", severity: .Debug)
                    let bufferSize:Int = 1024
                    var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
                    let bytesRead:Int = self._inputStream.read(&buffer, maxLength: bufferSize)
                    self._redisClient.log("\tbytes read:\(bytesRead)", severity: .Debug)
                    let data = NSData(bytes: buffer, length: bytesRead)
                    if bytesRead == bufferSize && self._inputStream.hasBytesAvailable //reached the end of the buffer, more to come
                    {
                        if self._incomingData != nil { //there was existing data
                            self._incomingData.appendData(data)
                        }
                        else {
                            self._incomingData = NSMutableData(data: data)
                        }
                    }
                    else if bytesRead > 0 //finished
                    {
                        if self._incomingData != nil //there was existing data
                        {
                            self._incomingData.appendData(data)
                        }
                        else { //got it all in one shot
                            self._incomingData = NSMutableData(data: data)
                        }
                        self._redisClient.log("\tfinished reading", severity: .Debug)
                        dispatch_semaphore_signal(self._commandLock) //signal we are done
                    }
                    else
                    {
                        if !self._closeExpected
                        {
                            self._error = NSError(domain: "com.rareairconsulting.resp", code: 0, userInfo: [NSLocalizedDescriptionKey:"Error occured while reading."])
                            dispatch_semaphore_signal(self._commandLock) //signal we are done                        
                        }
                    }
                }
            case NSStreamEvent.HasSpaceAvailable:
                self._redisClient.log("\tHasSpaceAvailable", severity: .Debug)
                if theStream === self._outputStream && self._queuedCommand != nil { //writing
                    self._sendQueuedCommand()
                }
            case NSStreamEvent.OpenCompleted:
                self._redisClient.log("\tOpenCompleted", severity: .Debug)
            case NSStreamEvent.ErrorOccurred:
                self._redisClient.log("\tErrorOccurred", severity: .Debug)
                self._error = theStream.streamError
                dispatch_semaphore_signal(self._commandLock) //signal we are done
            case NSStreamEvent.EndEncountered: //cleanup
                self._redisClient.log("\tEndEncountered", severity: .Debug)
                self._closeStreams()
            default:
                break
        }
    }
    
    private func _sendQueuedCommand()
    {
        let queuedCommand = self._queuedCommand
        self._queuedCommand = nil
        if queuedCommand != nil && !queuedCommand.isEmpty
        {
            self._redisClient.log("\t--SENDING COMMAND (\(queuedCommand))---", severity: .Debug)
            let commandStringData:NSMutableData = NSMutableData(data: queuedCommand.dataUsingEncoding(NSUTF8StringEncoding)!)
            if self._queuedData != nil
            {
                commandStringData.appendData("$\(self._queuedData.length)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                commandStringData.appendData(self._queuedData)
                commandStringData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                self._queuedData = nil
            }
            self._incomingData = nil
            let bytesWritten = self._outputStream.write(UnsafePointer<UInt8>(commandStringData.bytes), maxLength: commandStringData.length)
            self._redisClient.log("\tbytes sent: \(bytesWritten)", severity: .Debug)
        }
    }
    
    private func sendCommand(command:NSString, data:NSData? = nil, completionHandler:RedisCommandDataBlock)
    {
        //could probably use gcd barriers for this but this seems good for now
        self._operationQueue.addOperationWithBlock { [unowned self] () -> Void in
                self._redisClient.log("***Adding to the command queue***", severity: .Debug)
                dispatch_semaphore_wait(self._queueLock, DISPATCH_TIME_FOREVER)
                self._redisClient.log("***New command starting off queue***", severity: .Debug)
                self._queuedCommand = command as String
                self._queuedData = data
                if self._inputStream != nil
                {
                    switch(self._inputStream.streamStatus)
                    {
                        case NSStreamStatus.Closed, NSStreamStatus.Error: //try opening it if closed
                            self._openStreams()
                        default: break
                    }
                }
                else {
                    self._openStreams()
                }
            
                switch(self._outputStream.streamStatus)
                {
                    case NSStreamStatus.Closed, NSStreamStatus.Error: //try opening it if closed
                        self._openStreams()
                    case NSStreamStatus.Open:
                        self._sendQueuedCommand()
                    default: break
                }
                dispatch_semaphore_wait(self._commandLock, DISPATCH_TIME_FOREVER)
                self._redisClient.log("***Releasing command queue lock***", severity: .Debug)
                completionHandler(data: self._incomingData, error: self._error)
                dispatch_semaphore_signal(self._queueLock)
        }
    }
}
