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
/*
import UIKit
import FaceVerifier
import SvipeStoreimport SvipeStore
import MRZScanner

open class InteractionViewController: RootViewController, ActionSheetViewDelegate, PromotionSheetViewDelegate, ConsentSheetViewDelegate, EngagementSheetViewDelegate {
    
    public enum Action {
        
        case processing
        case mrzInfo
        case mrzScan
        case nfcInfo
        case nfcScan
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
            case .nfcInfo: return 2.0
            case .mrzInfo: return 2.0
            case .faceInfo: return 2.0
            case .mrzScan: return 6.0
            case .faceScan: return 6.0
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
            case .nfcInfo: return 3.0
            case .mrzInfo: return 3.0
            case .faceInfo: return 3.0
            case .mrzScan: return 60.0
            case .faceScan: return 60.0
            case .error: return 10.0
            case .promotion1,.promotion2: return 5
            case .promotion3: return 30
            case .issuing: return 20.0
            case .success: return 2.0
            case .signup, .login, .sign, .disclose: return 6.0
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
    
    static let CHIPER_SUITE_IDENT = 1
    static let BLE_VERSION = 1
    static let WIFI_AWARE_VERSION = 1
    static let DE_VERSION = "1.0"
    
    private var engagementSheetView: EngagementSheetView?
    private var actionSheetView: ActionSheetView?
    private var promotionSheetView: PromotionSheetView?
    private var consentSheetView: ConsentSheetView?
    open var isSvipeApp = false
    open var callbackURL: URL?

    // MARK: - Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        let selector = #selector(applicationWillResignActive)
        let notificationName = UIApplication.willResignActiveNotification        
        NotificationCenter.default.addObserver(self, selector: selector, name: notificationName, object: nil)
    }
    
    deinit {
        let notificationName = UIApplication.willResignActiveNotification
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }
    
    // MARK: - Application Events
    
    @objc func applicationWillResignActive() {
        dismissActionSheet()
        dismissPromotionSheet()
        dismissEngagementSheet()
    }
    
    // MARK: - State
    
    public func waitForConnection() {
        waiting()
    }
    
    var engagmentAction: Action = .none
    
    @objc private func engagementDone() {
        engagmentAction = .done
    }
    
    @objc private func waiting() {
        engagmentAction = .waitingBLE
        DispatchQueue.main.async {
            self.presentEngagmentSheet(action: self.engagmentAction, message: "Waiting for connection over Bluetooth")
            //perform(#selector(engagementDone()), with: nil, afterDelay: engagmentAction.timeout)
        }
    }
    
    @objc private func searching() {
        engagmentAction = .searchingBLE
        presentEngagmentSheet(action: engagmentAction, message: "Searching for device")
        //perform(#selector(engagementDone()), with: nil, afterDelay: engagmentAction.timeout)
    }
    
    private func set(action: Action, message: String) {
        
        guard let actionSheet = engagementSheetView else {
            return
        }
        switch action {
        case .waitingBLE:
            waiting()
            break;
        default: // do nothing
            break
        }
    }
    
    private func set(action: Action) {
        guard let actionSheet = promotionSheetView else {
            return
        }
        switch action {
        case .promotion1:
            actionSheet.animatePromotion1()
        case .promotion2:
            actionSheet.animatePromotion2()
        case .promotion3:
            actionSheet.animatePromotion3()
        default:
            break
        }
    }
    
    private func set(action: Action, mandatoryRequest: AppItemsRequest, optionalRequest: AppItemsRequest, counterParty: String) {
        guard let actionSheet = consentSheetView else {
            return
        }
        let msg = action.subTitle(app: counterParty)
        switch action {
        case .signup, .disclose:
            actionSheet.signup(msg: msg, mandatoryRequest: mandatoryRequest, optionalRequest: optionalRequest)
        case .login:
            actionSheet.login(msg: msg, mandatoryRequest: mandatoryRequest, optionalRequest: optionalRequest)
        case .sign:
            actionSheet.sign(msg: msg, mandatoryRequest: mandatoryRequest, optionalRequest: optionalRequest)
        default:
            break
        }
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
    
    // MARK: - Orientation
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (context) in
            self?.updateActionSheetOrientation()
        }, completion: nil)
    }
    
    private func updateActionSheetOrientation() {
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        self.actionSheetView?.updateInterfaceOrientation(orientation: interfaceOrientation)
        self.promotionSheetView?.updateInterfaceOrientation(orientation: interfaceOrientation)
    }
        
    // MARK: - Actionsheet Presenting
    
    func presentActionSheet(action: Action, message: String, mrzDelegate: QKMRZScannerViewDelegate? = nil , image: UIImage? = nil, faceViewDelegate: FaceViewDelegate, completion: @escaping ()->Void = {}) {
        
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            
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

    func presentPromotionSheet(action: Action, completion: @escaping ()->Void = {}) {
        
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            
            guard self.promotionSheetView == nil else {
                self.set(action: action)
                completion()
                return
            }
            
            self.promotionSheetView = PromotionSheetView.loadViewFromNib()
            
            if let actionSheet = self.promotionSheetView, let parentView = UIApplication.shared.keyWindow {
                actionSheet.delegate = self
                actionSheet.frame = parentView.bounds
                
                parentView.addSubview(actionSheet)
                actionSheet.present(animated: true, completion: completion)
                self.set(action: action)
            } else {
                fatalError()
            }
            
            self.updateActionSheetOrientation()
        }
    }
    
    func presentEngagmentSheet(action: Action, message: String, completion: @escaping ()->Void = {}) {
        
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            
            guard self.engagementSheetView == nil else {
                self.set(action: action, message: message)
                completion()
                return
            }
            
            self.engagementSheetView = EngagementSheetView.loadViewFromNib()
            
            if let actionSheet = self.engagementSheetView, let parentView = UIApplication.shared.keyWindow {
                actionSheet.delegate = self
                actionSheet.frame = parentView.bounds
                parentView.addSubview(actionSheet)
                actionSheet.present(animated: true, completion: completion)
                self.set(action: action, message: message)
            } else {
                fatalError()
            }
            
            self.updateActionSheetOrientation()
        }
        
    }

    func presentConsentSheet(mandatoryRequest: AppItemsRequest, optionalRequest: AppItemsRequest, action: Action, counterParty: String, completion: @escaping ()->Void = {}) {
        
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            
            guard self.consentSheetView == nil else {
                self.set(action: action, mandatoryRequest: mandatoryRequest, optionalRequest: optionalRequest, counterParty: counterParty)
                completion()
                return
            }
            
            self.consentSheetView = ConsentSheetView.loadViewFromNib()
            
            if let actionSheet = self.consentSheetView,
                let parentView = UIApplication.shared.keyWindow {
                actionSheet.delegate = self
                actionSheet.frame = parentView.bounds
                parentView.addSubview(actionSheet)
                actionSheet.present(animated: true, completion: completion)
                self.set(action: action, mandatoryRequest: mandatoryRequest, optionalRequest: optionalRequest, counterParty: counterParty)
            } else {
                fatalError()
            }
            
            self.updateActionSheetOrientation()
        }
    }
    
    func dismissActionSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
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
    
    func dismissPromotionSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            guard let actionSheet = self.promotionSheetView else {
                completion()
                return
            }
            actionSheet.dismiss(animated: true, delayed: delayed) { [weak self] in
                guard let self = self else {
                    return
                }
                if let lightingActionSheet = self.promotionSheetView {
                    lightingActionSheet.removeFromSuperview()
                    self.promotionSheetView = nil
                }
                completion()
            }
        }
    }
    
    func dismissEngagementSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        self.engagmentAction = .none
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            guard let actionSheet = self.engagementSheetView else {
                completion()
                return
            }
            actionSheet.dismiss(animated: true, delayed: delayed) { [weak self] in
                guard let self = self else {
                    return
                }
                
                if let lightingActionSheet = self.engagementSheetView  {
                    lightingActionSheet.removeFromSuperview()
                    self.engagementSheetView  = nil
                }
                completion()
            }
        }
    }
    
    func dismissConsentSheet(delayed: Bool = true, completion: @escaping ()->Void = {}) {
        dispatchMain { [weak self] in
            guard let self = self else {
                return
            }
            guard let actionSheet = self.consentSheetView else {
                completion()
                return
            }
            actionSheet.dismiss(animated: true, delayed: delayed) { [weak self] in
                guard let self = self else {
                    return
                }
                if let lightingActionSheet = self.consentSheetView {
                    lightingActionSheet.removeFromSuperview()
                    self.consentSheetView = nil
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
    
    func dismissPromotionSheetAndPresent(message: String) {
        dismissPromotionSheet { [weak self] in
            self?.present(message: message)
        }
    }
    
    // MARK: - ActionSheetViewDelegate
    
    func actionSheetDidClick(_ actionSheet: ActionSheetView) {
        
    }
    
    func actionSheetDidCancel(_ actionSheet: ActionSheetView) {
          dismissActionSheet(delayed: false, completion: {})
      }

    func actionSheetError(_ actionSheet: ActionSheetView) {
           
    }
    
    
    func promotionSheetDidDismiss(_ promotionSheet: PromotionSheetView) {
        dismissPromotionSheet(delayed: false, completion: {})

    }
    
    func promotionSheetDidSignup(_ promotionSheet: PromotionSheetView) {
        dismissPromotionSheet(delayed: false, completion: {})
    }
    
    func promotionSheetError(_ promotionSheet: PromotionSheetView) {
        
    }

    func consentSheetDidContinue(_ consentSheet: ConsentSheetView) {
        dismissConsentSheet(delayed: false, completion: {})
        print("consentSheetDidContinue \(isSvipeApp) \(self.callbackURL)")
        if isSvipeApp, let url = self.callbackURL {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
      
    func consentSheetDidDismiss(_ consentSheet: ConsentSheetView) {
        dismissConsentSheet(delayed: false, completion: {})
        if isSvipeApp, let callbackURL = self.callbackURL {
            UIApplication.shared.open(callbackURL)
        }
    }
      
    func consentSheetError(_ consentSheet: ConsentSheetView) {
          
    }
    
    // MARK: - ActionSheetViewDelegate
    
    
    func engagementSheetError(_ actionSheet: EngagementSheetView) {
           
    }
    
    func engagmentSheetDidDismiss(_ actionSheet: EngagementSheetView) {
        dismissEngagementSheet(delayed: false, completion: {})
    }
    

    // mDLstuff
    
    static public func createQRCode(transferMethod: TransferMethod) throws -> Data? {
        
        let issuerAuthority = MockIssuerAuthority()
        let sessionManager = HolderSessionManager.shared
        try sessionManager.initializeHolderSession()
        
        sessionManager.checkDeviceKeysNeedingCertification(issuerAuthority: issuerAuthority)
        
        if let coseKey = sessionManager.generateHolderCoseKey() {
            
            let security = Security.Builder()
                .setCoseKey(coseKey: coseKey)
                .setCipherSuiteIdent(cipherSuiteIdent: CHIPER_SUITE_IDENT)
                .build()
            
            print("security \(security)")
            
            var builder = DeviceEngagement.Builder()
                .version(version: DE_VERSION)
                .security(security: security)
                
            let peripheralMode = true //BleUtils.isPeripheralSupported()
            let centralMode = true // BleUtils.isCentralModeSupported(app.applicationContext)
                
            let bleTransferMethod = BleTransferMethod(type: DeviceEngagement.TRANSFER_TYPE_BLE, version: BLE_VERSION, bleIdentification: BleTransferMethod.BleIdentification(peripheralServer: peripheralMode, centralClient: centralMode, peripheralServerUUID: nil, mac: nil))
            builder = builder.addTransferMethod(transferMethod: bleTransferMethod)
                
            let deviceEngagement = builder.build()
            print("deviceEngagement \(deviceEngagement)")
            
            try InteractionViewController.setupHolder(deviceEngagement: deviceEngagement,coseKey: coseKey, issuerAuthority: issuerAuthority)
            
            
            print("\nENCODE 1\n")
            if let encoded = try? deviceEngagement.encode() {
                
                /*
                print("\nDECODE\n")
                var builder = DeviceEngagement.Builder().decode(bytes: encoded)
                let de = builder.build()
                print("decoded", de)
                do {
                    print("\nENCODE 2\n")
                    let encoded2 = try de.encode()
                    if encoded == encoded2 {
                        print("round trip")
                    } else {
                        print("they differ")
                        print(encoded)
                        print(encoded2)
                    }
                } catch let error {
                    print("xxx" + error.localizedDescription)
                }
                */
                
                return Data(encoded)
            } else {
                print("Could not encode DeviceEngagement")
            }
        }
        return nil
    }
    
    
    static func setupHolder(deviceEngagement: DeviceEngagement, coseKey: CoseKey, issuerAuthority: IIssuerAuthority) throws {
        
        var builder = OfflineTransferManager.Builder().actAs(actAs: AppMode.HOLDER).setDataType(dataType: DataTypes.CBOR).setCoseKey(coseKey: coseKey)
        
        // OfflineTransferManager.Builder().setDelegate(delegate: self).actAs(AppMode.HOLDER).setDataType(DataTypes.CBOR).setCoseKey(coseKey)

        let bleTransportMethod = deviceEngagement.getBLETransferMethod()
        //let wifiTransportMethod = deviceEngagement.getWiFiAwareTransferMethod()

        if let bleTransport = bleTransportMethod, let bleIdentification = bleTransport.bleIdentification {
            builder = builder.setTransferChannel(transferChannel: TransferChannels.BLE)
            // both modes are supported
            if let centralClient = bleIdentification.centralClient, centralClient == true, let peripheralServer = bleIdentification.peripheralServer, peripheralServer == true  {
                builder = builder.setBleServiceMode(bleServiceMode: BleServiceMode.PERIPHERAL_SERVER_MODE)
                // only central client mode supported
            } else if (bleTransport.bleIdentification?.centralClient == true) {
                builder = builder.setBleServiceMode(bleServiceMode: BleServiceMode.CENTRAL_CLIENT_MODE)
                // only peripheral server mode supported
            } else {
                builder = builder.setBleServiceMode(bleServiceMode: BleServiceMode.PERIPHERAL_SERVER_MODE)
            }
        }
        
        /*
        if let wifiTransportMethod = wifiTransportMethod {
            builder = builder.setTransferChannel(transferChannel: TransferChannels.WiFiAware)
        }*/
        
        if let holder = try? builder.build() {
            // Set Data to be sent to the Verifier over WiFi
            let issuerAuthority = MockIssuerAuthority.shared
            if let ic = try ProvisioningManager.getIdentityCredential(credentialName: HolderSessionManager.CREDENTIAL_NAME) {
                print(" \(ic)")
                try holder.setupHolder(credentialName: HolderSessionManager.CREDENTIAL_NAME, deviceEngagement: try deviceEngagement.encode(), icApi: ic, isAuthRequired: true, issuerAuthority: issuerAuthority)
            } else {
                print("Could not find credential \(HolderSessionManager.CREDENTIAL_NAME)")
            }
        } else {
            print("Could not build holder")
        }
        return
    }
    
    
}
*/
