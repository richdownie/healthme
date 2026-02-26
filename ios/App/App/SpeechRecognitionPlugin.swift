import Foundation
import Capacitor
import Speech
import AVFoundation

@objc(SpeechRecognitionPlugin)
public class SpeechRecognitionPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SpeechRecognitionPlugin"
    public let jsName = "SpeechRecognition"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise)
    ]

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @objc func isAvailable(_ call: CAPPluginCall) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                let available = status == .authorized && (self?.speechRecognizer?.isAvailable ?? false)
                call.resolve(["available": available])
            }
        }
    }

    @objc func start(_ call: CAPPluginCall) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    call.reject("Speech recognition not authorized")
                    return
                }
                self?.requestMicAndStart(call)
            }
        }
    }

    @objc func stop(_ call: CAPPluginCall) {
        cleanup()
        call.resolve()
    }

    private func requestMicAndStart(_ call: CAPPluginCall) {
        AVAudioApplication.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard allowed else {
                    call.reject("Microphone access not granted")
                    return
                }
                self?.startRecognition(call)
            }
        }
    }

    private func startRecognition(_ call: CAPPluginCall) {
        if audioEngine.isRunning {
            cleanup()
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            call.reject("Speech recognizer not available")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                call.reject("Unable to create recognition request")
                return
            }
            recognitionRequest.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    self.notifyListeners("result", data: [
                        "transcript": result.bestTranscription.formattedString,
                        "isFinal": result.isFinal
                    ])
                    if result.isFinal {
                        self.cleanup()
                    }
                }

                if error != nil && !self.audioEngine.isRunning {
                    self.cleanup()
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            call.resolve()
        } catch {
            call.reject("Audio engine error: \(error.localizedDescription)")
        }
    }

    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
