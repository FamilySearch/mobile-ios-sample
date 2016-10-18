# mobile-iOS-sample
Sample mobile native iOS app.

### Tools required
In order to use this demo application you must first have installed:
* XCode 7.3, or newer. This is now downloaded from the Mac App Store
* iOS SDK version 9 (Can be installed from within XCode)
* An API key [issued by Family Search](https://familysearch.org/developers/). Place ths key inside of `AppKeys.swift`

### Create AppKeys.swift file
In the root of the `FamilySearchIosSampleApp` folder, add a new swift file and name if `AppKeys.swift`.
In here, add a static String variable named `API_KEY` and add your api key from Family search.

Example:
```swift
import Foundation

class AppKeys : NSObject
{
    static let API_KEY = "your_api_key"
}
```
### Production and Testing Environments
To change what tree reference (integration, beta, production) you are using edit the starting URL in `/FamilySearchIosSampleApp/Utilities.swift`
