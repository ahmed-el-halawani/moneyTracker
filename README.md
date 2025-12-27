# 💰 Money Tracker

A cross-platform Expense & Income tracking application built with **Flutter**.
Manage your personal finances efficiently on iOS, Android, and the Web.

[![Flutter](https://img.shields.io/badge/Built_with-Flutter-blue?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey)]()
[![Build Status](https://img.shields.io/github/actions/workflow/status/ahmed-el-halawani/moneyTracker/build-all.yml?label=Build)](https://github.com/ahmed-el-halawani/moneyTracker/actions)

---

## 🚀 Live Demo

Try the app directly in your browser without installing anything:

### [👉 Click here to open Web Preview](https://ahmed-el-halawani.github.io/moneyTracker/)

---

## 📱 Downloads

Automated builds are generated for every release. You can download the latest versions here:

| Platform | Download Link |
| :--- | :--- |
| **Android** | [Download .APK (Latest Release)](https://github.com/ahmed-el-halawani/moneyTracker/releases/latest) |
| **iOS** | [Download .IPA (Latest Release)](https://github.com/ahmed-el-halawani/moneyTracker/releases/latest) |

> **Note for iOS Users:** To install the `.ipa` file, you may need to use tools like AltStore or have a developer account to sign the app, as the automated build is unsigned by default.

---

## ✨ Features

* **Cross-Platform:** Single codebase running smoothly on iOS, Android, and Web.
* **Expense Tracking:** Easily add and categorize daily expenses.
* **Income Management:** Keep track of your income sources.
* **Responsive UI:** Optimized for both mobile touchscreens and desktop web browsers.
* **Automated CI/CD:**
    * **Web:** Auto-deploys to GitHub Pages on dispatch.
    * **Mobile:** Auto-builds APK and IPA files via GitHub Actions.

---

## 📸 Screenshots

| Mobile Home | Add Transaction | Web Dashboard |
|:---:|:---:|:---:|
| <img src="" alt="Mobile Home" width="200"/> | <img src="" alt="Add Transaction" width="200"/> | <img src="" alt="Web View" width="200"/> |

---

## 🛠️ Installation (For Developers)

If you want to build and run this project locally:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/ahmed-el-halawani/moneyTracker.git](https://github.com/ahmed-el-halawani/moneyTracker.git)
    cd moneyTracker/money_tracker
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    # Run on Android/iOS Emulator
    flutter run

    # Run on Web (Chrome)
    flutter run -d chrome
    ```

---

## ⚙️ GitHub Actions Workflows

This repository includes CI/CD pipelines to automate deployment:
* `Build All Platforms`: Builds Android APK and iOS IPA in parallel.
* `Deploy Flutter Web`: Builds the web version and deploys it to the `gh-pages` branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
