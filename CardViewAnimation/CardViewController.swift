//
//  CardViewController.swift
//  CardViewAnimation
//
//  Created by Brian Advent on 26.10.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit

class CardViewController: UIViewController, IsCardViewController {

    weak var contentHeightProviderDelegate: ContentHeightProviderDelegate?

    var contentHeight: Float {
        let viewHeight = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        return Float(ceil(viewHeight))
    }

    @IBOutlet weak var handleArea: UIView!

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentHeightProviderDelegate?.contentHeightProvider(self, didUpdateHeight: contentHeight)
    }
}
