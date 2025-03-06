import XCTest
@testable import iOS

class StringURLDetectorTests: XCTestCase {

    func testExtractURLs_withValidURL() {
        let string = "duckduckgo.com"
        let expectedURLs = [
            URL(string: "http://duckduckgo.com")!
        ]
        
        let extractedURLs = string.extractURLs()
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URL should match the expected URL.")
    }
    
    func testExtractURLs_withAWord() {
        let string = "Duck"
        let extractedURLs = string.extractURLs()
        
        XCTAssertTrue(extractedURLs.isEmpty, "The extracted URLs should be empty for a string with no URLs.")
    }
    
    func testExtractURLs_withSentence() {
        let string = "How to bake a cake"
        let extractedURLs = string.extractURLs()
        
        XCTAssertTrue(extractedURLs.isEmpty, "The extracted URLs should be empty for a sentence with no URLs.")
    }
    
    func testExtractURLs_withFullURL() {
        let string = "https://www.youtube.com"
        let expectedURLs = [
            URL(string: "https://www.youtube.com")!
        ]
        
        let extractedURLs = string.extractURLs()
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URLs should include the valid URL.")
    }
    
    func testExtractURLs_withMalformedURLs() {
        let string = "http://example"
        let extractedURLs = string.extractURLs()
        let expectedURLs = [
            URL(string: "http://example")!
        ]
        
        XCTAssertEqual(extractedURLs, expectedURLs, "The extracted URLs should include the URL.")
    }
} 
