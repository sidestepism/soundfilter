//
//  ViewController.swift
//  voicefilterplayground
//
//  Created by Ryohei Fushimi on 2016/2/27.
//  Copyright © 2016 fushimir. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var PlayModeRealtime: NSButton!
    @IBOutlet weak var PlayModeRecAndPlay: NSButton!
    @IBOutlet weak var LoopCheckbox: NSButton!
    
    @IBOutlet weak var sliderDelay: NSSlider!
    @IBOutlet weak var sliderChorus: NSSlider!
    @IBOutlet weak var sliderFormant: NSSlider!
    
    @IBOutlet weak var buttonRec: NSButton!
    @IBOutlet weak var buttonPlay: NSButton!
    
    @IBOutlet weak var waveformVisualizerSubview: WaveformVisualizerView!
    @IBOutlet weak var checkboxLooped: NSButton!
    
    var recording = false
    var playing = false
    
    let filePath = NSURL(fileURLWithPath: NSTemporaryDirectory() + "/hamigaki.m4a")
//    let filePath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForSoundResource("atr.wav")
//        ?? NSTemporaryDirectory() + "/recording.wav")
    // temporary file for recording
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // 波形をアップデート
        var _ = NSTimer.scheduledTimerWithTimeInterval(0.02,
            target: self, selector: "updateWaveformVisualizer", userInfo: nil, repeats: true)
        

        waveformVisualizerSubview.volume = pow(AudioEngineManager.shared.inputLevel, 0.2)
        waveformVisualizerSubview.size = pow(AudioEngineManager.shared.inputLevel, 0.05)
        waveformVisualizerSubview.active = AudioEngineManager.shared.speechDetecting
    }

    func updateWaveformVisualizer() {
        waveformVisualizerSubview.volume = pow(AudioEngineManager.shared.inputLevel, 0.2)
        waveformVisualizerSubview.size = pow(AudioEngineManager.shared.inputLevel, 0.05)
        waveformVisualizerSubview.active = AudioEngineManager.shared.speechDetecting
        //waveformVisualizerSubview.setNeedsDisplay()
        waveformVisualizerSubview.display()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func sliderDelayChanged(sender: AnyObject) {
        AudioEngineManager.shared.AUDelayTime = (sender as! NSSlider).doubleValue
    }
    @IBAction func sliderDistortionChanged(sender: AnyObject) {
//        (sender as NSSlider!).
        AudioEngineManager.shared.AUDistortion = (sender as! NSSlider).floatValue
    }
    @IBAction func SliderSpeedChanged(sender: AnyObject) {
        AudioEngineManager.shared.AUSpeed = sliderDelay.floatValue
    }
    @IBAction func sliderPitchChanged(sender: AnyObject) {
        AudioEngineManager.shared.AUPitch = (sender as! NSSlider).floatValue
    }
    @IBAction func RecButtonPushed(sender: AnyObject) {
        NSLog("RecButtonPushed, buttonPlay.enabled = %@", buttonPlay.enabled)
        if playing {
            AudioEngineManager.shared.stopPlaying()
        }
        
        if recording {
            AudioEngineManager.shared.stopRecording()
            buttonPlay.enabled = true
            recording = false
        }else{
            AudioEngineManager.shared.startRecording(filePath)
            buttonPlay.enabled = false
            recording = true
        }
    }

    @IBAction func checkboxLoopedValueChanged(sender: AnyObject) {
        NSLog("checkboxLoopedValueChanged: %@", checkboxLooped.state)
        AudioEngineManager.shared.loop = Bool(checkboxLooped.state)
    }
    
    @IBAction func PlayButtonPushed(sender: AnyObject) {
        if playing {
            AudioEngineManager.shared.stopPlaying()
        } else {
            if recording {
                AudioEngineManager.shared.stopRecording()
            }
            AudioEngineManager.shared.startPlaying(filePath)
        }
        
    }
}

