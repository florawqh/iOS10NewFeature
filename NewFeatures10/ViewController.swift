//
//  ViewController.swift
//  NewFeatures10
//
//  Created by WangQionghua on 17/09/2016.
//  Copyright © 2016 Flora Wang. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
    let tapMessage = "Tap to start recording"
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var audioPlayer: AVAudioPlayer!
    
    
    @IBOutlet weak var outputField: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet var exampleText: UILabel!
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle(tapMessage, for: [])
            indicator.isHidden = true
        } else {
            startRecording()
            recordButton.setTitle("Recording... Tap to stop", for: .normal)
            indicator.isHidden = false
        }
    }
    
    @IBOutlet var replayButton: UIButton!
    @IBAction func replayButtonPressed(_ sender: AnyObject) {
        testRecordFile()
        recordButton.isEnabled = false
        
    }
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSR()
    }
    
    //MARK: - 2. request authorization
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
    
    // MARK: - 3. Create a speech recognition request for pre-recorded audio
    private func recognizeFile(url: URL) {
        // Cancel the previous task if it's running
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                // handle error
                return
            }
            if result.isFinal {
                self.outputField.text = result.bestTranscription.formattedString
            }
            
        }
    }
    
    private func testRecordFile() {
        if let path = Bundle.main.url(forResource: "55", withExtension: "mp3") {
            do {
                let sound = try AVAudioPlayer(contentsOf: path)
                audioPlayer = sound
                audioPlayer.delegate = self
                sound.play()
            } catch {
                print("Audio play error!")
            }
            
            recognizeFile(url: path)
        }
    }
    
    // MARK: - 3. Create a speech recognition request for live audio
    private func startRecording() {
        
        // Cancel the previous task if it's running
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
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        // Set recognition request for microphone record
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // MARK - 4.
        // Start a speech recognition session.
        // Keep reference to the task so that it can be cancelled.
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
                self.recordButton.setTitle(self.tapMessage, for: [])
                
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
}

// MARK: - 5. SFSpeechRecognizerDelegate
extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle(tapMessage, for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
}

// MARK: - 6. AVAudioPlayerDelegate
extension ViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.stop()
        indicator.isHidden = true
        recordButton.isEnabled = true
        
    }
}

