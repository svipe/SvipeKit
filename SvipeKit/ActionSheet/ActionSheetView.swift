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
import SvipeCommon
import SvipeMRZ

//
// MARK: - ActionSheetViewConfiguration Configuration
//

class ActionSheetViewConfiguration {
    
    let presentAnimationDuration = 0.3
    let dismissAnimationDuration = 0.2
    
    let presentAnimationDurationSlow = 0.5
    let dismissAnimationDurationSlow = 0.4
    let bundle = Bundle(for: ActionSheetView.self)
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

protocol ActionSheetViewDelegate: NSObjectProtocol {
    func actionSheetDidClick(_ actionSheet: ActionSheetView)
    func actionSheetDidCancel(_ actionSheet: ActionSheetView)
    func actionSheetError(_ actionSheet: ActionSheetView)
}

class ActionSheetView: UIView {
    
    private let bundle = Bundle(for: ActionSheetView.self)
    
    weak var delegate: ActionSheetViewDelegate?

    private let configuration = ActionSheetViewConfiguration()
    private static let viewNibName = String(describing: ActionSheetView.self)
    
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
    
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var faceContainerView: UIView!
    @IBOutlet weak var faceView: FaceView!
    @IBOutlet weak var mrzView: QKMRZScannerView!
    @IBOutlet var keyActionContainerView: UIView!
    @IBOutlet var backgroundFadeView: UIView!
    @IBOutlet var borderView: UIView!
    
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    @IBOutlet weak var pinView: SPPinView!
    
    @IBAction func didTapBackground(_ sender: Any) {
        print("didTapBackground")
        resetState()
        delegate?.actionSheetDidCancel(self)
    }
    
    @IBAction func pinCodeEntered(_ sender: SPPinView) {
        sender.resignFirstResponder()
        pinEntryDelegate?.didEnter(pinCode: sender.pinString)
    }
    
    public var pinEntryDelegate: PinEntryDelegate?
    
    @IBAction func svipeVerification(_ sender: Any) {
        
        let urlString = "https://svipe.com"
        if let url = URL(string: urlString ) {
           UIApplication.shared.open(url, options: [:]) { (success) in
               
           }
        }
    }
    
    // MARK: - Lifecycle
    
    class func loadViewFromNib() -> ActionSheetView? {
        let bundle = Bundle(for: ActionSheetView.self)
        guard let nibs = bundle.loadNibNamed(viewNibName, owner: nil, options: nil) else {
            return nil
        }
        guard let view = nibs.first as? ActionSheetView else {
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
        faceImageView.isHidden = true
        deviceImageView.isHidden = false
        keyImageView.isHidden = false
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        passportImageView.isHidden = true
        pinView.isHidden = true

        resetState()
    }
    
    private func setupMRZInfoView() {
        cancelButton.setTitle("Continue", for: .normal)
        cancelButton.backgroundColor = .systemOrange
        cancelButton.isHidden = false
        keyImageView.image = UIImage(named: "LASMRZ", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        faceImageView.isHidden = true
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
        passportImageView.isHidden = true
        resetState()
    }
    
    private func setupFaceInfoView(image: UIImage? = nil ) {
        
        cancelButton.setTitle("Continue", for: .normal)
        cancelButton.backgroundColor = .systemOrange
        cancelButton.isHidden = false

        deviceImageView.isHidden = true
        keyImageView.isHidden = true
        
        if let image = image {
            faceImageView.image = image
        }
        
        faceImageView.isHidden = false
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        faceView.didMatch = false
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
        passportImageView.isHidden = true
        resetState()
    }
    
    
    private func setupPhonePassportView() {
        
        cancelButton.setTitle("Continue", for: .normal)
        cancelButton.backgroundColor = .systemOrange

        cancelButton.isHidden = false
        deviceImageView.image = UIImage(named: "LASPassport", in: bundle, compatibleWith: nil)

        if UIDevice.current.ykd_hasHomeButton() {
            keyImageView.image = UIImage(named: "LASPhone", in: bundle, compatibleWith: nil)
        } else {
            keyImageView.image = UIImage(named: "LASPhoneNew", in: bundle, compatibleWith: nil)
        }
        
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        faceImageView.isHidden = true
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
        passportImageView.isHidden = false
        resetState()
    }
    
    
    private func setupProcessing() {
        cancelButton.isHidden = false
        keyImageView.image = UIImage(named: "LASCogs", in: bundle, compatibleWith: nil)
        deviceImageView.isHidden = true
        keyImageView.isHidden = false
        faceImageView.isHidden = true
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
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
        faceImageView.isHidden = true
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
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
        faceImageView.isHidden = true
        mrzView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        keyActionContainerView.isHidden = false
        borderView.isHidden = false
        pinView.isHidden = true
        passportImageView.isHidden = true
        resetState()
    }
    
    private func setupMrzPreview() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .secondarySystemBackground
        cancelButton.isHidden = false
        deviceImageView.isHidden = true
        keyImageView.isHidden = true
        keyActionContainerView.isHidden = true
        borderView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        mrzView.isHidden = false
        pinView.isHidden = true
        passportImageView.isHidden = true
        resetState()
    }
    
