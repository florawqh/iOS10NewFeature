//
//  ViewController.swift
//  NewFeatures10
//
//  Created by WangQionghua on 17/09/2016.
//  Copyright © 2016 Flora Wang. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var outputField: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet var exampleText: UILabel!
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Tap to start recording", for: .normal)
            indicator.isHidden = true
        } else {
            startRecording()
            recordButton.setTitle("Recording... Tap to stop", for: .normal)
            indicator.isHidden = false
        }
    }
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSR()
    }
    
    //2. request authorization
    private func setupSR() {
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { [weak self] (authStatus) in
            OperationQueue.main.addOperation() {
                
                var message = "Tap to start recording"
                switch authStatus {
                case .authorized:
                    self?.recordButton.isEnabled = true
                    self?.recordButton.setTitle(message, for: .normal)
                case .denied:
                    self?.recordButton.isEnabled = false
                    message = "You denied access to speech recognition"
                    self?.recordButton.setTitle(message, for: .disabled)
                case .restricted:
                    self?.recordButton.isEnabled = false
                    message = "Speech recognition restricted on this device"
                    self?.recordButton.setTitle(message, for: .disabled)
                case .notDetermined:
                    self?.recordButton.isEnabled = false
                    message = "Speech recognition not yet authorized"
                    self?.recordButton.setTitle(message, for: .disabled)
                }
            }
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.outputField.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        outputField.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
        } else {
            recordButton.isEnabled = false
        }
    }
}

