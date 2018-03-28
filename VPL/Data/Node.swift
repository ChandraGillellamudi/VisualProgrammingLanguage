//
//  Node.swift
//  VPL
//
//  Created by Nathan Flurry on 3/26/18.
//  Copyright © 2018 Nathan Flurry. All rights reserved.
//

// TODO: Add `declaredVariables` to `outputTrigger` so things like `var` and for loops can add defined variables
// TODO: Handle recursive issue

import Foundation

enum SocketLocation {
    case input, output
    
    /// If this location compliments another; e.g. this is an input and the
    /// other is an output and vice versa.
    func compliments(location: SocketLocation) -> Bool {
        switch self {
        case .input:
            return location == .output
        case .output:
            return location == .input
        }
    }
}

final class NodeTrigger {
    /// Reference to the node that owns this trigger.
    weak var owner: Node!
    
    /// An ID for the trigger.
    var id: String
    
    /// The trigger that this points to.
    var target: NodeTrigger? = nil
    
    /// If this is an input or output trigger.
    var location: SocketLocation {
        if let input = owner.inputTrigger, input === self {
            return .input
        } else if let output = owner.outputTrigger, output === self {
            return .output
        } else if owner.extraOutputTriggers.contains(where: { $0 === self }) {
            return .output
        } else {
            fatalError("Trigger is neither an input or output.")
        }
    }
    
    /// Creates a new input trigger.
    static func inputTrigger() -> NodeTrigger {
        return NodeTrigger(id: "in")
    }
    
    /// Creates a new output trigger.
    static func outputTrigger() -> NodeTrigger {
        return NodeTrigger(id: "out")
    }
    
    /// Creates a new trigger with a given ID.
    init(id: String) {
        self.id = id
    }
    
    /// If this trigger can be connected to another trigger.
    func canConnect(to target: NodeTrigger) -> Bool {
        // Make sure they can be connected and the target is not already connected to something else
        return location.compliments(location: target.location) && target.target == nil
    }
    
    /// Resets the socket so there is no target.
    func reset() {
        target?.target = nil
        target = nil
    }
    
    func connect(to target: NodeTrigger) {
        // Assert that the target is not already set
        assert(self.target == nil)
        assert(target.target == nil)
        
        // Assert that inputs are connecting to outputs or vice versa
        if owner.inputTrigger === self {
            assert(target.owner.outputTrigger === target || target.owner.extraOutputTriggers.contains { $0 === target })
        } else if owner.outputTrigger === self || owner.extraOutputTriggers.contains(where: { $0 === self }) {
            assert(target.owner.inputTrigger === target)
        } else {
            // This value should bein the input or outputs of the owner
            assertionFailure()
        }
        
        // Assign the target
        self.target = target
        target.target = self
    }
    
    func assemble() -> String {
        return target?.owner.assemble() ?? ""
    }
}

final class NodeValue {
    weak var owner: Node!
    let id: String
    let type: ValueType
    var target: NodeValue? = nil
    
    /// If this is an input or output value.
    var location: SocketLocation {
        if owner.inputValues.contains(where: { $0 === self }) {
            return .input
        } else if owner.outputValues.contains(where: { $0 === self }) {
            return .output
        } else {
            fatalError("Value is neither an input or output.")
        }
    }
    
    init(id: String, type: ValueType) {
        self.id = id
        self.type = type
    }
    
    /// If this value can be connected to another value.
    func canConnect(to target: NodeValue) -> Bool {
        return location.compliments(location: target.location) && target.target == nil && type == target.type
    }
    
    /// Resets the socket so there is no target.
    func reset() {
        target?.target = nil
        target = nil
    }
    
    func connect(to target: NodeValue) {
        // Assert that a target is not already set
        assert(self.target == nil)
        assert(target.target == nil)
        
        // Assert that inputs are connecting to outputs or vice versa
        if owner.inputValues.contains(where: { $0 === self }) {
            assert(target.owner.outputValues.contains { $0 === target })
        } else if owner.outputValues.contains(where: { $0 === self }) {
            assert(target.owner.inputValues.contains { $0 === target })
        } else {
            // This value should bein the input or outputs of the owner
            assertionFailure()
        }
        
        // Assign the target
        self.target = target
        target.target = self
    }
    
    func assemble() -> String {
        return target?.owner.assemble() ?? ""
    }
}

protocol Node: class {
    var id: String { get }
    var name: String { get }
    var inputTrigger: NodeTrigger? { get }
    var outputTrigger: NodeTrigger? { get }
    var extraOutputTriggers: [NodeTrigger] { get }
    var inputValues: [NodeValue] { get }
    var outputValues: [NodeValue] { get }
    
    init()
    
    func assemble() -> String
}

extension Node {
    func assembleOutputTrigger() -> String {
        return outputTrigger?.assemble() ?? ""
    }
}

extension Node {
    var inputTrigger: NodeTrigger? { return nil }
    var outputTrigger: NodeTrigger? { return nil }
    var extraOutputTriggers: [NodeTrigger] { return [] }
    var inputValues: [NodeValue] { return [] }
    var outputValues: [NodeValue] { return [] }
}

extension Node {
    func setupConnections() {
        setupTrigger(connection: inputTrigger)
        setupTrigger(connection: outputTrigger)
        for trigger in extraOutputTriggers { setupTrigger(connection: trigger) }
        for value in inputValues { setupValue(connection: value) }
        for value in outputValues { setupValue(connection: value) }
    }
    
    private func setupTrigger(connection: NodeTrigger?) {
        guard let connection = connection else { return }
        connection.owner = self
    }
    
    private func setupValue(connection: NodeValue?) {
        guard let connection = connection else { return }
        connection.owner = self
    }
}