import Foundation

extension String {
    func extractURLs() -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        var urls: [URL] = []
        detector.enumerateMatches(
            in: self,
            options: [],
            range: NSMakeRange(0, self.count),
            using: { (result, _, _) in
                guard let match = result, let url = match.url else { return }
                urls.append(url)
            }
        )
        
        return urls
    }
}
