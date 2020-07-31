import UIKit
import SvipeStore
import SvipeReader
import FaceVerifier
import CoreNFC
import SvipeMRZ
import SvipeCA
import CryptoSwift

public enum AuthenticationProtocol {
    case openid
    case fido2
    case svipe
}

@objc enum Status: Int {
    
    case unregistered
    case unregisteredWithSvipe
    case registered
    case registeredWithSvipe
    
    var title: String {
        switch self {
        case .unregistered: return NSLocalizedString("Register", comment: "")
        case .registered: return NSLocalizedString("Login", comment: "")
        case .unregisteredWithSvipe, .registeredWithSvipe: return NSLocalizedString("Sign in with SvipeID", comment: "")
        }
    }
}

public typealias ScanHandler = ((_ passport: CredentialDocument?, _ error: Error? ) -> Void)

public protocol SvipeAuthenticationButtonDelegate {
    func didCancel()
    func didFail()
    func didSucceed(passport: CredentialDocument)
}

public protocol PinEntryDelegate {
    func didEnter(pinCode: String)
}

@objc
open class Authenticator: NSObject {
    
    private enum Action {
        
        case processing
        case mrzInfo
        case mrzScan
        case nfcInfo
        case nfcScan
        case pinEntry
        case faceInfo
        case faceScan
        case issuing
        case success
        case error
        case none
        case done
        case promotion1
        case promotion2
        case promotion3
        case pin
        
        case disclose
        case signup
        case login
        case sign

        case waitingBLE
        case searchingBLE
        case connectingBLE
        case connectingWifi
        case handshakeBLE
        case transferBLE

        #if IOS_SIMULATOR || arch(i386) || arch(x86_64)
        var timeout: TimeInterval {
            switch self {
            case .mrzScan: return 2.0
            case .faceScan: return 4.0
            case .error: return 2.0
            case .promotion1,.promotion2, .promotion3: return 5
            case .signup, .login , .sign, .disclose: return 60.0
            case .success: return 3.0
            case .issuing: return 5.0
            default: return 5.0
            }
        }
        #else
        var timeout: TimeInterval {
            switch self {
            case .mrzScan: return 60.0
            case .faceScan: return 60.0
            case .error: return 10.0
            case .promotion1,.promotion2: return 5
            case .promotion3: return 30
            case .issuing: return 5.0
            case .success: return 3.0
            case .signup, .login, .sign, .disclose: return 60.0
            default: return 15.0
            }
        }
        #endif
        
        func subTitle(app: String) -> String {
            switch self {
            case .disclose: return NSLocalizedString("Disclose the information below to ", comment: "") + app
            case .signup: return NSLocalizedString("Create an account for ", comment: "") + app + " " + NSLocalizedString("and share the information below", comment: "")
            case .login: return NSLocalizedString("Sign in to ", comment: "") + app + NSLocalizedString(" as", comment: "")
            case .sign: return NSLocalizedString("Sign the agreement", comment: "")
            default: return ""
                
            }
        }
    }
    
    open var requestItems: AppItemsRequests? {
        didSet {
            
        }
    }

    private var credentialName: String?

    public var delegate: SvipeAuthenticationButtonDelegate?

    private var currentAction: Action = .mrzInfo
    //private var user: PublicKeyCredentialUserEntity = PublicKeyCredentialUserEntity()

    private var sceneObserver: SceneObserver?
    private var mrzKey: String = ""
    private var passportModel : NFCPassportModel?
    private var selfie: UIImage?
      
    private var pinCount: Int = 6
    private var pinRequired = false
    private var pinCode: String?
    
    private var testflightURLString = "https://testflight.apple.com/join/OZk7cdTY"

    private var actionSheetView: ActionSheetView?
    
    private let bundle = Bundle(for: Authenticator.self)

    private var scanCompletionHandler: ScanHandler?
    private var documentFilter: [SupportedClaim] = [SupportedClaim]()

    //private var mrzScannerView: QKMRZScannerView = QKMRZScannerView()
    private let passportReader = SvipeReader()
    private var faceView: FaceView = FaceView()

    @objc
    override public init() {
        super.init()
        setup()
    }
    
    @objc
    public func setup() {
        faceView.mode = .production
        actionSheetView?.delegate = self
        setupObserver()
    }
    
    // Do we have an alternative when keyWindow does not work?
    private func setupObserver() {
        if let window = UIApplication.shared.keyWindow {
            SceneObserver.setupApplication(window: window)
        } else {
            Log.error("Could not get window")
        }
    }

