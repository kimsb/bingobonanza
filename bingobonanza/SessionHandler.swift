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
            //"percentage": getPercentage(),
            "newToday": questions[currentKey]!.getNewToday(),
            "wellDoneToday": wellDoneToday()])
        } else {
            replyHandler(["anagram": "FAAAAIL",
            "answers": ["feilfeil"],
            "due": 999,
            //"percentage": "0.00",
            "newToday": 0,
            "wellDoneToday": false])
        }
        
    }
    
    func wellDoneToday() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let janFirst = formatter.date(from: "2025/01/01 00:00")!
        let today = Calendar.current.startOfDay(for: Date())
        let numberOfDaysTilJanFirst = Calendar.current.dateComponents([.day], from: today, to: janFirst).day!
        let newToday = questions[currentKey]!.getNewToday()
        return (currentKey == "W" && newToday >= questions["W"]!.getNewCount() / numberOfDaysTilJanFirst)
        || (currentKey == "C" && newToday >= questions["C"]!.getNewCount() / numberOfDaysTilJanFirst)
        || (currentKey == "7" && newToday >= questions["7"]!.getNewCount() / numberOfDaysTilJanFirst)
        || (currentKey == "8" && newToday >= (6677 - questions["8"]!.getSeen()) / numberOfDaysTilJanFirst)
    }
    
    func getNewTodayText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let janFirst = formatter.date(from: "2025/01/01 00:00")!
        let today = Calendar.current.startOfDay(for: Date())
        let numberOfDaysTilJanFirst = Calendar.current.dateComponents([.day], from: today, to: janFirst).day!
        let newToday = questions[currentKey]!.getNewToday()
        if (currentKey == "W") {
            return newToday >= questions["W"]!.getNewCount() / numberOfDaysTilJanFirst ? "New: \(newToday) \u{1F389}\u{1F929}\u{1F57A}" : newToday > 0 ? "New: \(newToday) \u{1F44F}" : ""
        }
        if (currentKey == "C") {
            return newToday >= questions["C"]!.getNewCount() / numberOfDaysTilJanFirst ? "New: \(newToday) \u{1F389}\u{1F929}\u{1F57A}" : newToday > 0 ? "New: \(newToday) \u{1F44F}" : ""
        }
        if (currentKey == "7") {
            return newToday >= questions["7"]!.getNewCount() / numberOfDaysTilJanFirst ? "New: \(newToday) \u{1F389}\u{1F929}\u{1F57A}" : newToday > 0 ? "New: \(newToday) \u{1F44F}" : ""
        }
        // current == 8 ønsker 10% (6677)
        return newToday >= (6677 - questions["8"]!.getSeen()) / numberOfDaysTilJanFirst ? "New: \(newToday) \u{1F389}\u{1F929}\u{1F57A}" : newToday > 0 ? "New: \(newToday) \u{1F44F}" : ""
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
            
            //for å sette ord som jeg feilaktig har godkjent til å vises i dag:
            
            /*let words7 = ["DOBØKER", "KAMTANN", "FJØRLUS", "VASSYKT", "PROFANT"]
            for question in questions["7"]!.seenQuestions {
                for answer in question.answers {
                    if (words7.contains(answer)) {
                        question.timeToShow = Date()
                        question.daysToAdd = 1
                        question.wrongGuessCount = question.wrongGuessCount + 1
                        print("setter \(answer) til å vises i dag")
                    }
                }
            }*/
             
            
            
            /*let words8 = ["BORTSELG", "EPARKIET"]
            for question in questions["8"]!.seenQuestions {
                for answer in question.answers {
                    if (words8.contains(answer)) {
                        question.timeToShow = Date()
                        question.daysToAdd = 1
                        question.wrongGuessCount = question.wrongGuessCount + 1
                        print("setter \(answer) til å vises i dag")
                    }
                }
            }*/
            
            /*for question in questions["8"]!.seenQuestions {
                    print("\(question.anagram) \(question.daysToAdd) \(question.wrongGuessCount) \(question.timeToShow) \(question.firstShown)")
            }*/
            
            /*for question in questions["8"]!.seenQuestions {
                if (question.timeToShow == Date.distantFuture) {
                    print("\(question.anagram): next: \(question.timeToShow) firstSeen: \(question.firstShown)")
                    question.timeToShow = Date()
                }
            }*/
            
            //Noen blir lagret med timeToShow = distant future.
            //Tror kanskje det skjer når både klokka og mobilen er aktiv..?
            //for question in questions["7"]!.seenQuestions {
            //    print("\(question.anagram): next: \(question.timeToShow) firstSeen: \(question.firstShown)")
            //}
            
            //For å se hvilke anagrammer jeg sliter mest med:
            /*for question in questions["8"]!.seenQuestions.sorted(by: { $0.wrongGuessCount < $1.wrongGuessCount }) {
                print("\(question.wrongGuessCount): \(question.anagram)")
            }*/
            
            
        } else {
            
            questions["7"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2023-unseen-7")),
                seenQuestions: linesToSeenQuestions(lines: loadQuestionsFromResources(resource: "2023-seen-7")))
            questions["8"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2023-unseen-8")),
                seenQuestions: linesToSeenQuestions(lines: loadQuestionsFromResources(resource: "2023-seen-8")))
            questions["C"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2023-erantslik-C")))
            questions["W"] = Questions(
                newQuestions: linesToQuestions(lines: loadQuestionsFromResources(resource: "2023-erantslik-W")))
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
            let wrongGuessCount = Int(componentsB[1])!
            let timeToShow = dateFormatter.date(from: "\(componentsB[2]) 00:00:00")!
            let firstShown = dateFormatter.date(from: "\(componentsB[3]) 00:00:00")!
            let anagram = componentsB[4]
            let answers = components[1].components(separatedBy: " ")
            questionArray.append(Question(anagram: anagram, answers: answers, timeToShow: timeToShow, daysToAdd: daysToAdd, wrongGuessCount: wrongGuessCount, firstShown: firstShown))
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
