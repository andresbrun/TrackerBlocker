import XCTest
@testable import iOS

class StringURLDetectorTests: XCTestCase {

    func testExtractURLsWithValidURL() {
        let string = "duckduckgo.com"
        let expectedURLs = [
            URL(string: "http://duckduckgo.com")!
        ]
        
        let extractedURLs = string.extractURLs()
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URL should match the expected URL.")
    }
    
    func testExtractURLsWithAWord() {
        let string = "Duck"
        let extractedURLs = string.extractURLs()
        
        XCTAssertTrue(extractedURLs.isEmpty, "The extracted URLs should be empty for a string with no URLs.")
    }
    
    func testExtractURLsWithSentence() {
        let string = "How to bake a cake"
        let extractedURLs = string.extractURLs()
        
        XCTAssertTrue(extractedURLs.isEmpty, "The extracted URLs should be empty for a sentence with no URLs.")
    }
    
    func testExtractURLsWithFullURL() {
        let string = "https://www.youtube.com"
        let expectedURLs = [
            URL(string: "https://www.youtube.com")!
        ]
        
        let extractedURLs = string.extractURLs()
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URLs should include the valid URL.")
    }
    
    func testExtractURLsWithMalformedURLs() {
        let string = "http://example"
        let extractedURLs = string.extractURLs()
        let expectedURLs = [
            URL(string: "http://example")!
        ]
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URLs should include the URL.")
    }
} 
