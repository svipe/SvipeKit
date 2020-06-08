//
//  SvipeAuthenticationButton.swift
//  SvipeKit
//
//  Created by Johan Sellström on 2020-06-08.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import UIKit

public class SvipeAuthenticationButton: UIButton {
    
    public var delegate: SvipeAuthenticationButtonDelegate?
    static private let svipeIcon = UIImage(named: "SvipeLogo")
    var status: Status = .unregistered
    let auth = Authenticator()
    public var authenticationProtocol: AuthenticationProtocol = .openid

    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        getStatus()
        setupButton()
    }
    
    override public func setTitle(_ title: String?, for state: UIControl.State) {
        
        print("setTitle \(status.title) ")
        
        switch status {
        case .registered, .unregistered:
            if title == nil {
                super.setTitle(status.title, for: state)
            } else {
                 super.setTitle(title, for: state)
            }
        default:
             super.setTitle(status.title, for: state)
        }
    }
    
    func setupButton() {
        // Only style if Svipe is installed otherwise it is whitelabled
        switch status {
        case .unregisteredWithSvipe, .registeredWithSvipe:
            setTitle(nil, for: .normal)
            setTitleColor(.white, for: .normal)
            backgroundColor      = NamedColor.svipeOrange
            //titleLabel?.font     = UIFont(name: "MyriadVariable-Concept", size: 18)
            
            if layer.cornerRadius == 0 {
                layer.cornerRadius = 25
            }
            
            if layer.borderWidth == 0 {
                layer.borderWidth = 1.0
            }
            
            if layer.borderColor == nil {
                layer.borderColor = UIColor.darkGray.cgColor
            }
            
            let iconView = UIImageView()
            iconView.tintColor = .white
            iconView.image = SvipeAuthenticationButton.svipeIcon
            addSubview(iconView)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            
            if let title = titleLabel {
                NSLayoutConstraint.activate([
                    iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4.0),
                    //iconView.trailingAnchor.constraint(equalTo: title.leadingAnchor, constant: 2.0),
                    iconView.topAnchor.constraint(equalTo: topAnchor, constant: 4.0 ),
                    iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4.0 ),
                    widthAnchor.constraint(equalToConstant: 200),
                    heightAnchor.constraint(equalToConstant: 50)
                ])
            }
            
            titleLabel?.sizeToFit()
        default:
            break
        }
        //addTarget(self, action: #selector(doAction), for: .touchUpInside)
    }
    
    @objc
    func doAction() {
        auth.doAction()
    }
    
    private func getStatus() {
           
        if hasSvipe {
            if isRegistered {
                status = .registeredWithSvipe
            } else {
                status = .unregisteredWithSvipe
            }
        } else {
            if isRegistered {
                status = .registered
            } else {
                status = .unregistered
            }
        }
    }
    
    private var hasSvipe: Bool {
        if let url = URL(string: "svipeid:"), UIApplication.shared.canOpenURL(url) {
            return true
        } else {
            return false
        }
    }
    
    private var isRegistered: Bool {
        return false
    }
}
