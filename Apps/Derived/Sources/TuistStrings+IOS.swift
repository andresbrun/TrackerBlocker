// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum IOSStrings: Sendable {

  public enum Webviewcontroller: Sendable {

    public enum AddressTextfield: Sendable {
    /// Enter the web address you want to visit
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.address_textfield.accessibility_hint")
      /// Address Field
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.address_textfield.accessibility_label")
      /// Search or enter address
      public static let placeholder = IOSStrings.tr("Localizable", "webviewcontroller.address_textfield.placeholder")
    }

    public enum BackButton: Sendable {
    /// Go back to the previous page
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.back_button.accessibility_hint")
      /// Back
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.back_button.accessibility_label")
    }

    public enum Error: Sendable {

      public enum Generic: Sendable {
      /// A server with the specified hostname could not be found
        public static let description = IOSStrings.tr("Localizable", "webviewcontroller.error.generic.description")
        /// TrackerBlocker MVP can't load this page.
        public static let title = IOSStrings.tr("Localizable", "webviewcontroller.error.generic.title")
      }
    }

    public enum ForwardButton: Sendable {
    /// Go forward to the next page
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.forward_button.accessibility_hint")
      /// Forward
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.forward_button.accessibility_label")
    }

    public enum OpenWhitelistDomainsButton: Sendable {
    /// View the list of whitelisted domains
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.open_whitelist_domains_button.accessibility_hint")
      /// Open Whitelist Domains
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.open_whitelist_domains_button.accessibility_label")
    }

    public enum ProgressBar: Sendable {
    /// Loading Progress
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.progress_bar.accessibility_label")
    }

    public enum ReloadButton: Sendable {
    /// Reload the current page
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.reload_button.accessibility_hint")
      /// Reload
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.reload_button.accessibility_label")
    }

    public enum ToggleWhitelistDomainButton: Sendable {
    /// Toggle the current domain's whitelist status
      public static let accessibilityHint = IOSStrings.tr("Localizable", "webviewcontroller.toggle_whitelist_domain_button.accessibility_hint")
      /// Toggle Whitelist Domain
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "webviewcontroller.toggle_whitelist_domain_button.accessibility_label")
    }
  }

  public enum Whitelistdomainsview: Sendable {

    public enum Alert: Sendable {

      public enum DuplicatedDomain: Sendable {
      /// The domain '%1$@' is already in the list
        public static func description(_ p1: Any) -> String {
          return IOSStrings.tr("Localizable", "whitelistdomainsview.alert.duplicated_domain.description",String(describing: p1))
        }
        /// Duplicated Domain
        public static let title = IOSStrings.tr("Localizable", "whitelistdomainsview.alert.duplicated_domain.title")
      }

      public enum InvalidDomain: Sendable {
      /// The domain '%1$@' is not valid
        public static func description(_ p1: Any) -> String {
          return IOSStrings.tr("Localizable", "whitelistdomainsview.alert.invalid_domain.description",String(describing: p1))
        }
        /// Invalid Domain
        public static let title = IOSStrings.tr("Localizable", "whitelistdomainsview.alert.invalid_domain.title")
      }
    }

    public enum CloseButton: Sendable {
    /// Close the whitelist domains view
      public static let accessibilityHint = IOSStrings.tr("Localizable", "whitelistdomainsview.close_button.accessibility_hint")
      /// Close
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "whitelistdomainsview.close_button.accessibility_label")
    }

    public enum NavigationBar: Sendable {
    /// Protections
      public static let title = IOSStrings.tr("Localizable", "whitelistdomainsview.navigation_bar.title")
    }

    public enum NewDomainField: Sendable {
    /// Enter a new domain to whitelist
      public static let accessibilityHint = IOSStrings.tr("Localizable", "whitelistdomainsview.new_domain_field.accessibility_hint")
      /// New Domain Field
      public static let accessibilityLabel = IOSStrings.tr("Localizable", "whitelistdomainsview.new_domain_field.accessibility_label")
      /// Enter new domain
      public static let placeholder = IOSStrings.tr("Localizable", "whitelistdomainsview.new_domain_field.placeholder")
    }

    public enum Protections: Sendable {
    /// Protections **disabled** for this site
      public static let disabled = IOSStrings.tr("Localizable", "whitelistdomainsview.protections.disabled")
      /// Protections **enabled** for this site
      public static let enabled = IOSStrings.tr("Localizable", "whitelistdomainsview.protections.enabled")
    }

    public enum Section: Sendable {
    /// Unprotected Domains
      public static let allWebsites = IOSStrings.tr("Localizable", "whitelistdomainsview.section.all_websites")
      /// Current Domain
      public static let currentWebsite = IOSStrings.tr("Localizable", "whitelistdomainsview.section.current_website")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension IOSStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftlint:enable all
// swiftformat:enable all
