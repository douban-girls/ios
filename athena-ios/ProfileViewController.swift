//
//  SecondViewController.swift
//  athena-ios
//
//  Created by AnnatarHe on 15/09/2017.
//  Copyright © 2017 AnnatarHe. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController {
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var userBio: UILabel!
    @IBOutlet weak var userCollectionsTableView: UICollectionView!
    @IBOutlet weak var profileContainer: UIView!
    
    var collections: [FetchProfileWithCollectionsQuery.Data.Collection?] = []
    
    var loadFrom = 0;
    var profileLoaded = false
    var loading = false
    
    private var collectionCursor = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userCollectionsTableView.dataSource = self
        userCollectionsTableView.delegate = self
        
        self.checkLogin()
        
    }
    
    @objc func touchAction(sender : UITapGestureRecognizer) {
        self.checkLogin()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !profileLoaded && Config.token != "" {
            self.loadProfile()
        }
    }
    
    func checkLogin() {
        if Config.token == "" {
            performSegue(withIdentifier: "toAuth", sender: nil)
        }
    }
    
    func showAlert(err: Error?) {
        guard let msg = err?.localizedDescription else {
            // do nothing
            return
        }
        
        let alert = UIAlertController(title: "Load profile data error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        // sentry report this error
        self.present(alert, animated: true)
    }
    
    func loadProfile() {
        Config.getApolloClient().fetch(query: FetchProfileWithCollectionsQuery(id: Int(Config.userId)!, from: self.loadFrom, size: 20)) { (result, err) in
            self.collectionCursor += 20
            guard let user = result?.data?.users else {
                self.showAlert(err: err)
                return
            }
            let avatarUrl: String
            let userObj = user.fragments.profile
            self.title = userObj.name!
            if userObj.avatar == "null" {
                avatarUrl = "https://via.placeholder.com/300x300"
            } else {
                avatarUrl = userObj.avatar!
            }
            
            let avatar = URL(string: avatarUrl)
            self.userAvatar.sd_setImage(with: avatar, placeholderImage: nil, options: .allowInvalidSSLCertificates, completed: nil)
            self.userName.text = userObj.name
            self.userBio.text = userObj.bio
            self.userEmail.text = userObj.email
            // todo: collection
            if let collects = result?.data?.collections {
                self.collections = collects
                self.userCollectionsTableView.reloadData()
            }
            
            self.userAvatar.layer.cornerRadius = 4.0
            self.userAvatar.layer.borderWidth = 1.0
            self.userAvatar.layer.borderColor = UIColor.clear.cgColor
            self.userAvatar.layer.masksToBounds = true
        }
    }
    
    func loadMoreCollect() {
        guard !loading else {
            return
        }
        loading = true
        
        Config.getApolloClient().fetch(query: FetchCollectionsQuery(id: Int(Config.userId)!, from: collectionCursor, size: 0)) { (result, err) in
            self.loading = false
            guard err == nil else {
                print(err)
                return
            }
            if let newCollection = result?.data?.collections {
                
                if (newCollection.count == 0) {
                    return
                }
                
                let nc = newCollection as! [FetchProfileWithCollectionsQuery.Data.Collection]
                
                self.collections.append(contentsOf: nc)
            }
            
            self.userCollectionsTableView.reloadData()
            self.collectionCursor += 20
        }
    }
}

extension ProfileViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionGirlCell", for: indexPath) as! CollectionItemCellCollectionViewCell
        let dataItem = collections[indexPath.row]
        let img = Utils.getRealImageSrc(image: (dataItem?.fragments.fetchGirls.img!)!)
        
        print(img)
        cell.img.sd_setImage(with: URL(string: img), placeholderImage: UIImage(named: "placeholderImage.png"), options: .allowInvalidSSLCertificates, completed: nil)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("ffdjaksdjflasjdkf")
        let dataCell = collectionView.cellForItem(at: indexPath) as! CollectionItemCellCollectionViewCell

        let dataItem = collections[indexPath.row] as! FetchProfileWithCollectionsQuery.Data.Collection
        
        Utils.presentBigPreview(
            view: self,
            imageUrl: dataItem.fragments.fetchGirls.img!,
            text: dataItem.fragments.fetchGirls.text!,
            holderImage: dataCell.img.image,
            from: dataCell
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        print("will display", indexPath.item, collections.count)
        if (indexPath.item == collections.count - 1) {
            // load more
            print("profile load more")
            self.loadMoreCollect()
        }
    }
    
    
}
