//
//  swiftchanTests.swift
//  swiftchanTests
//
//  Created by vanities on 10/30/20.
//

import XCTest
import FourChan
@testable import swiftchan

class SwiftchanTests: XCTestCase {
    let postParser = PostTextParser()
    let parser = CommentParser(comment: "https://www.youtube.com/watch?v=kg4<wbr>YFS6b0ek")

    func testHyperLinkFinder() throws {
        let result = parser.checkForUrls("""
                            Blender 3D:

                            http://www.blender.org/

                            Wings3D:

                            http://www.wings3d.com/

                            Softimage Mod Tool:

                            http://usa.autodesk.com/adsk/servle​t/pc/item?id=13571257&siteID=123112

                            Houdini Apprentice:

                            http://www.sidefx.com/index.php?opt​ion=com_download&Itemid=208&task=ap​prentice
""")
        print(result)
        XCTAssertEqual(result[0].0, URL(string: "http://www.blender.org/")!)
        XCTAssertEqual(result[1].0, URL(string: "http://www.wings3d.com/")!)
        XCTAssertEqual(result[2].0, URL(string: "http://usa.autodesk.com/adsk/servlet/pc/item?id=13571257&siteID=123112")!)
        XCTAssertEqual(result[3].0, URL(string: "http://www.sidefx.com/index.php?option=com_download&Itemid=208&task=apprentice")!)
    }

    func testHyperLinkFinderQueryParam() throws {
        let urlString = "https://store.steampowered.com/app/​773840/DRAG/"
        //let percentUrlString = "https://store.steampowered.com/app/​773840/DRAG/".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let result = parser.checkForUrls(urlString)
        XCTAssertEqual(result[0].0, URL(string: "https://store.steampowered.com/app/773840/DRAG/"))
    }
}
