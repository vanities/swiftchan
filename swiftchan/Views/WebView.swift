//
//  WebView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

  var text: String
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: nil)
  }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(text: "<b>FAQs about origami</b><br>\n<br>\n<i>Where do I begin with origami and how can I find easy models?</i><br>\n<br>\nTry browsing the board for guides, or other online resources listed below, for models you like and practice folding them.<br>\n<br>\nA great way to begin at origami is to participate in the Let’s Fold Together threads <a href=\"https://boards.4channel.org/po/catalog#s=lft\"><a href=\"//boards.4channel.org/po/catalog#s=lft\" class=\"quotelink\">&gt;&gt;&gt;/po/lft</a></a> - open up the PDF file and find a model you like, work on it, and discuss or post results.<br>\n<br>\n<a href=\"http://en.origami-club.com\">http://en.origami-club.com</a><br>\n<a href=\"https://origami.me/diagrams/\">https://origami.me/diagrams/</a><br>\n<a href=\"https://www.origami-resource-center.com/free-origami-instructions.html\">https://www.origami-resource-center<wbr>.com/free-origami-instructions.html<wbr></a><br>\n<a href=\"http://www.paperfolding.com/diagrams/\">http://www.paperfolding.com/diagram<wbr>s/</a><br>\n<br>\n<i>What paper should I use?</i><br>\n<br>\nIt depends on the model; for smaller models which involved 25 steps or fewer, 15 by 15 cm origami paper from a local craft store will be suitable. For larger models you will need larger or thinner paper, possibly from online shops. Boxpleated models require thin paper, such as sketching paper. Wet folded models require thicker paper, such as elephant hide.<br>\n<br>\n<a href=\"https://www.origami-shop.com/en/\">https://www.origami-shop.com/en/</a><br>\n<br>\n<i>Hints and tips?</i><br>\n<br>\nFor folding, The best advice is to always fold as cleanly as possible, and take your time. Everything else comes with experience.<br>\n<br>\n<a href=\"https://origami.me/beginners-guide/\">https://origami.me/beginners-guide/<wbr></a><br>\n<a href=\"https://origamiusa.org/glossary\">https://origamiusa.org/glossary</a><br>\n<br>\n<i>What are ‘CPs’?</i><br>\n<br>\nCrease patterns are a structural representations of origami models, shown as a schematic of lines; they are essentially origami models unfolded and laid flat. Lines on a crease pattern may be indicated by ‘mountain’ or ‘valley’ folds to show how the folds alternate. If you’re particularly skilled at origami, they become useful instructions for building models. A common base fold is usually discernable, all the intermediate details can be worked on from there.<br>\n<br>\n<a href=\"https://blog.giladnaor.com/2008/08/folding-from-crease-patterns.html\">https://blog.giladnaor.com/2008/08/<wbr>folding-from-crease-patterns.html</a><br>\n<a href=\"http://www.origamiaustria.at/articles.php?lang=2#a4\">http://www.origamiaustria.at/articl<wbr>es.php?lang=2#a4</a><br>")
    }
}
