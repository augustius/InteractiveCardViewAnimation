//
//  ViewController.swift
//  CardViewAnimation
//
//  Created by Brian Advent on 26.10.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit


class ViewController: UIViewController, CanContainCardViewController, ContentHeightProviderDelegate {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var containerHeight: NSLayoutConstraint!
  @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!

  var cardViewController: IsCardViewController?
  var visualEffectView: UIVisualEffectView = UIVisualEffectView()
  var collapseHeight: CGFloat = 138
  var cardHeight: CGFloat = 0
  var cardCornerRadius: CGFloat = 14

  override func viewDidLoad() {
    super.viewDidLoad()
    let view = CardViewController(nibName:"CardViewController", bundle:nil)
    addCardViewController(view)
  }

  func addPanGesture() {
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
    cardViewController?.view.addGestureRecognizer(panGestureRecognizer)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
    cardViewController?.view.addGestureRecognizer(tapGesture)
  }

  @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
    handleCardPan(recognizer: recognizer)
  }

  @objc func handleTapGesture(recognizer: UITapGestureRecognizer) {
    print("tap gesture tapped")
  }

  func addCardViewController(_ view: IsCardViewController) {
    cardViewController = view
    cardViewController?.contentHeightProviderDelegate = self
    setupCard(containerView)
  }

  func cardViewBottomMoving(with constant: CGFloat) {
    containerBottomConstraint.constant += constant
  }

  func getCardViewBottom() -> CGFloat {
    return containerBottomConstraint.constant
  }

  func setCardViewBottom(with constant: CGFloat) {
    containerBottomConstraint.constant = -constant
  }

  func setCardHeight(with constant: CGFloat) {
    containerHeight.constant = constant
  }

  @IBAction func butonPressed(_ sender: Any) {
    print("pressed")
  }

  // MARK: - ContentHeightProviderCollapsibleDelegate

  func contentHeightProvider(_ provider: ContentHeightProvider, didUpdateHeight height: Float) {
    print(height)
    if cardHeight < CGFloat(height) {
      cardHeight = CGFloat(height)
      setCardHeight(with: cardHeight)
    }
  }
}


/// ENDDDDD

protocol ContentHeightProvider: class {
    var contentHeight: Float { get }
}

protocol ContentHeightProviderWithDelegate: ContentHeightProvider {
    var contentHeightProviderDelegate: ContentHeightProviderDelegate? { get set }
}

protocol ContentHeightProviderDelegate: class {
    func contentHeightProvider(_ provider: ContentHeightProvider, didUpdateHeight height: Float)
}

protocol IsCardViewController: UIViewController, ContentHeightProviderWithDelegate {

}

enum CardState {
    case expand
    case collapse
}

typealias CardStateAndDistance = (state: CardState, distance: CGFloat)

protocol CanContainCardViewController {

  // MARK: - injected
  var cardViewController: IsCardViewController? { get set }

  // MARK: - Input
  var visualEffectView: UIVisualEffectView { get set }
  var cardHeight: CGFloat { get set }
  var collapseHeight: CGFloat { get set }
  var cardCornerRadius: CGFloat { get set }

  func addPanGesture()
  func addCardViewController(_ view: IsCardViewController)
  func setCardViewBottom(with constant: CGFloat)
  func getCardViewBottom() -> CGFloat
  func cardViewBottomMoving(with constant: CGFloat)
  func setCardHeight(with constant: CGFloat)
}

extension CanContainCardViewController where Self: UIViewController {

  func setupCard(_ containerView: UIView) {
    /// add child view
    addChildView(containerView)
    addPanGesture()
  }

  func addChildView(_ containerView: UIView) {
    guard let cardViewController = cardViewController else { return }
    addChildViewController(cardViewController, andPinToEdgesOf: containerView)
    animateToPositionY(positionY: collapseHeight)

    /// add visual effect view for blur
    visualEffectView.alpha = 0
    visualEffectView.clipsToBounds = false
    visualEffectView.layer.masksToBounds = false
    visualEffectView.effect = UIBlurEffect(style: .dark)
    cardViewController.view.addSubview(visualEffectView)
    cardViewController.view.sendSubviewToBack(visualEffectView)
    visualEffectView.pinViewToEdgesOfSuperview()
  }

  func handleCardPan(recognizer: UIPanGestureRecognizer) {
    let velocity = recognizer.velocity(in: cardViewController!.view)
    print("checking currentCardState: ")
    guard let currentCardState = decideCurrentCardState(velocity.y) else { return }
    print(currentCardState)
    print("velocityY: \(velocity.y)")

    switch recognizer.state {
      case .changed:
        animateTransition(currentCardState: currentCardState, velocityY: velocity.y)
      case .ended:
        endTransition(currentsCardState: currentCardState)
      default: break
    }
  }