    public func authenticate(callbackURL: String, credentialName: String, mandatoryClaims: [SupportedClaim], optionalClaims: [SupportedClaim],  _ completion: @escaping ScanHandler) {

        self.credentialName = credentialName

        if let callbackURLString = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = JOSE.createOpenidRequestURL(privateKey: nil, callbackURLString: callbackURL, credentialName: credentialName, mandatoryClaims: mandatoryClaims, optionalClaims:  optionalClaims), let customURL = URL(string:"svipe:"),  UIApplication.shared.canOpenURL(customURL) {
            UIApplication.shared.open(url, options: [:]) { (success) in
                print("open url \(url) with \(success)")
            }
        } else {
            scanCompletionHandler = completion
            documentFilter = [.email]
            doAction()
        }
    }

    /*
    @objc
    public func scanDocument(callbackURL: String, _ completion: @escaping ScanHandler) {
        if let callbackURLString = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "https://login.svipe.io/?client_id="+callbackURLString), let customURL = URL(string:"svipe:"),  UIApplication.shared.canOpenURL(customURL) {
            UIApplication.shared.open(url, options: [:]) { (success) in
                print("open url \(url) with \(success)")
            }
        } else {
            scanCompletionHandler = completion
            doAction()
        }
    }
    */
    
    /*
     The normal flow is according to the switch below
     */
    
    @objc public func doAction() {
    
        switch currentAction {
        case .none:
            mrzInfo()
        case .mrzScan:
            mrzScan()
        case .nfcInfo:
            nfcInfo()
        case .pinEntry: // pinCount is determined by MRZ
            pinEntry()
        case .nfcScan:
            nfcScan()
        case .faceInfo:
            faceInfo()
        case .faceScan:
            faceScan()
        case .issuing:
            issuing()
        default:
            mrzInfo()
        }
    }

    open func cancel() {
        reset()
        currentAction = .none
        dismissActionSheet()
    }
       
    @IBAction func didTapBackground(_ sender: Any) {
        cancel()
    }
           
    private func set(action: Action, message: String, image: UIImage? = nil, mrzDelegate: QKMRZScannerViewDelegate? = nil, faceViewDelegate: FaceViewDelegate) {
        
        guard let actionSheet = actionSheetView else {
            return
        }
        
        switch action {
        case .mrzInfo:
            actionSheet.animateMRZ(message: message)
        case .nfcInfo:
            actionSheet.animateNFC(message: message)
        case .faceInfo:
            actionSheet.animateFace(message: message, image: image)
        case .pinEntry:
            actionSheet.pinEntry(message: message, pinCount: self.pinCount, delegate: self)
        case .mrzScan:
            if let delegate =  mrzDelegate {
                actionSheet.mrzPreview(message: message, delegate: delegate)
            }
        case .faceScan:
            actionSheet.facePreview(message: message, faceViewDelegate: faceViewDelegate, image: image)
        case .success:
            actionSheet.animateSuccess(message: message)
        case .issuing:
            actionSheet.animateProcessing(message: message)
        case .processing:
            actionSheet.animateProcessing(message: message)
        case .error:
            actionSheet.animateError(message: message)
        default: // do nothing in case of f.i nfc scan
            break
        }
    }
    
    // MARK: - Actions
       
