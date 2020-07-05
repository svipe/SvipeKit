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
import FaceVerifier
import Vision

//
// MARK: - ActionSheetViewConfiguration Configuration
//


//
// MARK: - ActionSheetView
//

protocol EngagementSheetViewDelegate: NSObjectProtocol {
    func engagmentSheetDidDismiss(_ actionSheet: EngagementSheetView)
    func engagementSheetError(_ actionSheet: EngagementSheetView)
}

class EngagementSheetView: UIView {
    
    private let bundle = Bundle(for: EngagementSheetView.self)
    
    weak var delegate: EngagementSheetViewDelegate?

    private let configuration = ActionSheetViewConfiguration()
    private static let viewNibName = String(describing: EngagementSheetView.self)
    
    private var isPresenting = false
    private var isDismissing = false
    
    // MARK: - Outlets
    
    @IBOutlet var actionSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionSheetView: UIView!
    
    @IBOutlet var keyImageView: UIImageView!
    @IBOutlet var keyImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var deviceImageView: UIImageView!
    @IBOutlet weak var deviceImageViewHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var passportImageView: UIImageView!
    
    @IBOutlet var keyActionContainerView: UIView!
    @IBOutlet var backgroundFadeView: UIView!
    @IBOutlet var borderView: UIView!
    
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    @IBAction func svipeVerification(_ sender: Any) {
        let urlString = "https://svipe.com"
        if let url = URL(string: urlString ) {
           UIApplication.shared.open(url, options: [:]) { (success) in
           }
        }
    }
    
    @IBAction func didTapBackground(_ sender: Any) {
        print("tap")
        resetState()
        delegate?.engagmentSheetDidDismiss(self)
    }
    
    // MARK: - Lifecycle
    
    class func loadViewFromNib() -> EngagementSheetView? {
        let bundle = Bundle(for: EngagementSheetView.self)
        guard let nibs = bundle.loadNibNamed(viewNibName, owner: nil, options: nil) else {
            return nil
        }
        guard let view = nibs.first as? EngagementSheetView else {
            return nil
        }
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupKeyPhoneView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupKeyPhoneView()
    }
    
    private func setupKeyPhoneView() {
        cancelButton.isHidden = false

        if UIDevice.current.ykd_hasHomeButton() {
            deviceImageView.image = UIImage(named: "LASPhone", in: bundle, compatibleWith: nil)
        } else {
            deviceImageView.image = UIImage(named: "LASPhoneNew", in: bundle, compatibleWith: nil)
        }
        
        keyImageView.image = UIImage(named: "LASKey", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = false
        keyImageView.isHidden = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = true
        
        resetState()
    }
    
    private func setupMRZInfoView() {
        cancelButton.isHidden = false
        keyImageView.image = UIImage(named: "LASMRZ", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = true
        resetState()
    }
    
    private func setupPhonePassportView() {
        cancelButton.isHidden = false
        deviceImageView.image = UIImage(named: "LASPassport", in: bundle, compatibleWith: nil)

        if UIDevice.current.ykd_hasHomeButton() {
            keyImageView.image = UIImage(named: "LASPhone", in: bundle, compatibleWith: nil)
        } else {
            keyImageView.image = UIImage(named: "LASPhoneNew", in: bundle, compatibleWith: nil)
        }
        
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = false
        resetState()
    }
    
    
    private func setupProcessing() {
        cancelButton.isHidden = false
        keyImageView.image = UIImage(named: "LASCogs", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = false
        resetState()
    }
    
    private func setupSuccess() {
        if Bundle.appId == "com.svipe.id" {
            cancelButton.titleLabel?.text = "Done"
        } else {
            cancelButton.isHidden = true
        }
        keyImageView.image = UIImage(named: "LASSuccess", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = false
        resetState()
    }
    
    private func setupErrorView() {
        cancelButton.isHidden = false
        /*deviceImageView.image = UIImage(named: "LASPassport")
        if UIDevice.current.ykd_hasHomeButton() {
            keyImageView.image = UIImage(named: "LASPhone")
        } else {
            keyImageView.image = UIImage(named: "LASPhoneNew")
        }*/
        
        deviceImageView.isHidden = true
        keyImageView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = true
        resetState()
    }
    
    // MARK: - Animation States
    
    private func resetState() {
        
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = nil
        
        layer.removeAllAnimations()
        keyImageView.layer.removeAllAnimations()
    }
    
    func animateMRZ(message: String) {
        setupMRZInfoView()
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = message
        animateConnectKey()
    }
    
    func animateProcessing(message: String) {
        
        setupProcessing()
        borderView.backgroundColor = NamedColor.actionSheetProcessingColor
        messageLabel.text = message
        
        //animateKeyConnected()
        pulsateBorderView(duration: 1.5)
    }
    
    func animateSuccess(message: String) {
        
        setupSuccess()
        borderView.backgroundColor = NamedColor.actionSheetProcessingColor
        messageLabel.text = message
        
        //animateKeyConnected()
        pulsateBorderView(duration: 1.5)
    }
    
    func animateError(message: String) {
        
        setupErrorView()

        borderView.backgroundColor = NamedColor.actionSheetErrorColor
        messageLabel.text = message
        
        //animateKeyConnected()
        pulsateBorderView(duration: 1.5)
    }

    
    
    func animateTouchKey(message: String) {
        setupKeyPhoneView()
        borderView.backgroundColor = NamedColor.actionSheetTouchColor
        messageLabel.text = message
        
        animateKeyConnected()
        pulsateBorderView(duration: 1)
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
    
    // MARK: - Animation Helpers
    
    private func animateTouchPassport() {
        layoutIfNeeded()
        
        return
        
        UIView.animateKeyframes(withDuration: 3, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                
                self.deviceImageViewHeightConstraint.constant = self.configuration.deviceImageViewHeightConstraintMaxConstant
                self.layoutIfNeeded()
            })
            
    
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2, animations: {
                self.deviceImageViewHeightConstraint.constant = self.configuration.deviceImageViewHeightConstraintMinConstant
                self.layoutIfNeeded()
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                // Pause
            })
            
        }, completion: nil)
        
        /*
        UIView.animateKeyframes(withDuration: 3, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintConnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                // Pause
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintDisconnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                // Pause
            })
        }, completion: nil)
 */
    }
    
    private func animateConnectKey() {
        layoutIfNeeded()
        
        UIView.animateKeyframes(withDuration: 3, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintConnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                // Pause
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintDisconnectedConstant
                self.layoutIfNeeded()
            })
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                // Pause
            })
        }, completion: nil)
    }
    
    private func animateKeyConnected() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                self.keyImageViewTopConstraint.constant = self.configuration.keyImageViewTopConstraintConnectedConstant
                self.layoutIfNeeded()
            })
        }, completion: nil)
    }
    
    private func pulsateBorderView(duration: TimeInterval) {
        borderView.alpha = 0
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .repeat, animations: { [weak self] in
            guard let self = self else {
                return
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1, animations: {
                self.borderView.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.8, animations: {
                // Pause
            })
            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1, animations: {
                self.borderView.alpha = 0
            })
        }, completion: nil)
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
        keyActionContainerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.engagmentSheetDidDismiss(self)
    }
}

