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
import SvipeStore

//
// MARK: - ConsentSheetViewConfiguration Configuration
//

// Some temporary data structures

public struct DisclosureRequest{
    public var mandatory: Bool
    public let title: String
    public var value: String
    
    public init(mandatory: Bool, title: String, value: String) {
        self.mandatory = mandatory
        self.title = title
        self.value = value
    }
}

struct Credential {
    let name: String
    // Counterparty etc
}

var requests    = [DisclosureRequest]()
var credentials = [Credential]()

class ConsentSheetViewConfiguration {
    
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

protocol ConsentSheetViewDelegate: NSObjectProtocol {
    func consentSheetDidContinue(_ consentSheet: ConsentSheetView)
    func consentSheetDidDismiss(_ consentSheet: ConsentSheetView)
    func consentSheetError(_ consentSheet: ConsentSheetView)
}

class ConsentSheetView: UIView {
    
    private let bundle = Bundle(for: ConsentSheetView.self)

    weak var delegate: ConsentSheetViewDelegate?

    private let configuration = ConsentSheetViewConfiguration()
    private static let viewNibName = String(describing: ConsentSheetView.self)
    
    private var isPresenting = false
    private var isDismissing = false
    
    private var mandatoryRequest: AppItemsRequest?
    private var optionalRequest: AppItemsRequest?
    
    // MARK: - Outlets
    
    @IBOutlet var actionSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionSheetView: UIView!
    
    @IBOutlet var keyActionContainerView: UIView!
    @IBOutlet var backgroundFadeView: UIView!
    
    @IBOutlet weak var consentImageView: UIImageView!
    
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var continueButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
   
    @IBOutlet weak var consentTextView: UITextView!
    
    @IBAction func didTapBackground(_ sender: Any) {
        delegate?.consentSheetDidDismiss(self)
    }
    // MARK: - Lifecycle
    
    class func loadViewFromNib() -> ConsentSheetView? {
        let bundle = Bundle(for: ConsentSheetView.self)
        guard let nibs = bundle.loadNibNamed(viewNibName, owner: nil, options: nil) else {
            return nil
        }
        guard let view = nibs.first as? ConsentSheetView else {
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
  
    private func setup() {
        requests.removeAll()
        
        if let itemsRequest = self.mandatoryRequest {
             for nameSpace in itemsRequest.nameSpaces {
                 for name in nameSpace.entryNames {
                     let dr = DisclosureRequest(mandatory: true, title: name, value: "")
                     requests.append(dr)
                 }
             }
         }

        if let itemsRequest = self.optionalRequest {
            for nameSpace in itemsRequest.nameSpaces {
                for name in nameSpace.entryNames {
                    let dr = DisclosureRequest(mandatory: false, title: name, value: "")
                    requests.append(dr)
                }
            }
        }
        
        credentials = [ Credential(name: "True Identity"), Credential(name: "Anonymous")]
        self.pickerView.delegate = self
        self.pickerView.reloadAllComponents()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let bundle = Bundle(for: ConsentSheetView.self)
        let tableViewCell = UINib(nibName: "TableViewCell", bundle: bundle)
        tableView.register(tableViewCell, forCellReuseIdentifier: "TableViewCell")
        tableView.reloadData()
    }
    
    // MARK: - Animation States
    
    func disclose(msg: String) {
         setup()
         pickerView.isHidden = true
         tableView.isHidden = false
         consentTextView.isHidden = true
         messageLabel.text = msg
         self.continueButton.backgroundColor = .systemGroupedBackground
         self.continueButton.titleLabel?.text = NSLocalizedString("Cancel", comment: "")
     }
    
    func signup(msg: String, mandatoryRequest: AppItemsRequest, optionalRequest: AppItemsRequest) {
        self.mandatoryRequest = mandatoryRequest
        self.optionalRequest = optionalRequest
        setup()
        pickerView.isHidden = true
        tableView.isHidden = false
        consentTextView.isHidden = true
        messageLabel.text = msg
        //self.continueButton.titleLabel?.text = NSLocalizedString("Continue", comment: "")
    }
    
    func login(msg: String, mandatoryRequest: AppItemsRequest, optionalRequest: AppItemsRequest) {
        self.mandatoryRequest = mandatoryRequest
        self.optionalRequest = optionalRequest
        setup()
        pickerView.isHidden = false
        tableView.isHidden = true
        consentTextView.isHidden = true
        messageLabel.text = msg
        //self.continueButton.titleLabel?.text = NSLocalizedString("Continue", comment: "")
    }
    
    func sign(msg: String,mandatoryRequest: AppItemsRequest, optionalRequest: AppItemsRequest) {
        self.mandatoryRequest = mandatoryRequest
        self.optionalRequest = optionalRequest
        setup()
        pickerView.isHidden = true
        tableView.isHidden = true
        consentTextView.isHidden = false
        //print(consentView.consentTextView.attributedText)
        consentTextView.text = """
        Cookie Policy for Svipe ID

        This is the Cookie Policy for Svipe ID, accessible from https://id.svipe.com

        What Are Cookies

        As is common practice with almost all professional websites this site uses cookies, which are tiny files that are downloaded to your computer, to improve your experience. This page describes what information they gather, how we use it and why we sometimes need to store these cookies. We will also share how you can prevent these cookies from being stored however this may downgrade or 'break' certain elements of the sites functionality.

        For more general information on cookies see the Wikipedia article on HTTP Cookies.

        How We Use Cookies

        We use cookies for a variety of reasons detailed below. Unfortunately in most cases there are no industry standard options for disabling cookies without completely disabling the functionality and features they add to this site. It is recommended that you leave on all cookies if you are not sure whether you need them or not in case they are used to provide a service that you use.
        """

        messageLabel.text = msg
        //self.continueButton.titleLabel?.text = NSLocalizedString("Continue", comment: "")
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
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        delegate?.consentSheetDidContinue(self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.consentSheetDidDismiss(self)
    }
}

extension ConsentSheetView: UITableViewDelegate {
    
}

extension ConsentSheetView: UITableViewDataSource {
    
    /*func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let request = requests[indexPath.row]
        return !request.mandatory
    }*/
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection \(section) = \(requests.count)")
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell" , for: indexPath) as! TableViewCell
        let request = requests[indexPath.row]
        cell.attributeTitle.text = request.title.uppercased()
        cell.attributeValue.text = request.value
        
        if !request.mandatory {
            cell.delegate = self
        } else {
            cell.removeButton.isHidden = true
        }
 
        return cell
    }
    
    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        /*let row = indexPath.row
        requests.remove(at: row)*/
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if let row = indexPath?.row {
            print("didEndEditingRowAt \(row)")
        }
    }*/
    
    
}

extension ConsentSheetView: TableDelegate {
    
    func remove(_ cell: TableViewCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            print("Did click remove \(indexPath) \(cell.tag) with \(requests.count) objects")
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            requests.remove(at: indexPath.row)
            tableView.endUpdates()
        }
        
    }
    
}

extension ConsentSheetView: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return credentials.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return credentials[row].name
    }
}

extension ConsentSheetView: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("didSelectRow row: \(row)")
    }
    
}
