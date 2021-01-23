import UIKit

class SafeVI: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hitAPI(_for: "http://35.185.247.136:5000/processJson")
    }
        
    func hitAPI(_for URLString:String) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let url = URL(string: URLString)
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let dataTask = session.dataTask(with: url!) {
        data,response,error in
        guard let httpResponse = response as? HTTPURLResponse, let _ = data
            else {
                print("error: not a valid http response")
                return
            }
            switch (httpResponse.statusCode) {
                case 200:  //success response.
                    break
                case 400:
                    break
                default:
                    break
            }
        print(httpResponse)
       }
       dataTask.resume()
    }

}