  func animateToPositionY(_ duration: Double = 0, positionY: CGFloat) {
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
      self.setCardViewBottom(with: positionY)
    }, completion: nil)
  }

  func increasePositionY(_ duration: Double = 0, positionY: CGFloat) {
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
      self.cardViewBottomMoving(with: positionY)
    }, completion: nil)
  }

  func animateBlurEffect(_ duration: Double, finalCardState: CardState) {
    let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) { [weak self] in
      guard let strongSelf = self else { return }
      switch finalCardState {
        case .expand:
          //          strongSelf.visualEffectView.frame = CGRect(x: 0, y: -1000, width: strongSelf.view.bounds.width, height: 2000) //strongSelf.view.frame
          strongSelf.visualEffectView.alpha = 0.7

        case .collapse:
          //          strongSelf.visualEffectView.frame = .zero
          strongSelf.visualEffectView.alpha = 0
      }
    }
    blurAnimator.startAnimation()
  }

  func decideCurrentCardState(_ velocityY: CGFloat) -> CardState? {
    if velocityY > 0 {
      return .collapse
    } else if velocityY < 0 {
      return .expand
    } else {
      return nil
    }
  }

  func animateTransition(currentCardState: CardState, velocityY: CGFloat) {
    /// reduced velocityY value to to be used as Y pointer
    let reducedVelocityY = velocityY / 100
    /// get final Y position to be moved to
    let finalPositionY: CGFloat = -reducedVelocityY
    let currentBottomConstant = getCardViewBottom()
    print("currentBottomConstant: \(currentBottomConstant)")
    print("position: \(finalPositionY)")
    switch currentCardState {
      case .expand:
        if currentBottomConstant < 0 {
          increasePositionY(positionY: finalPositionY)
      }
      case .collapse:
        if currentBottomConstant > -collapseHeight {
          increasePositionY(positionY: finalPositionY)
      }
    }
  }

  func decideFinalCardStateAndDistance(currentCardState: CardState) -> CardStateAndDistance {
    let currentBottomConstant = getCardViewBottom()
    var collapseDistance = collapseHeight - abs(currentBottomConstant)
    var expandDistance = abs(currentBottomConstant)
    /// reduced distance by 30% for currentCardState
    let reducedDistance: CGFloat = 0.3
    switch currentCardState {
      case .collapse:
        collapseDistance *= reducedDistance
      case .expand:
        expandDistance *= reducedDistance
    }
    /// re-decide currentCardState based on the closest to
    let state: CardState = collapseDistance > expandDistance ? .expand : .collapse
    let distance = min(expandDistance, collapseDistance)
    return (state, distance)
  }

  func endTransition(currentsCardState: CardState) {
    let finalCardStateAndDistance = decideFinalCardStateAndDistance(currentCardState: currentsCardState)
    print("final Decision")
    print(finalCardStateAndDistance)
    let finalCardState = finalCardStateAndDistance.state
    let minDistance = finalCardStateAndDistance.distance
    /// calculate animate duration based on distance
    let duration: Double = Double(minDistance / 300)
    /// animate to final Y position
    let finalPositionY = finalCardState == .expand ? 0 : collapseHeight
    setCardHeight(with: finalCardState == .expand ? self.view.bounds.height + 200 : cardHeight)
    animateToPositionY(duration, positionY: finalPositionY)
    /// animate blur background
    animateBlurEffect(duration, finalCardState: finalCardState)
  }
}












extension UIView {
    func pinViewToEdgesOfSuperview(leftOffset: CGFloat = 0, rightOffset: CGFloat = 0, topOffset: CGFloat = 0, bottomOffset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        superview!.addConstraints([
            superview!.leftAnchor.constraint(equalTo: leftAnchor, constant: leftOffset),
            superview!.rightAnchor.constraint(equalTo: rightAnchor, constant: rightOffset),
            superview!.topAnchor.constraint(equalTo: topAnchor, constant: topOffset),
            superview!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomOffset)
        ])
    }
}


extension UIViewController {
    func addChildViewController(_ viewController: UIViewController, andPinToEdgesOf view: UIView) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.pinViewToEdgesOfSuperview()
        viewController.didMove(toParent: self)
    }

    func removeChildFromParent() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    var isRootViewController: Bool {
        return navigationController?.viewControllers.first == self
    }
}
