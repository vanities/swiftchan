<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL3 License][license-shield]][license-url]
[![Build and Release to Testflight](https://github.com/vanities/swiftchan/actions/workflows/fastlane_beta.yml/badge.svg)](https://github.com/vanities/swiftchan/actions/workflows/fastlane_beta.yml)
[![GitHub tag](https://img.shields.io/github/release/vanities/swiftchan.svg)](https://github.com/vanities/swiftchan/releases)


<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/vanities/swiftchan">
    <img src="assets/icon.png" alt="Logo" width="300" height="300">
  </a>

  <h3 align="center">swiftchan</h3>

  <p align="center">
    open source imageboard ios app written in swiftUI.
    <br />
  </p>
</p>

<center>
  <a href="https://discord.gg/jcUfgedZwc" target="_blank"><img src="https://i.imgur.com/dUwek7T.jpg" alt="Discord Server" width="200" height="100"></a>
</center>

<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
  * [TestFlight](#testflight)
  * [Known Bugs](#bugs)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)



<!-- ABOUT THE PROJECT -->
## About The Project

<img src="assets/screenshot.png" alt="screenshot" width="300"><img src="assets/board_screenshot.png" alt="board_screenshot" width="300"><img src="assets/thread_screenshot.png" alt="thread_screenshot" width="300"><img src="assets/webm.gif" alt="webm" width="300">


Written completely in SwiftUI using mostly MVVM. Heavily inspired by TheChan. Plays webms and gifs natively in app by using MobileVLCKit.


Has many settings to change including:
* replace thumbnails with high-res assets
* auto-update thread timer
* hiding threads/posts
* biometrics unlock

Here's why:
* you don't want to download a shady app from 3rd party appstores and you're not jailbroken
* native webm support
* fast like swift


### Built With
Dev requirements used in the app with CocoaPods and Swift Package Manager.

* [FourChanApi](https://github.com/jackpal/FourChanAPI)
* [SwiftUIPager](https://github.com/fermoya/SwiftUIPager)
* [URLImage](https://github.com/dmytro-anokhin/url-image)
* [MobileVLCKit](https://code.videolan.org/videolan/VLCKit)




<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

Download [xCode](https://apps.apple.com/us/app/xcode/id497799835?mt=12)

Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

### Installation

1. Clone the repo
```sh
git clone https://github.com/vanities/swiftchan
```
2. Install pod pakages
```sh
pod install
```
3. That's it! Open the workspacefile in Xcode.


### Testflight

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/vanities)

I have to pay the $100/year apple dev fee for this, so please help out. :)

If you want to test it with me on testflight or think we can get it on the app store, user [this link](https://testflight.apple.com/join/yDU6gMUi) or [email me](mailto:mischke@protonmail.com) if you have any issues.


<!-- USAGE EXAMPLES -->
## Usage

Open the `swiftchan.xcworkspace` file with Xcode.



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/vanities/swiftchan/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the GPL3 License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Maintainer - [@vanities](https://twitter.com/vanities)

Project Link: [https://github.com/vanities/swiftchan](https://github.com/vanities/swiftchan)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [SwiftUI VideoPlayer](https://github.com/wxxsw/VideoPlayer)
* [SwiftUI AVPlayer](https://github.com/ChrisMash/AVPlayer-SwiftUI/blob/master/AVPlayer-SwiftUI/VideoView.swift)
* [Swift 4chan app](https://github.com/jackpal/KleeneStar)






<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/vanities/swiftchan.svg?style=flat-square
[contributors-url]: https://github.com/vanities/swiftchan/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/vanities/swiftchan.svg?style=flat-square
[forks-url]: https://github.com/vanities/swiftchan/network/members
[stars-shield]: https://img.shields.io/github/stars/vanities/swiftchan.svg?style=flat-square
[stars-url]: https://github.com/vanities/swiftchan/stargazers
[issues-shield]: https://img.shields.io/github/issues/vanities/swiftchan.svg?style=flat-square
[issues-url]: https://github.com/vanities/swiftchan/issues
[license-shield]: https://img.shields.io/github/license/vanities/swiftchan.svg?style=flat-square
[license-url]: https://github.com/vanities/swiftchanblob/master/LICENSE.txt
