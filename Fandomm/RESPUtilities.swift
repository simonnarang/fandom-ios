//
//  RESPUtilities.swift
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

private let RESP_SPACE_REPLACEMENT = "\u{FFFC}" //used so we can pass around spaced strings while encoding commands
public class RESPUtilities
{
    internal class func stringFromRESPString(string:String) -> String {
        return string.stringByReplacingOccurrencesOfString(RESP_SPACE_REPLACEMENT, withString: " ")
    }
    
    internal class func respStringFromString(string:String) -> String {
        return string.stringByReplacingOccurrencesOfString(" ", withString: RESP_SPACE_REPLACEMENT)
    }
    
    internal class func commandToRequestString(command:String, data:Bool = false) -> String
    {
        if command.isEmpty {
            return command
        }
        
        var requestString:String! = nil
        let componentStrings:[String] = command.componentsSeparatedByString(" ")
        var count:Int = componentStrings.count
        if data {
            count += 1
        }
        requestString = "*\(count)\r\n"
        for componentString in componentStrings
        {
            let componentStringCleaned = RESPUtilities.stringFromRESPString(componentString)
            requestString = requestString + "$\(componentStringCleaned.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\r\n\(componentStringCleaned)\r\n"
        }
        return requestString
    }
    
    internal class func respIntegerFromData(data:NSData!) -> (int:Int!, error:NSError!)
    {
        var int:Int! = nil
        var error:NSError! = nil
        
        if data != nil
        {
            let dataString:String! = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
            if dataString.hasPrefix(":") { //int
                int = Int(dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor())))
            }
            else if dataString.hasPrefix("-") //error
            {
                error = NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor()))])
            }
        }
        return (int, error)
    }
    
    internal class func respStringFromData(data:NSData!) -> (string:String!, error:NSError!)
    {
        var string:NSString! = nil
        var error:NSError! = nil
        if data != nil
        {
            var dataString:String! = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
            if dataString == nil {
                dataString = NSString(data: data, encoding: NSUnicodeStringEncoding) as! String
            }
            if dataString != nil
            {
                if dataString.hasPrefix("+") { //simple string
                    string = dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor()))
                }
                else if dataString.hasPrefix("$-1") { //bulk string - non-existence of a value
                    string = ""
                }
                else if dataString.hasPrefix("$") { //bulk string
                    let firstCRLFRange:Range<String.Index> = dataString.rangeOfString("\r\n")!
                    string = dataString.substringWithRange(Range<String.Index>(start: firstCRLFRange.endIndex, end: dataString.endIndex.predecessor()))
                }
                else if dataString.hasPrefix("-") //error
                {
                    error = NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor()))])
                }
            }
            else {
                error = NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown string format"])
            }
        }
        if error != nil {
            return (nil, error)
        }
        else if string != nil {
            return (string as String, error)
        }
        return (nil, nil)
    }
    
    internal class func arrayFromComponents(inout stringComponents:[String], inout currentIndex:Int, arraySize:Int) -> [AnyObject]
    {
        var array:[AnyObject] = [AnyObject]()
        var newString:String! = nil

        for var index = currentIndex; index < stringComponents.count; index += 1
        {
            if index < currentIndex {
                continue
            }
            
            let component:String = stringComponents[index]
            if component.hasPrefix("$-1") //bulk string - non-existence of a value
            {
                if newString != nil && !newString.isEmpty {
                    array.append(newString)
                }
                newString = nil
                array.append("")
            }
            else if component.hasPrefix("*") //start of a new array
            {
                if newString != nil && !newString.isEmpty {
                    array.append(newString)
                }
                newString = nil
                
                currentIndex = index + 1
                let arraySize:Int = Int(component.substringFromIndex(component.startIndex.successor()))!
                let innerArray = self.arrayFromComponents(&stringComponents, currentIndex: &currentIndex, arraySize:arraySize)
                array.append(innerArray)
                continue
            }
            else if component.hasPrefix("$") //start of a new string
            {
                if newString != nil && !newString.isEmpty {
                    array.append(newString)
                }
                newString = nil
            }
            else if component.hasPrefix(":") //start of a new Int
            {
                if newString != nil && !newString.isEmpty {
                    array.append(newString)
                }
                newString = nil
                
                if let newInt = Int(component.substringFromIndex(component.startIndex.successor()))
                {
                    array.append(newInt)
                }
            }
            else //possibly in the middle of a string
            {
                if newString == nil {
                    newString = component
                }
                else {
                    newString = newString + " \(component)"
                }
            }
            currentIndex = index
            if array.count == arraySize {
                return array
            }
        }
        if newString != nil && !newString.isEmpty {
            array.append(newString)
        }
        currentIndex++
        return array
    }
    
    internal class func respArrayFromData(data:NSData!) -> (array:[AnyObject]!, error:NSError!)
    {
        if data != nil
        {
            let dataString:String! = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
            if dataString.hasPrefix("-") //error
            {
                let error:NSError = NSError(domain: RedisErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:dataString.substringWithRange(Range<String.Index>(start: dataString.startIndex.successor(), end: dataString.endIndex.predecessor()))])
                return (nil, error)
            }
            else if dataString.hasPrefix("*") //array
            {
                let crlf:String = "\r\n"
                var stringComponents:[String] = dataString.componentsSeparatedByString(crlf)
                stringComponents.removeLast()
                
                let firstItem:String = stringComponents[0]
                let arraySize:Int = Int(firstItem.substringFromIndex(firstItem.startIndex.successor()))!
                stringComponents.removeAtIndex(0)
                
                var currentIndex:Int = 0
                let array:[AnyObject] = self.arrayFromComponents(&stringComponents, currentIndex: &currentIndex, arraySize:arraySize)
                return (array, nil)
            }
        }
        return (nil, nil)
    }
}
