//
//  LEDControllerSingletonHelper.swift
//  SmartConfigDemoIos
//
//  Created by YeYe on 15/7/23.
//  Copyright © 2015年 YeYe. All rights reserved.
//

import UIKit
import Foundation

@objc class LEDControllerSingletonHelper: NSObject {
    
    func sendTCPMsgToSingleton( message:String ){
        let ledController : LEDController = LEDController.getInstance()
        ledController.msgReceived(message)
    }

}
