//
//  ViewController.swift
//  motionclock
//
//  Created by Giray Gençaslan on 07/06/16.
//  Copyright © 2016 gapp. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

protocol ObservableProtocol {
    associatedtype T
    var value: T { get set }
    func subscribe(observer: AnyObject,
                   block: (_ newValue: T, _ oldValue: T) -> ())
    func unsubscribe(observer: AnyObject)
}

class MainVC: UIViewController {

    let device:UIDevice = UIDevice.current
    
    var alert:UIAlertController = UIAlertController()
    
    var stepLogArray:NSMutableArray = NSMutableArray()  
    
    var isSetted:Bool = false
    
    var isSnooze = false
    
    var timer:Timer = Timer()
    
    var player = AVAudioPlayer()
    
    var playerError: Int = 0
    
    let pedometer:CMPedometer = CMPedometer()
    
    var hitCount:Int = 0
    
    @IBOutlet var datePicker: UIDatePicker!
    
    @IBOutlet weak var intervalLabel: UILabel!

    @IBOutlet var stepperOutlet: UIStepper!
    
    @IBAction func stepperAction(_ sender: UIStepper) {
        
        intervalLabel.text = Int(sender.value).description
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(ScreenSaverVC.swipeEvent))
        swipe.direction = UISwipeGestureRecognizer.Direction.up
        view.addGestureRecognizer(swipe)

        
        self.datePicker.setValue(UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0), forKey: "textColor")
        self.stepLogArray.removeAllObjects()
    }
    
    func swipeEvent() {
        
        if isSetted {
            self.cancelAlarm()
        } else {
            print("Local Alarm Setup Date: \(convertToLocalDateString(date: Date()))")
            self.setAlarm(wakeUpDate: resetSecondOnDate(standartDate: datePicker.date))
        }
        
    }

    func convertToLocalDateString(date: Date) -> String {
        
        let convertedDateFormatter:DateFormatter = DateFormatter()
        convertedDateFormatter.timeStyle = DateFormatter.Style.medium
        convertedDateFormatter.dateStyle = DateFormatter.Style.medium
        convertedDateFormatter.timeZone = TimeZone.autoupdatingCurrent
        
        let convertedDateString = convertedDateFormatter.string(from: date)
        return convertedDateString
    }

    func setAlarm(wakeUpDate: Date) {
        
        print("Local Alarm Date: \(convertToLocalDateString(date: wakeUpDate))") // ==> Burası silinecek
        
        isSetted = true
        device.isProximityMonitoringEnabled = true

        let screenSaverVC = self.storyboard?.instantiateViewController(withIdentifier: "screenSaverVC") as! ScreenSaverVC
        present(screenSaverVC, animated: true, completion: nil)
        
        //Screen Saver: Stop Alarm Tuşuna Basında Çalışır
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MainVC.stopAlarm),
                                               name: NSNotification.Name(rawValue: "STOP_ACTION"),
                                               object: nil)
        
        //Screen Saver: Cancel Alarm Tuşuna Basınca Çalışır
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MainVC.cancelAlarm),
                                               name: NSNotification.Name(rawValue: "CANCEL_ALARM"),
                                               object: nil)

        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(MainVC.alarmSelector),
                                          userInfo: wakeUpDate,
                                          repeats: true)

    }
    
    @objc func alarmSelector() {
        
        
        let currentSeconds = self.calculateSeconds(alarmDate: timer.userInfo as! Date)
        print("Remaining Time: \(currentSeconds) || Current Date: \(convertToLocalDateString(date: NSDate() as Date)) || Alarm On: \(convertToLocalDateString(date: resetSecondOnDate(standartDate: datePicker.date)))")
        
        let dateComparisonResult = Calendar.current.compare(NSDate() as Date,
                                                            to: resetSecondOnDate(standartDate: datePicker.date),
                                                            toGranularity: Calendar.Component.second)
        
        if dateComparisonResult == ComparisonResult.orderedSame {
            
            self.playAlarmTone()
            timer.invalidate()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ON_ALARM"), object: nil)
            
        }
        
    }
    
    func calculateSeconds(alarmDate: Date) -> Int {
        
        var alarmDate:Date = alarmDate
        
        var currentDate = Date()
        var currentDateComponents: DateComponents = (Calendar.current as NSCalendar).components(NSCalendar.Unit(rawValue: UInt.max), from: currentDate)
        currentDateComponents.nanosecond = 00   //==> Burası önemli hatırlamasan da sakın silme!
        currentDate = Calendar.current.date(from: currentDateComponents)!
        
        
        let calendar: Calendar = Calendar.current
        if alarmDate.compare(currentDate) == ComparisonResult.orderedAscending {
            
            alarmDate = (Calendar.current as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: alarmDate, options: [])!
            
        }
        
        let components = (calendar as NSCalendar).components(NSCalendar.Unit.second, from: currentDate, to: alarmDate, options: [])
        return components.second!
        
    }
    
    func playAlarmTone() {
        
        do {
            
            if let soundPath = Bundle.main.path(forResource: "alarm", ofType: "mp3") {
                
//                try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: [])
                
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .defaultToSpeaker)
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundPath))
                player.volume = 1.0
                player.numberOfLoops = -1
                player.prepareToPlay()
                player.play()
                
            } else {
                
                print("Failed to Generate Sound Path")
                self.playerError = 1
                
            }
            
        }
        catch {
            
            print("Failed Playing Alarm")
            
        }
        
    }

    @objc func cancelAlarm () {
        
        isSetted = false
        timer.invalidate()
        device.isProximityMonitoringEnabled = false
        
    }
    
    @objc func stopAlarm() {
        
        self.timer.invalidate()
        device.isProximityMonitoringEnabled = false
        if playerError == 0 { player.stop() } else { print("Alarm passed.") }
        
        let currentDate	 = Date()
        var nextAlarmDate:Date = (Calendar.current as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: Int(self.stepperOutlet.value), to: currentDate, options: [])!
        
        nextAlarmDate = self.resetSecondOnDate(standartDate: nextAlarmDate)
        
        snoozeMonitoring(snoozeDate: nextAlarmDate)
        print("Next Alarm On: \(self.convertToLocalDateString(date: nextAlarmDate))")
        
    }
    
    func snoozeMonitoring(snoozeDate: Date) {
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainVC.snoozeSelector), userInfo: snoozeDate, repeats: true) //==> Snooze timer burada çalıştırılıyor
        
        device.isProximityMonitoringEnabled = true
        self.startPedometerUpdates()
        
    }
    
    @objc func snoozeSelector() {
        
        let nextAlarmDate = self.timer.userInfo as! Date
        let currentSeconds = self.calculateSeconds(alarmDate: nextAlarmDate)
        print("Remaining Time: \(currentSeconds) || Current Date: \(convertToLocalDateString(date: NSDate() as Date)) || Alarm On: \(convertToLocalDateString(date: resetSecondOnDate(standartDate: nextAlarmDate)))")
        
        let dateComparisonResult = Calendar.current.compare(NSDate() as Date,
                                                            to: resetSecondOnDate(standartDate: nextAlarmDate),
                                                            toGranularity: Calendar.Component.second)
        
        if dateComparisonResult == ComparisonResult.orderedSame {
            
            if self.stepLogArray.count > 0 {

                timer.invalidate()
                device.isProximityMonitoringEnabled = false
                
                let topController:UIViewController = (UIApplication.shared.keyWindow?.rootViewController)!
                topController.dismiss(animated: true, completion: nil)
                
                pedometer.stopUpdates()
                print("============== Step Log Array ==============")
                print(self.stepLogArray)
                
                print("Pedometer Result: \(calculatePedometerResult(nextAlarmDate: nextAlarmDate))")
                
            } else {
                
                self.playAlarmTone()
                timer.invalidate()
                device.isProximityMonitoringEnabled = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ON_ALARM"), object: nil)
                
            }

        }

    }
    
    func startPedometerUpdates() {
        
        print("Pedometer Start Date: \(convertToLocalDateString(date: Date()))")
        
        if CMPedometer.isStepCountingAvailable() {
            
            pedometer.startUpdates(from: Date(), withHandler: { (pedometerData: CMPedometerData?, pedometerError: Error?) in
                
                if (pedometerError == nil) {
                    
                    print("Steps Taken At: \(self.convertToLocalDateString(date: Date())) \(pedometerData!.numberOfSteps)")
                    self.stepLogArray.add((pedometerData?.numberOfSteps)! as NSNumber)

                }
                
            })
            
        } else {
            
            print("Pedometer Not Supported")
            
        }
        
    }
    
    func resetSecondOnDate(standartDate: Date) -> Date {
        
        var returnDateComponents: DateComponents = (Calendar.current as NSCalendar).components(NSCalendar.Unit(rawValue: UInt.max), from: standartDate)
        returnDateComponents.second = 00
        returnDateComponents.nanosecond = 00
        return Calendar.current.date(from: returnDateComponents)!
        
    }
    
    func checkNumberOfStepsByDate(fromDate:Date) {
        
        let toDate:Date = (Calendar.current as NSCalendar).date(byAdding: NSCalendar.Unit.second, value: 5, to: fromDate, options: [])!
        
        if CMPedometer.isStepCountingAvailable() {
            
            self.pedometer.queryPedometerData(from: fromDate, to: toDate, withHandler: { (pedometerData, pedometerError) in
                
                DispatchQueue.main.async {
                
                    if pedometerError == nil {

                        print("Steps Taken At: \(fromDate) - \(toDate) : \(pedometerData!.numberOfSteps)")
                        if self.hitCount >= 2 { print("Hit Point: true") } else { print("Hit Point: false") }
                        
                    }
                    
                }
            
            })
            
        }
        else {
            
            print("Step Counter Not Available")
            
        }
        
    }
    
    func calculatePedometerResult(nextAlarmDate: Date) {
        
        for _ in 1...4 {
            
            var reversedSecond:Int = 0
            while (reversedSecond < 10) || (reversedSecond > 50) {
                
                reversedSecond = Int(arc4random_uniform(51) + 10)
                
            }

            let checkDate:Date = (Calendar.current as NSCalendar).date(byAdding: NSCalendar.Unit.second, value: -reversedSecond, to: nextAlarmDate, options: [])!
            self.checkNumberOfStepsByDate(fromDate: checkDate)
            
        }

    }

}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
