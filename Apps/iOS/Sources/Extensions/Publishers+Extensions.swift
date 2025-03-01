import Combine

extension Publishers {
    struct Pairwise<Upstream: Publisher>: Publisher {
        typealias Output = (Upstream.Output, Upstream.Output)
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        
        init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            var previous: Upstream.Output?
            upstream
                .filter { element -> Bool in
                    if previous == nil {
                        previous = element
                        return false
                    }
                    return true
                }
                .map { element -> Output in
                    let output = (previous!, element)
                    previous = element
                    return output
                }
                .receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    func pairwise() -> Publishers.Pairwise<Self> {
        Publishers.Pairwise(upstream: self)
    }
} 
