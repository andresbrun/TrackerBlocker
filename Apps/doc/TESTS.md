## Tests

### Unit Tests
The project includes a comprehensive suite of unit tests to ensure the reliability and correctness of the application's core functionalities. Below is a summary of the key unit tests implemented:

- **WKContentRuleListManagerTests**
  - Validates the initialization process with various scenarios, such as no cached rules or new ETag values.
  - Tests the handling of whitelist domain updates and ensures that rule list updates are triggered appropriately.

- **WebViewModelTests**
  - Tests the loading of default and specific URLs, including handling invalid URLs by performing searches.
  - Verifies navigation actions such as going back and forward.
  - Ensures the correct handling of rule list state updates and their impact on the current web page.

- **WhitelistDomainsListViewModelTests**
  - Tests the addition of valid, invalid, and duplicate domains to the whitelist.
  - Ensures that appropriate alerts are presented for invalid or duplicate domain entries.

These tests are designed to cover critical aspects of the application's functionality, providing confidence in the app's behavior and facilitating future development and refactoring efforts.

### Manual Tests

#### Tracker Functionality Verification
- **Test Description:** Executed tests on [Cover Your Tracks](https://coveryourtracks.eff.org/) with tracker functionality enabled and disabled.
- **Expected Behavior:** The application should exhibit different behaviors based on the tracker functionality state.
- **Result:** OK

#### Tracker Detection via Proxyman
- **Test Description:** Monitored network requests for tracker activity on the following websites using Proxyman:
  - **Youtube**
  - **Ebay**
  - **Amazon**
  - **Facebook**
- **Results and Observations:**
  - **Youtube:** [Document specific observations here]
  - **Ebay:** [Document specific observations here]
  - **Amazon:** [Document specific observations here]
  - **Facebook:** [Document specific observations here] 