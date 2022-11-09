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
        
        if (question != nil && question!.timeToShow == Date.distantFuture) {
            question?.firstShown = Date()
        }
        
        //dette blir stygt...
        if (question != nil) {
            replyHandler(["anagram": question!.anagram,
            "answers": question!.answers,
            "due": getDue(),
            "percentage": getPercentage()])
        } else {
            replyHandler(["anagram": "FAAAAIL",
            "answers": "feilfeil",
            "due": 999,
            "percentage": "0.00"])
        }
        
    }
    
    func getNewToday() -> Int {
        questions[currentKey]!.getNewToday()
    }
    
    func getDue() -> Int {
        questions[currentKey]!.getDue()
    }
    
    func getPercentage() -> String {
        String(format: "%.2f", questions[currentKey]!.getPercentage())
    }
    
    func getSeenCount() -> Int {
        questions[currentKey]!.getSeen()
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
            
            print("finner load")

            questions = loadedQuestions
            
            //Noen blir lagret med timeToShow = distant future.
            //Tror kanskje det skjer når både klokka og mobilen er aktiv..?
            //for question in questions["7"]!.seenQuestions {
            //    print("\(question.anagram): next: \(question.timeToShow) firstSeen: \(question.firstShown)")
            //}
            
        } else {
            
            questions["7"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2022-unseen-7")),
                seenQuestions: linesToSeenQuestions(lines: loadQuestionsFromResources(resource: "2022-seen-7")))
            questions["8"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2022-unseen-8")),
                seenQuestions: linesToSeenQuestions(lines: loadQuestionsFromResources(resource: "2022-seen-8")))
            questions["C"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2022-erantslik-C")))
            questions["W"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2022-erantslik-W")))
        }
    }
    
    func linesToSeenQuestions(lines: [String]) -> [Question] {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
        var questionArray = [Question]()
        for line in lines {
            let components = line.components(separatedBy: ";")
            let componentsB = components[0].components(separatedBy: " ")
            let daysToAdd = Int(componentsB[0])!
            let timeToShow = dateFormatter.date(from: "\(componentsB[1]) 00:00:00")!
            let anagram = componentsB[2]
            let answers = components[1].components(separatedBy: " ")
            questionArray.append(Question(anagram: anagram, answers: answers, timeToShow: timeToShow, daysToAdd: daysToAdd))
        }
        return questionArray
    }
    
    func linesToQuestions(lines: [String]) -> [Question] {
        var questionArray = [Question]()
        for line in lines {
            let components = line.components(separatedBy: ";")
            let anagram = components[0]
            let answers = components[1].components(separatedBy: " ")
            questionArray.append(Question(anagram: anagram, answers: answers))
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
