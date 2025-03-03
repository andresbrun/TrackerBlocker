import WebKit
import Combine
import os

final public class UserContentController: WKUserContentController {
    private let ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger.default
    
    private var ruleList: WKContentRuleList? {
        didSet {
            logger.info("UserContentController: Applying new rules")
            removeAllContentRuleLists()
            ruleList.map(add)
        }
    }
    
    init(ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>) {
        self.ruleListStateUpdates = ruleListStateUpdates
        super.init()
        subscribeToRuleListStateUpdates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func subscribeToRuleListStateUpdates() {
        ruleListStateUpdates
            .sink { [weak self] stateUpdates in
                guard let self, let stateUpdates = stateUpdates else { return }
                ruleList = stateUpdates.ruleList
            }
            .store(in: &cancellables)
    }
}