    private func setupPinEntry(pinCount: Int) {
        pinView.pinCount = pinCount
        pinView.shouldSecureText = false
        cancelButton.setTitle("Skip", for: .normal)
        cancelButton.backgroundColor = .secondarySystemBackground
        cancelButton.isHidden = false
        deviceImageView.isHidden = true
        keyImageView.isHidden = true
        keyActionContainerView.isHidden = true
        borderView.isHidden = true
        faceView.isHidden = true
        faceContainerView.isHidden = true
        mrzView.isHidden = true
        pinView.isHidden = true
        pinView.isHidden = false
        passportImageView.isHidden = true
        resetState()
    }
    
    private func setupFacePreview(image: UIImage? = nil) {
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .secondarySystemBackground
        cancelButton.isHidden = false
        deviceImageView.isHidden = true
        keyImageView.isHidden = true
        keyActionContainerView.isHidden = true
        borderView.isHidden = true
        faceView.isHidden = false
        faceContainerView.isHidden = false
        mrzView.isHidden = true
        pinView.isHidden = true
        frameView.isHidden = false
        passportImageView.isHidden = true
        resetState()
        print(faceView.constraints)
        
        faceView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            faceView.leadingAnchor.constraint(equalTo:  frameView.leadingAnchor, constant: 0.0),
            faceView.trailingAnchor.constraint(equalTo: frameView.trailingAnchor, constant: 0.0),
            faceView.topAnchor.constraint(equalTo:  frameView.topAnchor, constant: 0.0 ),
            faceView.bottomAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 0.0 ),
        ])
        
        print(faceView.constraints)
        
    }

    
    // MARK: - Animation States
    
    private func resetState() {
        
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = nil
        
        layer.removeAllAnimations()
        keyImageView.layer.removeAllAnimations()
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

    
    func animateFace(message: String, image: UIImage? = nil ) {
        
        setupFaceInfoView(image: image)
        
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = message

        animateKeyConnected()
        pulsateBorderView(duration: 1.5)
    }
    
    func animateNFC(message: String) {
        setupPhonePassportView()
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = message
        animateConnectKey()
    }
    
    func animateMRZ(message: String) {
        setupMRZInfoView()
        borderView.backgroundColor = NamedColor.actionSheetIdleColor
        messageLabel.text = message
        animateConnectKey()
    }
    
    func pinEntry(message: String, pinCount: Int, delegate: PinEntryDelegate) {
        pinEntryDelegate = delegate
        setupPinEntry(pinCount: pinCount)
        //mrzView.delegate = delegate
        messageLabel.text = message
    }
    
    func mrzPreview(message: String, delegate: QKMRZScannerViewDelegate) {
        setupMrzPreview()
        mrzView.delegate = delegate
        mrzView.startScanning()
        mrzView.turnOnFlash()
        //mrzScannerView.delegate = self
        messageLabel.text = message
    }
    
    func facePreview(message: String, faceViewDelegate: FaceViewDelegate, image: UIImage? = nil) {
        
        if let image = image {
            setupFacePreview(image: image)
            faceView.delegate = faceViewDelegate
            try? faceView.start(with: image, and: nil, size: 160.0)
        }
        messageLabel.text = message
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
        guard let delegate = delegate else {
            return
        }
        delegate.actionSheetDidClick(self)
    }
}


extension NamedColor {
    
    /// The border color of the action sheet action view when no operation is done.
    static var actionSheetIdleColor = UIColor.white
    
    /// The border color of the action sheet action view when a touch is required for a operation to continue.
    static var actionSheetTouchColor = UIColorFrom(hex: 0xBAE950)
    
    /// The border color of the action sheet action view when the action sheet is set on a processing state.
    static var actionSheetProcessingColor = UIColorFrom(hex: 0x76D6FF)
    
    /// The border color of the action sheet action view when the action sheet is set on a processing state.
    static var actionSheetErrorColor = UIColor.systemRed

}


