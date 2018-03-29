//
//  MiscNodes.swift
//  VPL
//
//  Created by Nathan Flurry on 3/28/18.
//  Copyright © 2018 Nathan Flurry. All rights reserved.
//

import UIKit

class PrintNode: DisplayableNode {
    static let shortcutCharacter: String? = "P"
    
    static let id: String = "print"
    static let name: String = "Print"
    var inputTrigger: InputTrigger? = InputTrigger()
    var inputValues: [InputValue] = [InputValue(id: "value", name: "Value", type: .string)]
    var output: NodeOutput = .triggers([OutputTrigger()])
    
    required init() {
        self.setupConnections()
    }
    
    func assemble() -> String {
        var out = ""
        out !+= "print(\(inputValues[0].assemble()))"
        return out + assembleOutputTrigger()
    }
}