    @objc private func errorMessage(msg: Any?) {
           
        guard let msg = msg as? String else {
            return
        }
        let action: Action = .error
        presentProgress(message: msg, action: action)
        perform(#selector(quit), with: nil, afterDelay: action.timeout)
    }
       
    @objc private func mrzInfo() {
           
        currentAction = .mrzInfo
        presentProgress(message: "Scan the machine readable text", action: currentAction)
    }
       
    @objc private func mrzScan() {
        currentAction = .mrzScan
        presentProgress(message: "Fit the text in the viewfinder", action: currentAction)
           
        if UIDevice.isSimulator {
            if pinRequired {
                perform(#selector(pinEntry), with: self.pinCount, afterDelay: currentAction.timeout)
            } else {
                perform(#selector(nfcInfo), with: nil, afterDelay: currentAction.timeout)
            }
        } else {
            perform(#selector(errorMessage), with:  "Timed out", afterDelay: currentAction.timeout)
        }
    }
       
    @objc private func pinEntry() {
        currentAction = .pinEntry
        presentProgress(message: "Enter your pin", action: currentAction)
    }
    
    @objc private func nfcInfo() {
        currentAction = .nfcInfo
        presentProgress(message: "Put the phone on the id document", action: currentAction)
    }

    @objc private func faceInfo() {
           
        currentAction = .faceInfo
        #if IOS_SIMULATOR || arch(i386) || arch(x86_64)
            let image = UIImage(named:"SamplePassportPhoto", in: bundle, compatibleWith: nil)
        #else
            guard  let model = self.passportModel else {
                return
            }
            let image = self.passportModel?.passportImage
        #endif
        presentProgress(message: "Scan your face to make sure it matches", image: image, action: currentAction)
    }
       
    @objc private func faceScan() {
        
        #if IOS_SIMULATOR || arch(i386) || arch(x86_64)
            let image = UIImage(named:"SamplePassportPhoto", in: bundle, compatibleWith: nil)
            currentAction = .faceScan
            presentProgress(message: "Fit your face in the viewfinder",  image: image, action: currentAction)
            perform(#selector(issuing), with: nil, afterDelay: currentAction.timeout)
        #else
            guard let model = self.passportModel else {
                quit()
                return
            }

            let passport = CredentialDocument(model: model)
            guard let image = passport.image else {
                return
            }
            currentAction = .faceScan
            presentProgress(message: "Fit your face in the viewfinder",  image: image, action: currentAction)
            //perform(#selector(errorMessage), with: "Timed out", afterDelay: currentAction.timeout)
        #endif
    }

    @objc private func issuing() {
    
        reset()
        currentAction = .issuing
                   
       #if IOS_SIMULATOR || arch(i386) || arch(x86_64)
        var passport = CredentialDocument(isDemo: true)
        self.selfie = passport.image
        self.passportModel = NFCPassportModel()
        guard let model = self.passportModel, let selfie = self.selfie else {
            self.perform(#selector(self.errorMessage), with: "No model or selfie", afterDelay: 1)
            return
        }
       #else
        guard let model = self.passportModel, let selfie = self.selfie else {
            self.perform(#selector(self.errorMessage), with: "No model or selfie", afterDelay: 1)
            return
        }
        var passport = CredentialDocument(model: model)
       #endif
           
        presentProgress(message: "Verifying and issuing credentials ", action: currentAction)
    
        if !UIDevice.isSimulator {
            SvipeCA.verify(model: model, selfie: selfie) { (data, error) in
                
                if let error = error  {
                    Log.error(error.localizedDescription)
                    self.perform(#selector(self.errorMessage), with: "Could not verify document:" + error.localizedDescription, afterDelay: 1)
                } else {
                    
                    guard let data = data else {
                        self.perform(#selector(self.errorMessage), with: "No data from verification service", afterDelay: 1)
                        return
                    }
                    
                    if let response = try? JSONDecoder().decode(IssuerResponseDataObject.self, from: data) {
                        let signBytes =  ByteArray(Data(hex:response.signing.first!.issuerAuth))
                        let coseSign1 = CoseSign1.Builder().decode(coseSign1Data: signBytes).build()
                        print(coseSign1)
                        
                        if let bytes = coseSign1.dsCertificateBytes {
                            let rootCertificateInitialiser = try! RootCertificateInitialiser()
                            let rootCertificatesAndPublicKeys = rootCertificateInitialiser.rootCertificatesAndPublicKeys
                            if let certificate = try? DSCertificate(bytes: bytes, rootCertificatesAndPublicKeys: rootCertificatesAndPublicKeys, issuingCountry: nil) {
                                print(certificate.x509Certificate)
                            }
                        } else {
                            print("No certificate")
                        }
                        
                        let issuerBytes = ByteArray(Data(hex:response.signing.first!.issuerNameSpaces))
                        if let issuerNameSpaces = try? IssuerNameSpaces.Builder().decode(data: issuerBytes) {
                            print(issuerNameSpaces)
                        } else {
                            print("could not decode IssuerNameSpaces")
                        }
                    }
                    self.success()
                }
            }
        } else {
            self.perform(#selector(self.success), with: nil, afterDelay: self.currentAction.timeout)
        }
    }
       
    @objc private func success() {
        currentAction = .success
        presentProgress(message: "Success", action: currentAction )
        perform(#selector(done), with: nil, afterDelay: currentAction.timeout)
        if let model = self.passportModel {
            #if IOS_SIMULATOR || arch(i386) || arch(x86_64)
            let passport = CredentialDocument(isDemo: true)
            #else
            let passport = CredentialDocument(model: model)
            #endif
            print(passport)
            quit()
            scanCompletionHandler?(passport, nil)
            delegate?.didSucceed(passport: passport)
            //self.svipeSuccess(passport: passport)
        }
    }

    @objc private func quit() {
        dismissActionSheet()
    }
       
    @objc private func finalized() {
        currentAction = .none
        reset()
    }
       
    @objc private func done() {
        dismissActionSheet()
        currentAction = .done
        reset()
    }
       
    // MARK: - Progress

    private func presentProgress(message: String, image: UIImage? = nil, action: Action) {
        presentActionSheet(action: action, message: message, mrzDelegate: self, image: image,  faceViewDelegate: self)
    }
       
    private func dismissAuthenticationProgressAndPresent(message: String) {
        dismissActionSheetAndPresent(message: message)
        return
    }
       
    // MARK: - MRZ stuff
       
    private func calcCheckSum( _ checkString : String ) -> Int {
        let characterDict  = ["0" : "0", "1" : "1", "2" : "2", "3" : "3", "4" : "4", "5" : "5", "6" : "6", "7" : "7", "8" : "8", "9" : "9", "<" : "0", " " : "0", "A" : "10", "B" : "11", "C" : "12", "D" : "13", "E" : "14", "F" : "15", "G" : "16", "H" : "17", "I" : "18", "J" : "19", "K" : "20", "L" : "21", "M" : "22", "N" : "23", "O" : "24", "P" : "25", "Q" : "26", "R" : "27", "S" : "28","T" : "29", "U" : "30", "V" : "31", "W" : "32", "X" : "33", "Y" : "34", "Z" : "35"]
           
        var sum = 0
        var m = 0
        let multipliers : [Int] = [7, 3, 1]
        for c in checkString {
            guard let lookup = characterDict["\(c)"], let number = Int(lookup) else { return 0 }
            let product = number * multipliers[m]
            sum += product
            m = (m+1) % 3
        }
           
        return (sum % 10)
    }
       
    @objc private func nfcScan() {
    
        currentAction = .nfcScan
        var failed = false
        if UIDevice.isSimulator {
            print("pinCode is \(self.pinCode)")
        } else {
               
            self.sceneObserver = SceneObserver(sceneActivationClosure: { [weak self] in
                if let self = self {
                    self.sceneObserver = nil
                    if failed {
                        self.reset()
                        self.nfcInfo()
                    } else {
                        self.faceInfo()
                    }
                }
            })
            
            // Set the masterListURL on the Passport Reader to allow auto passport verification
            //let masterListURL = bundle.url(forResource: "masterList", withExtension: ".pem")!
            //passportReader.setMasterListURL( masterListURL )
               
            passportReader.readPassport(mrzKey: mrzKey, customDisplayMessage: { (displayMessage) in
                switch displayMessage {
                    case .requestPresentPassport:
                        return "Hold your iPhone near an NFC enabled passport or id card."
                    default:
                        // Return nil for all other messages so we use the provided default
                        return nil
                }
            }, completed: { (passportModel, error) in
                if let passportModel = passportModel {
                    print("document type \(passportModel.documentType)")
                    // All good, we got a passport
                    DispatchQueue.main.async {
                        self.passportModel = passportModel
                        // In case we could not get keyWindow etc
                        if self.sceneObserver == nil {
                            self.faceInfo()
                        }
                    }
                } else {
                    failed = true
                    self.errorMessage(msg: "\(error?.localizedDescription ?? "Unknown error")")
                    Log.error("Abort \(error?.localizedDescription ?? "Unknown error")")
                       
                    if self.sceneObserver == nil {
                        self.reset()
                        self.nfcInfo()
                    }
                }
            })
        }
    }
       
    private func clearTimeouts() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // MARK: - Orientation
    
    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (context) in
            self?.updateActionSheetOrientation()
        }, completion: nil)
    }
    
    private func updateActionSheetOrientation() {
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        self.actionSheetView?.updateInterfaceOrientation(orientation: interfaceOrientation)
    }
    
    // MARK: - Actionsheet Presenting
    
    private func presentActionSheet(action: Action, message: String, mrzDelegate: QKMRZScannerViewDelegate? = nil , image: UIImage? = nil, faceViewDelegate: FaceViewDelegate, completion: @escaping ()->Void = {}) {
        
        DispatchQueue.main.async {
            guard self.actionSheetView == nil else {
                self.set(action: action, message: message, image: image, mrzDelegate: mrzDelegate, faceViewDelegate: faceViewDelegate)
                completion()
                return
            }
            
            self.actionSheetView = ActionSheetView.loadViewFromNib()
            
            if let actionSheet = self.actionSheetView, let parentView = UIApplication.shared.keyWindow {
                actionSheet.delegate = self
                actionSheet.frame = parentView.bounds
                
                parentView.addSubview(actionSheet)
                actionSheet.present(animated: true, completion: completion)
                self.set(action: action, message: message, image: image, mrzDelegate: mrzDelegate, faceViewDelegate: faceViewDelegate)
            } else {
                fatalError()
            }
            
            self.updateActionSheetOrientation()
        }
    }

    func dismissActionSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        
        DispatchQueue.main.async {
            guard let actionSheet = self.actionSheetView else {
                completion()
                return
            }
            
            actionSheet.dismiss(animated: true, delayed: delayed) { [weak self] in
                guard let self = self else {
                    return
                }
                if let lightingActionSheet = self.actionSheetView {
                    lightingActionSheet.removeFromSuperview()
                    self.actionSheetView = nil
                }
                completion()
            }
        }
    }
    
    func dismissActionSheetAndPresent(message: String) {
        dismissActionSheet { [weak self] in
            self?.present(message: message)
        }
    }
   
    // MARK: - Message Presenting

     func present(message: String) {
        DispatchQueue.main.async {
             let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
             alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            
             // self?.present(alert, animated: true, completion: nil)
         }
     }
     
     func present(error: Error) {
         DispatchQueue.main.async {
             let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
             alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
             // self?.present(alert, animated: true, completion: nil)
         }
     }
    
   private func reset() {
       clearTimeouts()
   }

}

extension Authenticator: PinEntryDelegate {
    
    public func didEnter(pinCode: String) {
        self.pinCode = pinCode
        nfcInfo()
    }
}

extension Authenticator: FaceViewDelegate {
    
    public func faceView(_ faceView: FaceView, didFail message: String) {
            
    }

    public func faceView(_ faceView: FaceView, didFindMatchingFace: Bool) {
        
        print("Matching face!")
        
        if didFindMatchingFace {
            issuing()
        } else {
            errorMessage(msg: "Could not match face")
            // error, this could be due to a timeout
        }
    }
         
    public func faceView(_ faceView: FaceView, didCrop face: UIImage) {
        self.selfie = face
    }
         
    public func faceView(_ faceView: FaceView, didComputeDistance distance: Double) {
        // ignore
    }
}

extension Authenticator: QKMRZScannerViewDelegate {
    
    public func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
           
        clearTimeouts()
        mrzScannerView.stopScanning()
           
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd"

        var passportNumber = ""
        var dateOfBirth = ""
        var expiryDate = ""

        let documentNumber = scanResult.documentNumber

        if documentNumber.count < 9 {
            passportNumber = documentNumber + String.init(repeating: "<", count: 9 - documentNumber.count)
        } else {
            passportNumber = documentNumber
        }

        guard let _birthDate = scanResult.birthDate, let _expiryDate = scanResult.expiryDate else {
            return
        }
           
        dateOfBirth = dateFormatter.string(from: _birthDate)
        expiryDate = dateFormatter.string(from: _expiryDate)

        let passportNrChksum = calcCheckSum(passportNumber)
        let dateOfBirthChksum = calcCheckSum(dateOfBirth)
        let expiryDateChksum = calcCheckSum(expiryDate)

        self.mrzKey = "\(passportNumber)\(passportNrChksum)\(dateOfBirth)\(dateOfBirthChksum)\(expiryDate)\(expiryDateChksum)"
        
        self.pinCount = 6
        
        if pinRequired {
            pinEntry()
        } else {
            nfcInfo()
        }
    
    }
       
}

extension Authenticator: ActionSheetViewDelegate {
    
    // MARK: - ActionSheetViewDelegate
                    
    func actionSheetDidCancel(_ actionSheet: ActionSheetView) {
        dismissActionSheet(delayed: false, completion: {})
        reset()
    }
          
    func actionSheetDidClick(_ actionSheet: ActionSheetView) {
           
        switch currentAction {
        case .mrzInfo:
            mrzScan()
        case .pinEntry:
            nfcInfo()
        case .nfcInfo:
            if NFCNDEFReaderSession.readingAvailable {
                nfcScan()
            } else {
                faceInfo()
            }
        case .faceInfo:
            faceScan()
        default:
            print("\(currentAction)")
            actionSheetDidCancel(actionSheet)
            reset()
        }
    }
       
    func actionSheetError(_ actionSheet: ActionSheetView) {
        // We should not reset nextAction
        print("error")
    }
    
}
