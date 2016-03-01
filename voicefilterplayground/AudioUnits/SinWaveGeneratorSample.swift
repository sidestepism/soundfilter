//
//  PinkNoiseGenerator.swift
//  voicefilterplayground
//
//  Created by Ryohei Fushimi on 2016/3/1.
//  Copyright © 2016 fushimir. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

func RenderCallback (
    inRefCon: UnsafeMutablePointer<Void>,
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>) -> (OSStatus)
{
    let tmp: UnsafeMutablePointer<SoundPlayerData> = UnsafeMutablePointer<SoundPlayerData>(inRefCon);
    let data: SoundPlayerData = tmp.memory;
    let buf: AudioBufferList = ioData.memory;
    var datas: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>(buf.mBuffers.mData);
    
    let sineWaveFreq: Float = 440.0;
    let samplingRate: Float = 44100.0;
    let freq: Float = sineWaveFreq * 2.0 * Float(M_PI) / samplingRate;
    
    for(var i: UInt32 = 0; i < inNumberFrames; i++)
    {
        var tmpVal: Float = sin(data.time);
        memcpy(datas, &tmpVal, sizeof(Float));
        datas++;
        data.time += freq;
    }
    
    return noErr;
}

class SoundPlayerData
{
    var time: Float = 0.0;
}

class SoundPlayer
{
    var audioUnit: AudioUnit?;
    var acd: AudioComponentDescription?;
    var ac: AudioComponent?;
    var data: SoundPlayerData = SoundPlayerData();
    var isPlaying: Bool = false;
    
    func play()
    {
        // AudioUnitの準備
        audioUnit = AudioUnit();
        
        // AudioComponentDescriptionの準備
        acd = AudioComponentDescription();
        acd?.componentType = kAudioUnitType_Output;
        acd?.componentSubType = kAudioUnitSubType_GenericOutput;
        acd?.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd?.componentFlags = 0;
        acd?.componentFlagsMask = 0;
        
        // AudioComponentの生成
        ac = AudioComponentFindNext(nil, &acd!);
        
        // AudioUnitとAudioComponentとの関連づけ
        AudioComponentInstanceNew(ac!, &audioUnit!);
        
        // 音声処理のコールバックメソッドを準備
        // メソッドとメソッドに渡すデータを用意しておきます。
        var input = AURenderCallbackStruct(inputProc: RenderCallback, inputProcRefCon: &data);
        
        // AudioUnitとコールバックメソッドの関連づけ
        AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, UInt32(sizeofValue(input)));
        
        // AudioUnitの初期化
        AudioUnitInitialize(audioUnit!);
        
        // 音声再生実行開始
        AudioOutputUnitStart(audioUnit!);
        isPlaying = true;
    }
    
    func stop()
    {
        if(audioUnit == nil || isPlaying == false)
        {
            return;
        }
        
        AudioOutputUnitStop(audioUnit!);
        audioUnit = nil;
    }
}
