# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).
Format inspired by [ChangeLog](http://keepachangelog.com).

<!---
Each section should include a header with one of these titles: Added, Changed, Fixed, Removed. 
All items pertaining to that header will be listed out in a list using hyphens.

Added would be to define new features.
Changed would be to define features that have changed or be updated.
Fixed would be for any defects that were fixed.
Removed would be for any features that were removed.
--->

## [Unreleased][unreleased]

## [1.3.1] - 2015-07-31

### Fixed
- When switching lines, the App Menu was not correctly updating, causing the App Menu to incorrectly navigate.
- iPad UI issues.

## [1.3.0] - 2015-07-29

### Added
- Added User Voice to provide improved user feedback.
- Ability to add and edit a new local contact that gets saved to the Jive Platform and synced between devices. (US10218, US10225)
- Improved and updated localizations. (US10270)
- Volume Slider (US10048)
- Ringtone Selector (US15049)
- Ability to detect expired AuthToken and re-request token without forcing Logout. Prompts logged in user to enter password. (US10668)
- Reorganized Settings
- New App Drawer with new look and feel (iPhone).

### Changes
- DE994 Local EULA. Made the EULA to be embedded in the app to improve load time, and provide offline access to EULA.

### Fixed
- DE1095. Deleted calls are now being marked read, updating the badge count correctly.
- DE1094. Fixed issues around Default DID selection.
- DE999. Intercom Speaker Bug fixed. 
- Various small bugs.

## [1.2.5] - 2015-06-02

## [1.2.4] - 2015-04-27

## [1.2.3] - 2015-04-20

[unreleased]: https://github.com/jive/iOS-JiveOne/compare/v1.3.1(150731)...HEAD
[1.3.1]: https://github.com/jive/iOS-JiveOne/compare/v1.3.0(150729)...v1.3.1(150731)
[1.3.0]: https://github.com/jive/iOS-JiveOne/compare/v1.2.5(150602)...v1.3.0(150729)
[1.2.5]: https://github.com/jive/iOS-JiveOne/compare/v1.2.4(150427)...v1.2.5(150602)
[1.2.4]: https://github.com/jive/iOS-JiveOne/compare/v1.2.3(150420)...v1.2.4(150427)
[1.2.3]: https://github.com/jive/iOS-JiveOne/compare/v1.2.2(150323)...v1.2.4(150420)
