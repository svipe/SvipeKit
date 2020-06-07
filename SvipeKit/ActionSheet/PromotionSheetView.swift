// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

//
// MARK: - PromotionSheetViewConfiguration Configuration
//

class PromotionSheetViewConfiguration {
    
    let presentAnimationDuration = 0.3
    let dismissAnimationDuration = 0.2
    
    let presentAnimationDurationSlow = 0.5
    let dismissAnimationDurationSlow = 0.4
    
    var currentPresentAnimationDuration: TimeInterval {
        get {
            let cores = ProcessInfo.processInfo.processorCount
            return cores >= 4 ? presentAnimationDuration : presentAnimationDurationSlow
        }
    }
    
    var currentDismissAnimationDuration: TimeInterval {
        get {
            let cores = ProcessInfo.processInfo.processorCount
            return cores >= 4 ? dismissAnimationDuration : dismissAnimationDurationSlow
        }
    }
    
    let actionSheetViewFadeViewAlpha: CGFloat = 0.6
    
    let actionSheetViewBottomConstraintConstant: CGFloat = 5.0
    let keyImageViewTopConstraintDisconnectedConstant: CGFloat = 8
    let keyImageViewTopConstraintConnectedConstant: CGFloat = -19
    
    let deviceImageViewHeightConstraintMaxConstant: CGFloat = 346
    let deviceImageViewHeightConstraintMinConstant: CGFloat = 120

}

//
// MARK: - ActionSheetView
//

protocol PromotionSheetViewDelegate: NSObjectProtocol {
    func promotionSheetDidSignup(_ promotionSheet: PromotionSheetView)
    func promotionSheetDidDismiss(_ promotionSheet: PromotionSheetView)
    func promotionSheetError(_ promotionSheet: PromotionSheetView)
}

class PromotionSheetView: UIView {
    
    private let bundle = Bundle(for: PromotionSheetView.self)

    weak var delegate: PromotionSheetViewDelegate?

    private let configuration = ActionSheetViewConfiguration()
    private static let viewNibName = String(describing: PromotionSheetView.self)
    
    private var isPresenting = false
    private var isDismissing = false
    
    // MARK: - Outlets
    
    @IBOutlet var actionSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionSheetView: UIView!
    
    @IBOutlet var keyActionContainerView: UIView!
    @IBOutlet var backgroundFadeView: UIView!
    
    @IBOutlet weak var promotionImageView: UIImageView!
    
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    // MARK: - Lifecycle
    
    class func loadViewFromNib() -> PromotionSheetView? {
        let bundle = Bundle(for: PromotionSheetView.self)
        guard let nibs = bundle.loadNibNamed(viewNibName, owner: nil, options: nil) else {
            return nil
        }
        guard let view = nibs.first as? PromotionSheetView else {
            return nil
        }
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
  
    // MARK: - Animation States
    
    func animatePromotion1() {
        messageLabel.text = "Get a digital identity"
    }
    
    func animatePromotion2() {
        promotionImageView.image = UIImage(named: "promotion2", in: bundle, compatibleWith: nil)
        messageLabel.text = "Securely control your credentials"
    }

    func animatePromotion3() {
        cancelButton.titleLabel?.text = "Done"
        promotionImageView.image = UIImage(named: "promotion3", in: bundle, compatibleWith: nil)
        messageLabel.text = "Sign in to other apps and sites"
    }

    // MARK: - Presentation
    
    func present(animated: Bool, completion: @escaping ()->Void) {
        guard !isPresenting else {
            return
        }
        isPresenting = true
        
        actionSheetBottomConstraint.constant = -(actionSheetBottomConstraint.constant + actionSheetView.frame.size.height)
        backgroundFadeView.alpha = 0
        
        layoutIfNeeded()
        
        actionSheetBottomConstraint.constant = configuration.actionSheetViewBottomConstraintConstant

        let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseOut]
        
        UIView.animate(withDuration: configuration.currentPresentAnimationDuration, delay: 0, options:options, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.layoutIfNeeded()
            self.backgroundFadeView.alpha = self.configuration.actionSheetViewFadeViewAlpha
        }) { [weak self](_) in
            completion()
            self?.isPresenting = false
        }
    }
    
    func dismiss(animated: Bool, delayed: Bool = true, completion: @escaping ()->Void) {
        guard !isDismissing else {
            return
        }
        isDismissing = true
        
        actionSheetBottomConstraint.constant = configuration.actionSheetViewBottomConstraintConstant
        layoutIfNeeded()
        
        actionSheetBottomConstraint.constant = -(actionSheetBottomConstraint.constant + actionSheetView.frame.size.height)
        
        // Small delay to avoid UI flickering when the state is changing very fast.
        let delay = delayed ? 1.0 : 0
        let options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseIn]
        
        UIView.animate(withDuration: configuration.currentDismissAnimationDuration, delay: delay, options:options, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.layoutIfNeeded()
            self.backgroundFadeView.alpha = 0
        }) { [weak self](_) in
            completion()
            self?.isDismissing = false
        }
    }
    
    // MARK: - Layout updates
    
    func updateInterfaceOrientation(orientation: UIInterfaceOrientation) {
        var rotationAngle: CGFloat = 0
        switch orientation {
        case .unknown:
            fallthrough
        case .portrait:
            break
        case .landscapeLeft:
            rotationAngle = CGFloat(Double.pi / 2)
        case .landscapeRight:
            rotationAngle = CGFloat(-Double.pi / 2)
        case .portraitUpsideDown:
            rotationAngle = CGFloat(Double.pi)
        @unknown default:
            fatalError()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        delegate.promotionSheetDidSignup(self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        delegate.promotionSheetDidDismiss(self)
    }
}

extension NamedColor /* MFI Key Action Sheet */ {
    
    /// The border color of the action sheet action view when no operation is done.
    static var actionSheetIdleColor = UIColor.white
    
    /// The border color of the action sheet action view when a touch is required for a operation to continue.
    static var actionSheetTouchColor = UIColorFrom(hex: 0xBAE950)
    
    /// The border color of the action sheet action view when the action sheet is set on a processing state.
    static var actionSheetProcessingColor = UIColorFrom(hex: 0x76D6FF)
    
    /// The border color of the action sheet action view when the action sheet is set on a processing state.
    static var actionSheetErrorColor = UIColor.systemRed

}
