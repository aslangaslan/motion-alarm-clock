//
//  ScreenSaver.swift
//  motionclock
//
//  Created by Giray Gençaslan on 6/26/16.
//  Copyright © 2016 gapp. All rights reserved.
//

import UIKit
import MapKit

class ScreenSaverVC: UIViewController {
    
    var swipe:UISwipeGestureRecognizer = UISwipeGestureRecognizer()
    
    var tap: UITapGestureRecognizer = UITapGestureRecognizer()
    
    var locationManager:CLLocationManager = CLLocationManager()
    
    var userLatitude:CLLocationDegrees = CLLocationDegrees()
    
    var userLongitude:CLLocationDegrees = CLLocationDegrees()
    
    @IBOutlet weak var lblGoodMorning: UILabel!
    
    @IBOutlet weak var clockLabel: UILabel!

    @IBOutlet weak var backgroundImage: UIImageView!

    @IBOutlet weak var lblCancelAlarm: UILabel!
    
    @IBOutlet weak var lblTapToStop: UILabel!
    
    @IBOutlet weak var imgDownArrow: UIImageView!

    override func viewDidLoad() {
        
        super.viewDidLoad()

        UIApplication.shared.isStatusBarHidden = true
        
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(ScreenSaverVC.swipeEvent))
        swipe.direction = UISwipeGestureRecognizer.Direction.down
        view.addGestureRecognizer(swipe)

        lblGoodMorning.isHidden = true
        lblGoodMorning.alpha = 0.0
        
        lblTapToStop.isHidden = true
        lblTapToStop.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(ScreenSaverVC.onAlarm), name: NSNotification.Name(rawValue: "ON_ALARM"), object: nil)
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ScreenSaverVC.showClock), userInfo: nil, repeats: true)

    }
    
    @objc func onAlarm() {
        
        tap = UITapGestureRecognizer(target: self, action: #selector(ScreenSaverVC.tapEvent))
        view.addGestureRecognizer(tap)
        
        lblTapToStop.isHidden = false
        lblGoodMorning.isHidden = false
        
        UIView.animate(withDuration: 1.0, animations: { self.lblTapToStop.alpha = 1.0 })
        UIView.animate(withDuration: 1.0, animations: { self.lblGoodMorning.alpha = 1.0 })
        
        lblCancelAlarm.isHidden = true
        imgDownArrow.isHidden = true
        
        view.removeGestureRecognizer(swipe)
        
        let giray = lblCancelAlarm.isHidden ? true : false
        print(giray)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0]
        userLatitude = userLocation.coordinate.latitude
        userLongitude = userLocation.coordinate.longitude
        
    }
    
    @objc func tapEvent() {
        
        view.removeGestureRecognizer(tap)
        
        lblTapToStop.isHidden = true
        lblGoodMorning.isHidden = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: "STOP_ACTION"), object: nil)
        
    }
    
    @objc func swipeEvent() {
        
        let topController:UIViewController = (UIApplication.shared.keyWindow?.rootViewController)!
        topController.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CANCEL_ALARM"), object: nil)
        
    }
    
    @objc func showClock(){
        
        monitorScreenSaverBckg()
        
        let currentDate = Date()
        let convertedDateFormatter:DateFormatter = DateFormatter()
        convertedDateFormatter.timeStyle = DateFormatter.Style.medium
        convertedDateFormatter.dateStyle = DateFormatter.Style.none
        convertedDateFormatter.timeZone = TimeZone.ReferenceType.local
        let localCurrentDate = convertedDateFormatter.string(from: currentDate)
        clockLabel.text = "\(localCurrentDate)"
        
    }
    
    func monitorScreenSaverBckg() {
        
        let solar = Solar(forDate: Date(), withTimeZone: TimeZone.autoupdatingCurrent, latitude: userLatitude, longitude: userLongitude)
        let isDayTime: Bool = (solar?.isDaytime)! as Bool
        let isNightTime: Bool = (solar?.isNighttime)! as Bool
        
        if isDayTime && self.backgroundImage.image != UIImage(named: "sunrise-background") {
            
            dayTimeAction()
            
        } else if isNightTime && self.backgroundImage.image != UIImage(named: "night-background") {
            
            nightTimeAction()
            
        }
        
    }
    
    func dayTimeAction() {

        self.backgroundImage.alpha = 0.2
        backgroundImage.image = UIImage(named: "sunrise-background")
        UIView.animate(withDuration: 2.0, animations: { self.backgroundImage.alpha = 1.0 })

    }
    
    func nightTimeAction() {
        
        self.backgroundImage.alpha = 0.2
        backgroundImage.image = UIImage(named: "night-background")
        UIView.animate(withDuration: 2.0, animations: { self.backgroundImage.alpha = 1.0 })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        showClock()
        monitorScreenSaverBckg()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
