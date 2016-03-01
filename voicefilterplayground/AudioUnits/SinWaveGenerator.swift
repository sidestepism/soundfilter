//
//  LowPassFilter.swift
//  voicefilterplayground
//
//  Created by Ryohei Fushimi on 2016/3/1.
//  Copyright © 2016 fushimir. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation


class SinWaveGeneratorData
{
    var time: Float = 0.0;
}

class SinWaveGenerator
{

    var data: SinWaveGeneratorData = SinWaveGeneratorData()
    var acd: AudioComponentDescription = AudioComponentDescription()

    var audioUnit: AudioUnit;

    init()
    {
        // AudioUnitの準備
        audioUnit = AudioUnit();

        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_GenericOutput;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;

        // AudioComponentの生成
        var ac: AudioComponent = AudioComponentFindNext(nil, &acd);
        // AudioUnitとAudioComponentとの関連づけ
        AudioComponentInstanceNew(ac, &audioUnit);
        
        // 音声処理のコールバックメソッドを準備
        // メソッドとメソッドに渡すデータを用意しておきます。
        var input = AURenderCallbackStruct(inputProc: RenderCallback, inputProcRefCon: &data);
        
        // AudioUnitとコールバックメソッドの関連づけ
        AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, UInt32(sizeofValue(input)));
        
        // AudioUnitの初期化
        AudioUnitInitialize(audioUnit);
    }
    
    
}