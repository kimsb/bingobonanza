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
            
            if (correct!) {
                print("last answer was correct!")
            } else {
                print("last answer was wrong...")
            }
            lastQuestion!.setTimeToShow(answeredCorrect: correct!)
            print("last anagram: \(lastAnagram)")
        }
        
        let question = getNextQuestion(listKey: listKey, lastAnswered: lastQuestion)
        
        print("returning answers: \(question.answers)")
        
        replyHandler(["anagram": question.anagram,
                      "answers": question.answers,
                      "due": getDue()])
        
    }
    
    func getDue() -> Int {
        questions[currentKey]!.getDue()
    }
    
    func getNextQuestion(listKey: String, lastAnswered: Question? = nil) -> Question {
        lastQuestion = questions[listKey]!.getNextQuestion(lastQuestion: lastAnswered)
        return lastQuestion!
    }
    
    func saveQuestions() {
        DispatchQueue.global(qos: .userInitiated).async {
            NSKeyedArchiver.archiveRootObject(self.questions, toFile: Questions.ArchiveURL.path)
        }
    }
    
    func loadQuestions() {
        if let loadedQuestions = NSKeyedUnarchiver.unarchiveObject(withFile: Questions.ArchiveURL.path) as? [String:Questions] {
            questions = loadedQuestions
            print("loader questions fra device")
            print("7 count: \(String(describing: questions["7"]?.newQuestions.count))")
        } else {
            
            let nye = linesToQuestions(lines: loadQuestionsFromResources(resource: "7-nye"))
            let mature = linesToQuestions(lines: loadQuestionsFromResources(resource: "7-sett"), isMature: true)
            
            print("nye 7 = \(nye.count)")
            print("mature 7 = \(mature.count)")
            
            var alleSjuere = [Question]()
            for index in 0..<nye.count {
                if (index < mature.count) {
                    alleSjuere.append(mature[index])
                }
                alleSjuere.append(nye[index])
            }
            
            print("alle 7 = \(alleSjuere.count)")
            
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
        print("isMature: \(isMature)")
        print("first: \(questionArray.first!.anagram) \(questionArray.first!.answers)")
        print("last: \(questionArray.last!.anagram) \(questionArray.last!.answers)")
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
