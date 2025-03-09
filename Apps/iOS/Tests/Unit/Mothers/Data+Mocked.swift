import Foundation

extension Data {
    static var mockedData: [String: Any] = [
        "trackers": [
            "1558334541.rsc.cdn77.org": [
                "domain": "1558334541.rsc.cdn77.org",
                "owner": [
                    "name": "DataCamp Limited",
                    "displayName": "DataCamp"
                ],
                "prevalence": 0.0000613,
                "fingerprinting": 3,
                "cookies": 0.0000545,
                "categories": [],
                "default": "ignore",
                "rules": [
                    [
                        "rule": "1558334541\\.rsc\\.cdn77\\.org\\/nfs\\/20221227\\/etp\\.min\\.js",
                        "fingerprinting": 3,
                        "cookies": 0.0000136
                    ],
                    [
                        "rule": "1558334541\\.rsc\\.cdn77\\.org\\/nfs\\/20221104\\/etpnoauid\\.min\\.js",
                        "fingerprinting": 3,
                        "cookies": 0.0000136
                    ]
                ]
            ]
        ],
        "entities": [
            "DataCamp Limited": [
                "domains": [
                    "cdn77.org",
                    "datacamp.com",
                    "rdocumentation.org"
                ],
                "prevalence": 0.0551,
                "displayName": "DataCamp"
            ]
        ],
        "domains": [
            "cdn77.org": "DataCamp Limited"
        ],
        "cnames": [
            "aax-eu.amazon.se": "aax-eu-retail-direct.amazon-adsystem.com"
        ]
    ]
    
    static var mockedTDS: Data {
        try! JSONSerialization.data(
            withJSONObject: mockedData,
            options: []
        )
    }
} 