//
//  EpisodesViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/19/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class EpisodesViewController: UITableViewController, PlayerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        Feed.shared.load(self)
        Player.shared?.delegate = self
        if let link = Player.shared?.link {
            self.openDeepLink(link)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Feed.shared.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell

        cell.item = Feed.shared.items[indexPath.row]

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EpisodeDetailsSegue" {
            ViewController.shared?.menuVisible = false
            let controller = segue.destination as! EpisodeDetailsViewController
            var item: Feed.Item?
            if let identifier = sender as? String {
                //print("identifier = \(identifier)")
                item = Feed.shared.itemsByGUID[identifier]
            }
            if item == nil,
               let indexPath = self.tableView.indexPathForSelectedRow {
                item = Feed.shared.items[indexPath.row]
            }
            if item != nil {
                Player.shared?.link = nil
            }
            controller.item = item
        }
    }

    func player(_ player: Player, didOpen link: String) {
       self.openDeepLink(link)
    }

    func openDeepLink(_ link: String) {

        let url = URL(string: link)
        if url?.scheme == "allearsenglish" && url?.host == "episode",
           let path = url?.path {

            let pattern = "/(\\w+)"
            let expression = try? NSRegularExpression(pattern: pattern)
            if let regex = expression {

                let matches = regex.matches(in: path, options: [], range: NSMakeRange(0, path.characters.count))
                if matches.count == 1,
                   let match = matches.first {

                    if match.numberOfRanges > 1 {
                        let range = match.rangeAt(1)
                        let start = path.index(path.startIndex, offsetBy:range.location)
                        let end = path.index(start, offsetBy: range.length)
                        let identifier = path[start..<end]
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "EpisodeDetailsSegue", sender: identifier)
                        }
                    }

                }

            }

        }

    }

}
