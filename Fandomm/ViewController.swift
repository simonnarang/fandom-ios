//
//  ViewController.swift
//  Fandomm
//
//  Created by weel Narang on 8/25/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    let redisClient:RedisClient = RedisClient(host:"pub-redis-17342.us-east-1-4.3.ec2.garantiadata.com", port:17342, loggingBlock:{(redisClient:AnyObject, message:String, severity:RedisLogSeverity) in
        var debugString:String = message
        debugString = debugString.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
        debugString = debugString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        print("Log (\(severity.rawValue)): \(debugString)")
    })
    
    //vars to be used
    let defaults = NSUserDefaults.standardUserDefaults()
    var realUsername = String()
    var userFandoms = [AnyObject]()
    var signUpCounter = 0
    var number = Int()
    var thearray =  [AnyObject]()
    
    //IBOUTLETS
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.redisClient.lRem("thefandomfandom", count: 3, value: "I wonder if Will will ever see this? will will?") { (int, error) -> Void in
            
        }
        
        self.username.delegate = self
        self.password.delegate = self
       
        //dissmiss keyboard if needed on tap
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        //lrange throgh fandoms now so later users have them
        self.redisClient.lRange("thefandomfandom", start: 0, stop: 9999) { (array, error) -> Void in
            if error != nil {
                print("badbla")
                print(error)
            }else {
                for fandommpost in array {
                    self.thearray.append(fandommpost as! String)
                    print("\(fandommpost)huu")
                }
                self.number = self.thearray.count
                print("\(self.number)hiiiu")
            }
        }
    }
    
    //sign in/up alorithm
    func singInUp() -> Void {
            let passwordUsernameSwitchErrorAlertOne = UIAlertController (title: "😂Looks like you may have switched up your username and password😂", message: "if you are \(self.password.text!), want to login", preferredStyle: .Alert)
            let passwordUsernameSwitchErrorAlertOneOkButton = UIAlertAction(title: "sure!", style: .Default) { (action) in
                self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
            }
            passwordUsernameSwitchErrorAlertOne.addAction(passwordUsernameSwitchErrorAlertOneOkButton)
            let passwordUsernameSwitchErrorAlertOneNotMeButton = UIAlertAction(title: "thats not me let me try to sign in again", style: .Default) { (action) in}
            passwordUsernameSwitchErrorAlertOne.addAction(passwordUsernameSwitchErrorAlertOneNotMeButton)
            let networkErrorAlertTwo = UIAlertController(title: "😁Having some trouble recognizing usernames right now😁", message: "I can't reach the chest full of gold usernames... either your not connected to the internet or you need to update fandom over in the app store if not im already working on a fix so try again soon", preferredStyle: .Alert)
            let networkErrorAlertTwoOkButton = UIAlertAction(title: "☹️Okay☹️", style: .Default) { (action) in}
            networkErrorAlertTwo.addAction(networkErrorAlertTwoOkButton)
            
            let networkErrorAlertOne = UIAlertController(title: "😁Having some trouble recognizing usernames right now😁", message: "Sorry about that... perhaps check the app store to see if you need to update fandom... if not I'm already working on a fix so try again soon", preferredStyle: .Alert)
            let networkErrorAlertOneOkButton =  UIAlertAction(title: "☹️Okay☹️", style: .Default) { (action) in
            }
            networkErrorAlertOne.addAction(networkErrorAlertOneOkButton)
            let loginErrorAlertOne = UIAlertController(title: "😜Wrong password!😜", message: "try again \(self.username.text!)", preferredStyle: .Alert)
            let loginErrorAlertOneOkButton = UIAlertAction(title: "Got it!", style: .Default) { (action) in
            }
            loginErrorAlertOne.addAction(loginErrorAlertOneOkButton)
            
            let signInOrUpAlertOne =  UIAlertController(title: "🤔Don't recongnize that username!🤔", message: "Do you want to sign up or use a different username? ", preferredStyle: .Alert)
            let signInOrUpAlertOneSignUpButton = UIAlertAction(title: "sign up", style: .Default) { (action) in
                self.redisClient.lPush(self.username.text!, values: [self.password.text!], completionHandler: { (int, error) -> Void in
                    if error != nil {
                        print("an error occured while attempting to sign up a user via lPush(PW/POSTS list)...")
                        print(error)
                        self.presentViewController(networkErrorAlertOne, animated: true) {}
                        
                    }else{
                        print("there was no error appending a user acount to the redis db via lpush")
                        self.signUpCounter += 1
                        print("no error... signUpCounter is now at \(self.signUpCounter)")
                    }
                })
                self.redisClient.lPush("\(self.username.text!)followers", values: ["claire"], completionHandler: { (int, error) -> Void in
                    if error != nil {
                        print("an error occured while attempting to sign up a user via lPush(FOLLOWERS list)...")
                        print(error)
                    }else{
                        self.signUpCounter += 1
                        
                    }
                })
                self.redisClient.lPush("\(self.username.text!)following", values: ["claire"], completionHandler: { (int, error) -> Void in
                    if error != nil {
                        print("an error occured while attempting to sign up a user via lPush(FOLLOWING list)...")
                        print(error)
                    }else{
                        self.signUpCounter += 1
                    }
                })
                self.redisClient.lPush("\(self.username.text!)fandoms", values: ["thefandomfandom"], completionHandler: { (int, error) -> Void in
                    if error != nil {
                        print("an error occured while attempting to sign up a user via lPush(FANDOMS list)...")
                        print(error)
                    }else{
                        self.signUpCounter += 1
                    }
                })
                if self.signUpCounter == 4 {
                    
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }else{
                    if self.signUpCounter == 0{
                        print("all 4 of the tasks acossiated with user signup failed")
                        //self.presentViewController(networkErrorAlertOne, animated: true) {}
                        self.realUsername = self.username.text!
                        self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                    }else if self.signUpCounter == 1 {
                        print("3 of the tasks acossiated with user signup failed")
                        //self.presentViewController(networkErrorAlertOne, animated: true) {}
                        self.realUsername = self.username.text!
                        self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                    }else if self.signUpCounter == 2 {
                        print("2 of the tasks acossiated with user signup failed")
                        //self.presentViewController(networkErrorAlertOne, animated: true) {}
                        self.realUsername = self.username.text!
                        self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                    }else if self.signUpCounter == 3{
                        print("1 of the tasks acossiated with user signup failed")
                        //self.presentViewController(networkErrorAlertOne, animated: true) {}
                        self.realUsername = self.username.text!
                        self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                    }else{
                        print("FATAL ERR// something wrong with signup counter")
                        //self.presentViewController(networkErrorAlertOne, animated: true) {}
                        self.realUsername = self.username.text!
                        self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                    }
                }
            }
            signInOrUpAlertOne.addAction(signInOrUpAlertOneSignUpButton)
            let signInOrUpAlertOneSignInButton = UIAlertAction(title: "use different username", style: .Default) { (action) in
            }
            signInOrUpAlertOne.addAction(signInOrUpAlertOneSignInButton)
            
            
            
            
            /*redisClient.auth("", completionHandler: { (string, error) -> Void in
            if error == nil {
            authenticated = (string == "OK")
            print("authenticated")
            }
            print("error is \(error)")
            if authenticated{
            }else{
            redisClient.quit { (string, error) -> Void in }
            }
            })*/
            //check to see if username already exists
            redisClient.exists(username.text!) { (int, error) -> Void in
                //if it does exist, and there is no error continue to check is password is correct
                if error == nil && int == 1 {
                    print("omggg!!! the redis db didnt give an error for no reason!!! it worked!!!")
                    self.realUsername = self.username.text!
                    self.redisClient.lRange(self.username.text!, start: 0, stop: 0, completionHandler: { (array, error) -> Void in
                        if array[0] as? String == self.password.text {
                            print("testOne")
                            self.realUsername = self.username.text!
                            self.redisClient.lRange("\(self.username.text!)fandoms", start: 0, stop: 99999999, completionHandler: { (array, error) -> Void in
                                print("getting fandoms to send to other view controllers")
                                for fandom in array {
                                    self.userFandoms.append(fandom)
                                    print("appended \(fandom) to userfandoms")
                                }
                                print("\(self.username.text!)fandoms")
                                print(array)
                                print("there is an error if \(self.userFandoms) != \(array) blub")
                                if self.userFandoms.count < 1 {
                                    print("redis connection array not working")
                                    print(self.userFandoms)
                                } else {
                                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                                }
                            })
                            
                        }else{
                            self.presentViewController(loginErrorAlertOne, animated: true) {}
                        }
                    })
                }else if error == nil && int == 0 {
                    print("zerow")
                    self.redisClient.exists(self.password.text!, completionHandler: { (int, error) -> Void in
                        if error == nil && int == 1 {
                            self.redisClient.lRange(self.password.text!, start: 0, stop: 0, completionHandler: { (array, error) -> Void in
                                if array[0] as? String == self.username.text! {
                                    self.presentViewController(passwordUsernameSwitchErrorAlertOne, animated: true) {}
                                    self.realUsername = self.password.text!
                                }else{
                                    self.presentViewController(signInOrUpAlertOne, animated: true) {}
                                }
                            })
                        }else{
                            self.presentViewController(signInOrUpAlertOne, animated: true) {}
                        }
                    })
                    
                }else{
                    if int != nil {
                        self.presentViewController(networkErrorAlertOne, animated: true) {}
                        print("same old redis error :p")
                        print(error)
                    }else{
                        self.presentViewController(networkErrorAlertTwo, animated: true) {}
                    }
                }
            }
    }
    
    //when next button @bottom hit calls signInUp function
    @IBAction func nextButton(sender: AnyObject) {
            singInUp()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let DestViewCont: TabBarViewController = segue.destinationViewController as! TabBarViewController
        DestViewCont.usernameTwo = self.realUsername
        DestViewCont.userFandoms = self.userFandoms
        DestViewCont.number = self.number
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //dissmiss keyboard calles on tap
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //textField editing problems algorithm
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        let passwordUsernameSwitchErrorAlertOne = UIAlertController (title: "😂Looks like you may have switched up your username and password😂", message: "if you are \(self.password.text!), want to login", preferredStyle: .Alert)
        let passwordUsernameSwitchErrorAlertOneOkButton = UIAlertAction(title: "sure!", style: .Default) { (action) in
            self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
        }
        passwordUsernameSwitchErrorAlertOne.addAction(passwordUsernameSwitchErrorAlertOneOkButton)
        let passwordUsernameSwitchErrorAlertOneNotMeButton = UIAlertAction(title: "thats not me let me try to sign in again", style: .Default) { (action) in}
        passwordUsernameSwitchErrorAlertOne.addAction(passwordUsernameSwitchErrorAlertOneNotMeButton)
        let networkErrorAlertTwo = UIAlertController(title: "😁Having some trouble recognizing usernames right now😁", message: "I can't reach the chest full of gold usernames... either your not connected to the internet or you need to update fandom over in the app store if not im already working on a fix so try again soon", preferredStyle: .Alert)
        let networkErrorAlertTwoOkButton = UIAlertAction(title: "☹️Okay☹️", style: .Default) { (action) in}
        networkErrorAlertTwo.addAction(networkErrorAlertTwoOkButton)
        
        let networkErrorAlertOne = UIAlertController(title: "😁Having some trouble recognizing usernames right now😁", message: "Sorry about that... perhaps check the app store to see if you need to update fandom... if not I'm already working on a fix so try again soon", preferredStyle: .Alert)
        let networkErrorAlertOneOkButton =  UIAlertAction(title: "☹️Okay☹️", style: .Default) { (action) in
        }
        networkErrorAlertOne.addAction(networkErrorAlertOneOkButton)
        let loginErrorAlertOne = UIAlertController(title: "😜Wrong password!😜", message: "try again \(self.username.text!)", preferredStyle: .Alert)
        let loginErrorAlertOneOkButton = UIAlertAction(title: "Got it!", style: .Default) { (action) in
        }
        loginErrorAlertOne.addAction(loginErrorAlertOneOkButton)
        
        let signInOrUpAlertOne =  UIAlertController(title: "🤔Don't recongnize that username!🤔", message: "Do you want to sign up or use a different username? ", preferredStyle: .Alert)
        let signInOrUpAlertOneSignUpButton = UIAlertAction(title: "sign up", style: .Default) { (action) in
            self.redisClient.lPush(self.username.text!, values: [self.password.text!], completionHandler: { (int, error) -> Void in
                if error != nil {
                    print("an error occured while attempting to sign up a user via lPush(PW/POSTS list)...")
                    print(error)
                    self.presentViewController(networkErrorAlertOne, animated: true) {}
                    
                }else{
                    print("there was no error appending a user acount to the redis db via lpush")
                    self.signUpCounter += 1
                    print("no error... signUpCounter is now at \(self.signUpCounter)")
                }
            })
            self.redisClient.lPush("\(self.username.text!)followers", values: ["claire"], completionHandler: { (int, error) -> Void in
                if error != nil {
                    print("an error occured while attempting to sign up a user via lPush(FOLLOWERS list)...")
                    print(error)
                }else{
                    self.signUpCounter += 1
                    
                }
            })
            self.redisClient.lPush("\(self.username.text!)following", values: ["claire"], completionHandler: { (int, error) -> Void in
                if error != nil {
                    print("an error occured while attempting to sign up a user via lPush(FOLLOWING list)...")
                    print(error)
                }else{
                    self.signUpCounter += 1
                }
            })
            self.redisClient.lPush("\(self.username.text!)fandoms", values: ["thefandomfandom"], completionHandler: { (int, error) -> Void in
                if error != nil {
                    print("an error occured while attempting to sign up a user via lPush(FANDOMS list)...")
                    print(error)
                }else{
                    self.signUpCounter += 1
                }
            })
            if self.signUpCounter == 4 {
                                
                self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
            }else{
                if self.signUpCounter == 0{
                    print("all 4 of the tasks acossiated with user signup failed")
                    //self.presentViewController(networkErrorAlertOne, animated: true) {}
                    self.realUsername = self.username.text!
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }else if self.signUpCounter == 1 {
                    print("3 of the tasks acossiated with user signup failed")
                    //self.presentViewController(networkErrorAlertOne, animated: true) {}
                    self.realUsername = self.username.text!
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }else if self.signUpCounter == 2 {
                    print("2 of the tasks acossiated with user signup failed")
                    //self.presentViewController(networkErrorAlertOne, animated: true) {}
                    self.realUsername = self.username.text!
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }else if self.signUpCounter == 3{
                    print("1 of the tasks acossiated with user signup failed")
                    //self.presentViewController(networkErrorAlertOne, animated: true) {}
                    self.realUsername = self.username.text!
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }else{
                    print("FATAL ERR// something wrong with signup counter")
                    //self.presentViewController(networkErrorAlertOne, animated: true) {}
                    self.realUsername = self.username.text!
                    self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                }
            }
        }
        signInOrUpAlertOne.addAction(signInOrUpAlertOneSignUpButton)
        let signInOrUpAlertOneSignInButton = UIAlertAction(title: "use different username", style: .Default) { (action) in
        }
        signInOrUpAlertOne.addAction(signInOrUpAlertOneSignInButton)
        
        
        
        
        /*redisClient.auth("", completionHandler: { (string, error) -> Void in
        if error == nil {
        authenticated = (string == "OK")
        print("authenticated")
        }
        print("error is \(error)")
        if authenticated{
        }else{
        redisClient.quit { (string, error) -> Void in }
        }
        })*/
        //check to see if username already exists
        redisClient.exists(username.text!) { (int, error) -> Void in
            //if it does exist, and there is no error continue to check is password is correct
            if error == nil && int == 1 {
                print("omggg!!! the redis db didnt give an error for no reason!!! it worked!!!")
                self.realUsername = self.username.text!
                self.redisClient.lRange(self.username.text!, start: 0, stop: 0, completionHandler: { (array, error) -> Void in
                    if array[0] as? String == self.password.text {
                        print("testOne")
                        self.realUsername = self.username.text!
                        self.redisClient.lRange("\(self.username.text!)fandoms", start: 0, stop: 99999999, completionHandler: { (array, error) -> Void in
                            print("getting fandoms to send to other view controllers")
                            for fandom in array {
                                self.userFandoms.append(fandom)
                                print("appended \(fandom) to userfandoms")
                            }
                            print("\(self.username.text!)fandoms")
                            print(array)
                            print("there is an error if \(self.userFandoms) != \(array) blub")
                            if self.userFandoms.count < 1 {
                                print("redis connection array not working")
                                print(self.userFandoms)
                            } else {
                                self.performSegueWithIdentifier("viewControllerToTBVC", sender: nil)
                            }
                        })
                        
                    }else{
                        self.presentViewController(loginErrorAlertOne, animated: true) {}
                    }
                })
            }else if error == nil && int == 0 {
                print("zerow")
                self.redisClient.exists(self.password.text!, completionHandler: { (int, error) -> Void in
                    if error == nil && int == 1 {
                        self.redisClient.lRange(self.password.text!, start: 0, stop: 0, completionHandler: { (array, error) -> Void in
                            if array[0] as? String == self.username.text! {
                                self.presentViewController(passwordUsernameSwitchErrorAlertOne, animated: true) {}
                                self.realUsername = self.password.text!
                            }else{
                                self.presentViewController(signInOrUpAlertOne, animated: true) {}
                            }
                        })
                    }else{
                        self.presentViewController(signInOrUpAlertOne, animated: true) {}
                    }
                })
                
            }else{
                if int != nil {
                    self.presentViewController(networkErrorAlertOne, animated: true) {}
                    print("same old redis error :p")
                    print(error)
                }else{
                    self.presentViewController(networkErrorAlertTwo, animated: true) {}
                }
            }
        }

        return false
        
    }

}

