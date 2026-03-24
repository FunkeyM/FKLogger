//
//  ViewController.swift
//  FKLogger
//
//  Created by Bobby on 2026/3/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogVerbose(message: "你好")
        LogDebug(message: "debug")
        LogWarn(message: "warn")
        LogInfo(message: "info")
        LogError(message: "error")
        print("nooooooo")
        
//        var arr = [String]()
//        arr[1] = "1"
        
        FKLoggerManager.shared.debug("debbbb")
    }


}

