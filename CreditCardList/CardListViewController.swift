//
//  CardListViewController.swift
//  CreditCardList
//
//  Created by 오승준 on 2022/06/09.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseFirestore

class CardListViewController: UITableViewController {
    //UIViewController? 테이블 뷰를 구성하려면 필요한 델리게이트와 데이터소스를 기본 연결된 상태로 제공해 별도로 델리게이트 선언을 하지 않아도 된다. root view로 uitableview를 가지게 된다. UIViewcontroller는 그냥 view를 root view로 가진다.
//    var ref: DatabaseReference!     //Firebase Realtime Database 가져올 수 있는 데이터베이스 레퍼런스
    var db = Firestore.firestore()
    
    
    var creditCardList: [CreditCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UITableView Cell Register
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
        //실시간 데이터베이스 읽기
        
        
//        self.ref = Database.database().reference()
//
//        //레퍼런스에서 값을 지켜보다가 값을 snapshot이라는 객체로 전달
//        self.ref.observe(.value) { snapshot in
//            guard let value = snapshot.value as? [String: [String: Any]] else { return }
//
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: value)
//                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
//                let cardList = Array(cardData.values)
//                self.creditCardList = cardList.sorted { $0.rank < $1.rank }
//
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            } catch let error {
//                print("ERROR JSON parsing\(error)")
//            }
//        }
        
        //Firestore 읽기
        db.collection("creditCardList").addSnapshotListener{ snapshot, error in
            guard let document = snapshot?.documents else {
                print("ERROR Firestore fetching document \(String(describing: error))")
                return
            }
            
            self.creditCardList = document.compactMap { doc -> CreditCard? in
                do{
                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: [])
                    let creditCard = try JSONDecoder().decode(CreditCard.self, from: jsonData)
                    return creditCard
                } catch let error {
                    print("Error JSon parsing\(error)")
                    return nil
                }
            }.sorted { $0.rank < $1.rank }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell", for: indexPath)
                as? CardListCell else { return UITableViewCell() }
        
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        cell.cardImageView.kf.setImage(with: imageURL)
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = creditCardList[indexPath.row].name
 
        return cell
        
    }
        
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //상세 화면 전달
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailViewController = storyboard.instantiateViewController(identifier: "CardDetailViewController") as? CardDetailViewController else { return }
        
        detailViewController.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.show(detailViewController, sender: nil)
        
        //실시간 데이터베이스 쓰기
        //options 1
//        let cardID = creditCardList[indexPath.row].id
 //       ref.child("Item\(cardID)/isSelected").setValue(true)
        
        //options 2
//        ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self] snapshot
//            in
//            guard let self = self,
//                  let value = snapshot.value as? [String: [String: Any]],
//                  let key = value.keys.first else { return }
//
//            self.ref.child("\(key)/isSelected").setValue(true)
//        }
        
        //Firestore 쓰기
        //Option 1
        let cardID = creditCardList[indexPath.row].id
//        db.collection("creditCardList").document("card\(cardID)").updateData(["isSelected": true])
        
        //Option 2 경로 모를 때
        db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments { snapshot, _ in
            guard let document = snapshot?.documents.first else {
                print("error Firestore fetching document")
                return
            }
            document.reference.updateData(["isSelected": true])
        }
        
    }
 
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath : IndexPath )
     {
        if editingStyle == .delete {
            //실시간 데이터베이스 삭제
            //Options 1
//            let cardID = creditCardList[indexPath.row].id
//            ref.child("Item\(cardID)").removeValue()
            
//            //Options 2 경로 모룸
//            ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self]
//                snapshot in
//                guard let self = self,
//                      let value = snapshot.value as? [String: [String: Any]],
//                      let key = value.keys.first else {return}
//
//                self.ref.child(key).removeValue()
//                }
            
            //Firestore 삭제
            //Option1 경로를 알 때
            let cardID = creditCardList[indexPath.row].id
//            db.collection("creditCardList").document("card\(cardID)").delete()
            //Option2 경로를 모를 때
            db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments{ snapshot, _  in
                guard let document = snapshot?.documents.first else {
                    print("error")
                    return
                }
                document.reference.delete()
            }
            }
         
        }
    }
