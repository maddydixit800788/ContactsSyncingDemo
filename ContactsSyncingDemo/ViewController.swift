//
//  ViewController.swift
//  ContactsSyncingDemo
//
//  Created by Madhav on 21/10/19.
//  Copyright © 2019 Madhav. All rights reserved.
//

import UIKit
import Contacts
import PhoneNumberKit

enum ContactsFilter {
    case none
    case mail
    case message
}

class ViewController: UIViewController {
    
    @IBOutlet weak var contactFilterSegment: UISegmentedControl!
    @IBOutlet weak var contactDataTable: UITableView!
    var contactFilter: ContactsFilter = .message
    
    var phoneContacts = [PhoneContact]() // array of PhoneContact(It is model find it below)
    var phoneNumbersWithCode = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadContacts(filter: .none) // Calling loadContacts methods
    }
    
    @IBAction func contactFilterSegmentActin(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            contactFilter = .message
        case 1:
            contactFilter = .mail
        case 2:
            contactFilter = .none
        default:
            contactFilter = .message
        }
        
        DispatchQueue.main.async {
            self.contactDataTable.reloadData()
        }
    }
    
      
    fileprivate func loadContacts(filter: ContactsFilter) {
        phoneContacts.removeAll()
        var allContacts = [PhoneContact]()
        for contact in PhoneContacts.getContacts() {
            allContacts.append(PhoneContact(contact: contact))
        }
        
        var filterdArray = [PhoneContact]()
        if filter == .mail {
            filterdArray = allContacts.filter({ $0.email.count > 0 }) // getting all email
        } else if filter == .message {
            filterdArray = allContacts.filter({ $0.phoneNumber.count > 0 }) // getting all number
        } else {
            filterdArray = allContacts
        }
        
        phoneContacts.append(contentsOf: filterdArray)
        
        for contact in phoneContacts {
            
            print("Name -> \(contact.name ?? "NA")")
            
            if filter == .mail || filter == .none {
                print("Email -> \(contact.email)")
            }
            
            if filter == .message || filter == .none {
                print("Phone Number -> \(contact.phoneNumber)")
            }
        }
        
        DispatchQueue.main.async {
            self.contactDataTable.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phoneContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TVCell", for: indexPath)
        
        let contact = phoneContacts[indexPath.row]
        
        cell.textLabel?.text = contact.name
        
        switch contactFilter {
        case .message:
            cell.detailTextLabel?.text = contact.phoneNumber[0]
        case .mail:
            cell.detailTextLabel?.text = contact.email.description ?? "NA"
        case .none:
            cell.detailTextLabel?.text = contact.phoneNumber[0]
        default:
            cell.detailTextLabel?.text = contact.phoneNumber[0]
        }
        
        return cell
    }
    
    
}

class PhoneContacts {

    class func getContacts() -> [CNContact] { //  ContactsFilter is Enum find it below

        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey] as [Any]

        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }

        var results: [CNContact] = []

        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)

            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching containers")
            }
        }
        return results
    }
}


class PhoneContact: NSObject {

    var name: String?
    var phoneNumber: [String] = [String]()
    var email: [String] = [String]()

    init(contact: CNContact) {
        name        = contact.givenName + " " + contact.familyName
        for phone in contact.phoneNumbers {
            if let number = phone.value as? CNPhoneNumber {

                let countryCodeStr = number.value(forKey: "countryCode") as? String ?? "IN"
                
                // Get The Mobile Number
                var mobile = number.stringValue
                mobile = mobile.replacingOccurrences(of: " ", with: "")

                // Parse The Mobile Number
                let phoneNumberKit = PhoneNumberKit()

                do {
                    let phoneNumberCustomDefaultRegion = try phoneNumberKit.parse(mobile, withRegion: countryCodeStr, ignoreType: true)
                    let countryCode = String(phoneNumberCustomDefaultRegion.countryCode)
                    let mobile = String(phoneNumberCustomDefaultRegion.nationalNumber)
                    let finalMobile = "+" + countryCode + mobile
                    phoneNumber.append(finalMobile)
                } catch {
                    print("Generic parser error")
                }
            }
        }
        for mail in contact.emailAddresses {
            email.append(mail.value as String)
        }
    }

    override init() {
        super.init()
    }
}
