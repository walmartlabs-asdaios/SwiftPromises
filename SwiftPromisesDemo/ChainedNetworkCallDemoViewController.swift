//
//  ChainedNetworkCallDemoViewController.swift
//  SwiftPromises
//
//  Created by Douglas Sjoquist on 3/1/15.
//  Copyright (c) 2015 Ivy Gulch LLC. All rights reserved.
//

import UIKit
import SwiftPromises

class ChainedNetworkCallDemoViewController: BaseDemoViewController {

    @IBOutlet var url1TextField:UITextField?
    @IBOutlet var url2TextField:UITextField?
    @IBOutlet var url3TextField:UITextField?
    @IBOutlet var url1StatusImageView:UIImageView?
    @IBOutlet var url2StatusImageView:UIImageView?
    @IBOutlet var url3StatusImageView:UIImageView?
    @IBOutlet var finalStatusImageView:UIImageView?
    @IBOutlet var stopOnErrorSwitch:UISwitch?

    override func viewWillAppear(animated: Bool) {
        url1TextField!.text = "http://cnn.com"
        url2TextField!.text = "http://apple.com"
        url3TextField!.text = "http://nytimes.com"

        super.viewWillAppear(animated)
    }

    override func clearStatus() {
        url1StatusImageView!.setStatus(nil)
        url2StatusImageView!.setStatus(nil)
        url3StatusImageView!.setStatus(nil)
        finalStatusImageView!.setStatus(nil)
    }

    override func readyToStart() -> Bool {
        return true
    }

    override func start() {
        clearStatus()
        clearLog()

        startActivityIndicator()

        loadURL1StepPromise().then(
            { [weak self] value in
                return .Pending(self!.loadURL2StepPromise())
        } ).then(
            { [weak self] value in
                return .Pending(self!.loadURL3StepPromise())
        }).then(
            { [weak self] value in
                self?.log("final success")
                self?.finalStatusImageView!.setStatus(true)
                self?.stopActivityIndicator()
                return .Value(value)
            }, reject: { [weak self] error in
                self?.log("final error: \(error)")
                self?.finalStatusImageView!.setStatus(false)
                self?.stopActivityIndicator()
                return .Error(error)
        })

    }

    func loadURL1StepPromise() -> Promise<NSData> {
        return loadURLStepPromise(url1TextField!.text, statusImageView:url1StatusImageView!)
    }

    func loadURL2StepPromise() -> Promise<NSData> {
        return loadURLStepPromise(url2TextField!.text, statusImageView:url2StatusImageView!)
    }

    func loadURL3StepPromise() -> Promise<NSData> {
        return loadURLStepPromise(url3TextField!.text, statusImageView:url3StatusImageView!)
    }

    func loadURLStepPromise(urlString:String?, statusImageView:UIImageView?) -> Promise<NSData> {
        let url:NSURL? = (urlString == nil) ? nil : NSURL(string:urlString!)
        return loadURLPromise(url).then(
            { [weak self] value in
                statusImageView?.setStatus(true)
                self?.log("loaded \(value?.length) bytes from URL \(url)")
                return .Value(value)
            }, reject: { [weak self] error in
                statusImageView?.setStatus(false)
                var stopOnError = true
                if let stopOnErrorSwitch = self?.stopOnErrorSwitch {
                    stopOnError = stopOnErrorSwitch.on
                }
                if stopOnError {
                    self?.log("Stopping on error while loading URL \(url): \(error)")
                    return .Error(error)
                } else {
                    self?.log("Ignore error while loading URL \(url): \(error)")
                    return .Value(nil) // don't stop the chain
                }
            }
        )
    }

}
