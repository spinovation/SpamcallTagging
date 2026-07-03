# Deep SCI — Crowdsourced Spam-Call Tagging iOS App

A native iOS application designed to aggregate real-time, distributed human judgment about call intent, escalating numbers to a system-wide blocklist before spammers rotate to their next batch of victims. 

This project implements **Phase 1 (App-Level)** of the crowdsourced tagging architecture, including a native SwiftUI application and an integrated **Call Directory Extension** for CallKit-level identification and blocking.

---

## Key Features

1. **One-Tap Tagging Simulator:** A high-fidelity simulated call log inside the app allowing users to instantly flag calls into four taxonomy categories (Scam/Fraud, Robocall, Telemarketing, or Not Spam/Clean).
2. **System-Level Blocking (CallKit):** An integrated App Extension (`CXCallDirectoryProvider`) that registers blocked numbers (Tier 2/3) and warning labels (Tier 1) directly with the iOS phone system.
3. **Browsable Spam Directory:** Full search and filtering of flagged numbers by carrier, category, threat level, and sorting by tag volume or recency.
4. **Campaign Burst & Geo-Region Analysis:** Visualization of peak call traffic patterns and coarse geographic area code locations for flagged numbers.
5. **Sybil-Resistance & Privacy:** 
   - Generates a local, non-reversible, pseudonymous User ID stored in the **iOS Keychain** to prevent account-flooding abuse.
   - Calculates a **Tagger Reputation Score** for each user, weighting tags based on participation and historical accuracy (penalizing false-flags).
6. **Configurable Escalation Threshold:** A settings slider allowing users to customize how many unique reports are needed to block or silence numbers.

---

## Directory Structure

* **`project.yml`**: Configures XcodeGen to generate the `.xcodeproj` file.
* **`setup.sh`**: Project bootstrap shell script to install dependencies and run project generation.
* **`README.md`**: Guide for development settings, code-signing configuration, and manual testing cycles.
* **`DeepSCI/`**: Main SwiftUI application codebase.
  * **`DeepSCIApp.swift`**: App entry point.
  * **`Models/`**: `SpamNumber` and `SpamTag` data representations.
  * **`Services/`**: Data layer, local JSON storage syncing, Keychain access, and CallKit control.
  * **`Views/`**: SwiftUI layouts (Dashboard, Directory, Simulator, Detail page, and Settings).
* **`DeepSCIDirectory/`**: Call Directory Extension target.
  * **`CallDirectoryHandler.swift`**: Subclasses `CXCallDirectoryProvider` to feed phone numbers and labels into CallKit.

---

## System Architecture

```
                 +---------------------------------------------------+
                 |                  Main SwiftUI App                 |
                 +--------+-------------------+-----------------+----+
                          |                   |                 |
                          v                   v                 v
           +--------------+---------+   +-----+-----+   +-------+-------+
           |     Sync/Mock Service   |   | Keychain  |   | Spam Manager  |
           +--------------+---------+   +-----------+   +-------+-------+
                          |                                     | (Reload)
                          v                                     v
                 +--------+------------------+          +-------+-------+
                 | Shared App Group Folder  |          | iOS CallKit   |
                 | - spam_numbers.json      |          | System        |
                 | - user_tags.json         |          +-------+-------+
                 +--------+-----------------+                  ^
                          ^                                    | (Load)
                          |                                    |
                 +--------+------------------------------------+----+
                 |             Call Directory Extension              |
                 +---------------------------------------------------+
```

---

## Setup & Installation Instructions

Since this workspace is configured for command-line editing, we use **XcodeGen** to build the Xcode project files dynamically.

### Step 1: Bootstrap the Project
Open terminal and run the bootstrap script from the project root:
```bash
./setup.sh
```
This script will:
1. Verify if `xcodegen` is installed, and if not, install it using Homebrew.
2. Build the directory layout assets.
3. Automatically generate the `DeepSCI.xcodeproj` project package.

### Step 2: Open in Xcode
Open the generated project in Xcode:
```bash
open DeepSCI.xcodeproj
```

---

## How to Test and Verify

### 1. Configure Signing & App Groups (Physical Device / Provisioning)
To share data between the Main App and the Call Directory Extension, iOS requires an **App Group**.
1. In Xcode, click the **DeepSCI** project root.
2. Select the **DeepSCI** app target -> **Signing & Capabilities**.
3. Set your Developer **Team** ID.
4. Click `+ Capability` and add **App Groups**. Check/create group `group.com.deepsci.app`.
5. Select the **DeepSCIDirectory** extension target -> **Signing & Capabilities**.
6. Set the same Developer **Team** ID.
7. Add **App Groups** and check the exact same group `group.com.deepsci.app`.

*Note: If you do not have an Apple Developer account, the app is architected with a sandbox-fallback to write to local documents, allowing you to test the SwiftUI views and directory simulator, but iOS will restrict the extension from running.*

### 2. Enable the App Extension on your iPhone
Once compiled and loaded on a device:
1. Go to the iPhone **Settings** app.
2. Select **Phone** -> **Call Blocking & Identification**.
3. Under *Call Directory Apps*, enable **Deep SCI**.

### 3. Verification Walkthrough
1. **Sync Seed Data:** Open the app. The dashboard will automatically sync the initial mock database.
2. **Browse Directory:** Tap the **Directory** tab to view flagged numbers. Search "+1800" or select "Scam/Fraud" filters to test responsiveness.
3. **Simulate a Spam Tag:** 
   - Tap the **Simulator** tab to view a mock incoming Call Log.
   - Find the call from `+1 206 555-0121` (Amazon Order Security) and tap **Tag Call**.
   - Select **Scam / Fraud**.
   - The confirmation will slide in. The number has now been tagged.
4. **Inspect Changes:**
   - Tap the **Directory** tab. Note that `+1 206 555-0121` has moved from 9 to 10 tags.
   - Because the threshold is set to 10, this number automatically escalates to **Tier 2: Silenced** and is transferred to the blocklist.
   - Tap the number to view its category charts and call burst windows.
5. **Simulate Business Appeals:**
   - From the detail view of `+1 206 555-0121`, scroll to the bottom and tap **Submit Unblock/Dispute Request**.
   - Tap **Submit Attestation**. This simulates a business filing a wrong-flag appeal (FR-11).
   - The number will reset back to 0 flags, removing it from the blocklist and reloading CallKit.
