//
//  AudioEngineManager.swift
//  Chattie
//
//  Created by 村上晋太郎 on 2016/02/11.
//  Copyright © 2016年 R. Fushimi and S. Murakami. All rights reserved.
//

import AVFoundation

class AudioEngineManager: NSObject {
    
    private let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    
    private let pitch = AVAudioUnitTimePitch()
    private let speed = AVAudioUnitVarispeed()
    private let distortion = AVAudioUnitDistortion()
    private let delay = AVAudioUnitDelay()
    private let mixer = AVAudioMixerNode() // ファイルフォーマットの不整合を吸収

    private let generator = SinWaveGenerator()
    
    var recording = false
    var playing = false
    var loop = false
    var playerVolume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }
    
    var AUPitch: Float {
        get { return pitch.pitch }
        set { pitch.pitch = newValue }
    } // 100 = 1semitones
    var AUSpeed: Float {
        get { return speed.rate }
        set { speed.rate = newValue }
    }
    var AUDelayTime: Double {
        get { return delay.delayTime }
        set { delay.delayTime = newValue }
    }
    var AUDistortion: Float {
        get { return distortion.wetDryMix }
        set { distortion.wetDryMix = newValue }
    }
    
    var inputLevel:Double = 0.0
    var averageInputLevel:Double = 0.0
    
    var speechDetecting = false
    var concurrentSilentFrames = 0
    
    var speechDetectionOnInputLevelThreshold = 0.0002
    var speechDetectionOffInputLevelThreshold: Double {
        get {
            return speechDetectionOnInputLevelThreshold * 0.5
        }
    }
    let speechDetectionOffConcurrentFramesThreshold = 3
    
    // 若干迷ったけど、繰り返し呼ばれるようなコールバックはデリゲートパタンの方が良さそう (循環参照を防ぐため)
    weak var speechDetectionDelegate: AudioEngineManagerSpeechDetectionDelegate? = nil
    
    var fileForRecording: AVAudioFile?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupEngine()
    }
    
    func setupEngine() {
        guard let input = engine.inputNode else {
            AppUtil.alert("ERROR", message: "input node not found")
            return
        }

        AUDelayTime = 0.0
        AUSpeed = 1.0
        AUPitch = 0.0
        AUDistortion = 50.0
        distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.SpeechRadioTower)
        
        var sinGeneratorNode: AUNode;

        let format = input.outputFormatForBus(0)
        engine.attachNode(player)
        engine.attachNode(generator.audioUnit)
        engine.attachNode(mixer)
        engine.attachNode(pitch)
        engine.attachNode(speed)
        engine.attachNode(distortion)
        engine.attachNode(delay)
        
        playerVolume = 1.0
        engine.connect(player, to: mixer, format: format)
        engine.connect(mixer, to: pitch, format: nil)

        engine.connect(pitch, to: speed, format: nil)
        engine.connect(speed, to: distortion, format: nil)
        engine.connect(distortion, to: delay, format: nil)
    
        engine.connect(delay, to: engine.mainMixerNode, format: nil)
        engine.connect(input, to: engine.mainMixerNode, format: format)
        input.volume = 0
        startEngine()
        
        // attach tap to update input volume
        // for waveform visualization and speech detection
        let bus = 0
        let size: AVAudioFrameCount = 4096 // 0.1sec?
        input.installTapOnBus(bus, bufferSize: size, format: nil) {
            (AVAudioPCMBuffer buffer, AVAudioTime when) in
            self.updateInputLevel(buffer, when: when)
            if self.recording {
                self.updateRecording(buffer, when: when)
            }
        }
    }
    
    func updateInputLevel(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        let frameLength = 2048 // bufferのlengthを書き換えたら副作用がありそうだから念のため...
        self.inputLevel = 0.0
        for i in 0 ..< Int(frameLength) {
            self.inputLevel += pow(Double(buffer.floatChannelData.memory[i]), 2)
        }
        self.inputLevel /= Double(frameLength)
        self.inputLevelUpdated()
    }
    
    func inputLevelUpdated() {
        if inputLevel > 1.0 {
            inputLevel = 1.0
        }
        
        if !speechDetecting{
            if inputLevel > speechDetectionOnInputLevelThreshold {
                speechDetecting = true
                if let delegate = speechDetectionDelegate {
                    delegate.audioEngineManagerDidStartSpeechDetection(self)
                }
            }
        }else{
            if inputLevel < speechDetectionOffInputLevelThreshold {
                concurrentSilentFrames += 1
            } else {
                concurrentSilentFrames = 0
            }
            if concurrentSilentFrames > speechDetectionOffConcurrentFramesThreshold {
                speechDetecting = false
                concurrentSilentFrames = 0
                if let delegate = speechDetectionDelegate {
                    delegate.audioEngineManagerDidFinishSpeechDetection(self)
                }
            }
        }
    }
    
    func updateRecording(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        guard let file = fileForRecording else {
            NSLog("ERROR: file for recording is nil")
            return
        }
        do {
            try file.writeFromBuffer(buffer)
        } catch {
            NSLog("ERROR: recording to audio file failed")
            print(error)
        }
    }
    
    func startEngine() {
        if !engine.running {
            do {
                try engine.start()
            } catch {
                AppUtil.alert("ERROR", message: "could not start audio engine")
            }
        }
    }
    
    // MARK: - Play and Record
    
    func startRecording(fileURL: NSURL) {
        startEngine()
        
        guard let input = engine.inputNode else {
            AppUtil.alert("ERROR", message: "input node not found")
            return
        }
        
        // setup audio file
        let bus = 0
        guard let file = try? AVAudioFile(forWriting: fileURL,settings: input.outputFormatForBus(bus).settings) else {
            AppUtil.alert("ERROR", message: "creating audio file for recording failed")
            return
        }
        
        fileForRecording = file
        recording = true
    }
    
    func stopRecording() {
        if recording {
            recording = false
            fileForRecording = nil
        }
    }
    
    let defaultPitch: Float = 2000
    func startPlaying(fileURL: NSURL, completion: (() -> Void)? = nil) {
        startPlaying(fileURL, pitchShinfted: false, completion: completion)
    }
    
    func startPlaying(fileURL: NSURL, pitchShinfted: Bool, completion: (() -> Void)? = nil) {
        stopPlaying()
        guard let file = try? AVAudioFile(forReading: fileURL) else {
            AppUtil.alert("ERROR", message: "reading recording file failed")
            return
        }
        let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        do {
            try file.readIntoBuffer(buffer)
        } catch {
            AppUtil.alert("ERROR", message: "can not read file")
        }
        
        if pitchShinfted {
            pitch.pitch = defaultPitch
        } else {
            pitch.pitch = 0
        }
        
        // フォーマット変更
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: mixer, format: buffer.format)
        
        startEngine()
        player.scheduleBuffer(buffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: {
            if let comp = completion {
                comp()
            }
            self.playing = false
            if self.loop {
                self.startPlaying(fileURL, pitchShinfted: pitchShinfted, completion: completion)
            }
        })
        player.play()
        playing = true
    }
    
    func stopPlaying() {
        if player.playing {
            player.stop()
        }
    }
    
    static let shared = AudioEngineManager()
    class func setup() {
        let _ = shared
    }
}

@objc protocol AudioEngineManagerSpeechDetectionDelegate {
    func audioEngineManagerDidStartSpeechDetection(manager: AudioEngineManager)
    func audioEngineManagerDidFinishSpeechDetection(manager: AudioEngineManager)
}
