//
//  SessionHandler.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 02/01/2020.
//  Copyright © 2020 Kim Stephen Bovim. All rights reserved.
//

import Foundation
import WatchConnectivity

class SessionHandler : NSObject, WCSessionDelegate {
    
    // 1: Singleton
    static let shared = SessionHandler()
    
    // 2: Property to manage session
    var session = WCSession.default
    
    private var questions = [String:Questions]()
    private var lastQuestion: Question?
    private let listKeys = ["7", "8", "C", "W"]
    private var currentKey = "7"
    
    override init() {
        super.init()
        
        // 3: Start and avtivate session if it's supported
        if isSuported() {
            session.delegate = self
            session.activate()
        }
        
        print("isPaired?: \(session.isPaired), isWatchAppInstalled?: \(session.isWatchAppInstalled)")
    }
    
    func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    
    // MARK: - WCSessionDelegate
    
    // 4: Required protocols
    
    // a
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    // b
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    // c
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        // Reactivate session
        /**
         * This is to re-activate the session on the phone when the user has switched from one
         * paired watch to second paired one. Calling it like this assumes that you have no other
         * threads/part of your code that needs to be given time before the switch occurs.
         */
        self.session.activate()
    }
    
    /// Observer to receive messages from watch and we be able to response it
    ///
    /// - Parameters:
    ///   - session: session
    ///   - message: message received
    ///   - replyHandler: response handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        let listKey = message["nextQuestion"] as! String
        if (currentKey != listKey) {
            lastQuestion = nil
            currentKey = listKey
        }
        
        let correct = message["correct"] as? Bool
        if (correct != nil) {
            let lastAnagram = message["lastAnagram"] as! String
            if (lastQuestion?.anagram != lastAnagram) {
                print("returned lastAnagram: \(lastAnagram) last anagram is: \(String(describing: lastQuestion?.anagram))")
                replyHandler(["anagram": lastQuestion!.anagram,
                              "answers": lastQuestion!.answers,
                             "due": getDue()])
                return
            }
            lastQuestion!.setTimeToShow(answeredCorrect: correct!)
            print("last anagram: \(lastAnagram)")
        }
        
        let question = getNextQuestion(lastAnswered: lastQuestion)
        
        //dette blir stygt...
        if (question != nil) {
            replyHandler(["anagram": question!.anagram,
            "answers": question!.answers,
            "due": getDue()])
        } else {
            replyHandler(["anagram": "FAAAAIL",
            "answers": "feilfeil",
            "due": 999])
        }
        
    }
    
    func getDue() -> Int {
        questions[currentKey]!.getDue()
    }
    
    func getPercentage() -> Double {
        questions[currentKey]!.getPercentage()
    }
    
    func setCurrentKey(keyIndex: Int) {
        currentKey = listKeys[keyIndex]
    }
    
    func getNextQuestion(lastAnswered: Question? = nil) -> Question? {
        //TODO - denne krasjer når null
        lastQuestion = questions[currentKey]?.getNextQuestion(lastQuestion: lastAnswered)
        return lastQuestion
    }
    
    func saveQuestions() {
        DispatchQueue.global(qos: .userInitiated).async {
            NSKeyedArchiver.archiveRootObject(self.questions, toFile: Questions.ArchiveURL.path)
        }
    }
    
    func loadQuestions() {
        if let loadedQuestions = NSKeyedUnarchiver.unarchiveObject(withFile: Questions.ArchiveURL.path) as? [String:Questions] {
            
            //LEGGE TIL NYE ORD
            /*let nye7 = linesToQuestions(lines: loadQuestionsFromResources(resource: "puggeliste-nye-2020"))
            
            print("første nye: \(nye7.first!.anagram): \(nye7.first!.answers)")
            
            let nyeAnagrammer = nye7.map { $0.anagram }
            let fjernetNewQuestions = loadedQuestions["7"]!.newQuestions.filter{!nyeAnagrammer.contains($0.anagram)}
            
            let fjernetSeenQuestions = loadedQuestions["7"]!.seenQuestions.filter{!nyeAnagrammer.contains($0.anagram)}
            
            let nyeNewMedGamleNew = nye7 + fjernetNewQuestions
            
            loadedQuestions["7"]!.seenQuestions = fjernetSeenQuestions
            loadedQuestions["7"]!.newQuestions = nyeNewMedGamleNew*/
            
            
            
            
            //SLETTING
            /*let slettes = loadQuestionsFromResources(resource: "slettes-C")
            
            //SLETTE FRA NEW
            let loadedNye = loadedQuestions["C"]!.newQuestions
            
            print("loaded count: \(loadedNye.count)")
            
            let slettetAnswersNye = loadedNye.map { (question: Question) -> Question in
                let mutable = question
                mutable.answers = question.answers.filter{!slettes.contains($0)}
                return mutable
            }
            let fjernetTommeAnswersNye = slettetAnswersNye.filter{!$0.answers.isEmpty}
            print("fjernet count: \(fjernetTommeAnswersNye.count)")
            
            //SLETTE FRA SEEN
            let loadedSeen = loadedQuestions["C"]!.seenQuestions
                       
            print("loaded seen count: \(loadedSeen.count)")
                       
            let slettetAnswersSeen = loadedSeen.map { (question: Question) -> Question in
                let mutable = question
                mutable.answers = question.answers.filter{!slettes.contains($0)}
                return mutable
            }
            let fjernetTommeAnswersSeen = slettetAnswersSeen.filter{!$0.answers.isEmpty}
            print("fjernet seen count: \(fjernetTommeAnswersSeen.count)")
            
            //loadedQuestions["C"]!.seenQuestions = fjernetTommeAnswersSeen
            //loadedQuestions["C"]!.newQuestions = fjernetTommeAnswersNye*/
            //SLETTING SLUTT - HUSK Å SVARE PÅ ET SPM, SÅ ENDRINGER BLIR LAGRET
            
            questions = loadedQuestions
        } else {
            
            let nye = linesToQuestions(lines: loadQuestionsFromResources(resource: "7-nye"))
            let mature = linesToQuestions(lines: loadQuestionsFromResources(resource: "7-sett"), isMature: true)
                        
            var alleSjuere = [Question]()
            for index in 0..<nye.count {
                if (index < mature.count) {
                    alleSjuere.append(mature[index])
                }
                alleSjuere.append(nye[index])
            }
            
            print("alleSjuere: \(alleSjuere.count)")
                        
            questions["7"] = Questions(newQuestions: alleSjuere)
            questions["8"] = Questions(newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "8-anki")))
            questions["C"] = Questions(newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "C-anki")))
            questions["W"] = Questions(newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "W-anki")))
        }
    }
    
    func linesToQuestions(lines: [String], isMature: Bool = false) -> [Question] {
        var questionArray = [Question]()
        for line in lines {
            let components = line.components(separatedBy: ";")
            let anagram = components[0]
            let answers = components[1].components(separatedBy: " ")
            questionArray.append(Question(anagram: anagram, answers: answers, isMature: isMature))
        }
        return questionArray
    }
    
    func loadQuestionsFromResources(resource: String) -> [String] {
        let path = Bundle.main.path(forResource: resource, ofType: "txt")
        let contents = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        let lines = contents.split(separator:"\n")
        var liste = [String]()
        for line in lines {
            liste.append(String(line))
        }
        return liste
    }
}
