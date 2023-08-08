//
//  TaoBaoAuthorizedManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/16.
//  参考资料 https://cloud.tencent.com/developer/ask/sof/87370
// https://www.cnblogs.com/lxlx1798/articles/14259055.html
/**
    清除WKWebView的缓存
    在磁盘缓存上。
    WKWebsiteDataTypeDiskCache,
    
    html离线Web应用程序缓存。
    WKWebsiteDataTypeOfflineWebApplicationCache,
    
    内存缓存。
    WKWebsiteDataTypeMemoryCache,
    
    本地存储。
    WKWebsiteDataTypeLocalStorage,
    
    Cookies
    WKWebsiteDataTypeCookies,
    
    会话存储
    WKWebsiteDataTypeSessionStorage,
    
    IndexedDB数据库。
    WKWebsiteDataTypeIndexedDBDatabases,
    
    查询数据库。
    WKWebsiteDataTypeWebSQLDatabases
    */
import UIKit
import WebKit

class TaoBaoAuthorizedManager: NNBaseView {
    private var callback: ((Bool)->Void)?
    public var cookieArray: [HTTPCookie] = []
    public var storage: HTTPCookieStorage {
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .always
        return storage
    }
    public var getAddress = false
    public var zhifubao = true
    public var taobaoHttp = true
    public var aliIndex = false
    public var scanNum = 0
    public let getHtmlJS = "var currentUrl = window.location.href;" +
    "var body = document.getElementsByTagName('html')[0].outerHTML;" +
    "window.webkit.messageHandlers.showHtml(currentUrl,body);"
    private let myUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    public var delayTime: DispatchTime = .now() + .milliseconds(100)
    // MARK: Lifecycle
    deinit {
        log.info("TaoBaoAuthorizedManager\(#file)" + "\(#function)")
        
    }
    
    convenience init(callback: @escaping ((Bool)->Void)) {
        self.init()
        self.callback = callback
    }
    
    override func nn_initViews (){
        removeALLWebsiteDataStore()
    }
    
    private func initViews (){
        self.addSubview(webView)
    }
    
    private func initDatas() {
        let linkUrl = "https://login.taobao.com/"
        var request =  URLRequest(url: URL(string: linkUrl)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.setValue("User-Agent", forHTTPHeaderField: myUA)
        webView.load(request)
        HUD.wait(info: "跳转中...")
    }
    
    private func addLayoutSubviews (){
        webView.frame = .zero
    }
    
    // MARK: Event Response
    
    // MARK: Public Method
    
    // MARK: Private Method
    private func removeALLWebsiteDataStore(){
        let store: WKWebsiteDataStore = WKWebsiteDataStore.default()
        let dataTypes: Set<String> = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: dataTypes, completionHandler: { (records: [WKWebsiteDataRecord]) in
            store.removeData(ofTypes: dataTypes, for: records, completionHandler: {})
            self.initViews()
            self.initDatas()
            self.addLayoutSubviews()
        })
    }
    
    private func removeSomeWebsiteDataStore(){
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
    }
    
    // MARK: Set
    
    // MARK: Get
    internal lazy var webView: WKWebView = {
        let wkUController: WKUserContentController = WKUserContentController()
        wkUController.add(self, name: "ajaxDone")
        wkUController.add(self, name: "showHtml")
        wkUController.add(self, name: "upMyZfbInfo")
        wkUController.add(self, name: "upBill")
        wkUController.add(self, name: "accreditPage")
        wkUController.add(self, name: "tbAuthenticationName")
        let config = WKWebViewConfiguration()
        config.userContentController = wkUController
        let view = WKWebView(frame: .zero, configuration: config)
        view.customUserAgent = myUA
        view.navigationDelegate = self
        return view
    }()
}

extension TaoBaoAuthorizedManager: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        log.info("message.name:\(message.name)\nbody:\(message.body)")
//        if message.name == "log",
//           let body = message.body as? String{
//            let dic = body.toDictionary()
//            if let content = dic?["content"] as? [String: Any],
//               let data = content["data"] as? [String: Any]{
//                if let ck = data["ck"] as? String{
//                    let linkUrl = "taobao://login.taobao.com/qrcodeCheck.htm?lgToken=\(ck)&tbScanOpenType=Notification"
//                    UIApplication.shared.open(URL(string: linkUrl)!)
//                    HUD.clear()
//                } else if let redirectUrl = data["redirectUrl"] as? String,
//                          redirectUrl.hasPrefix("https://i.taobao.com/my_taobao.htm"){
//                    if #available(iOS 14.0, *) {
//                        userContentController.removeAllScriptMessageHandlers()
//                    } else {
//                        userContentController.removeScriptMessageHandler(forName: "log")
//                    }
//                    self.callback?(true)
//                }
//            }
//        }
        if message.name == "ajaxDone",
           let dic = message.body as? [String: Any],
           let body = dic["responseText"] as? String {
            ajaxDone(body: body)
        } else if message.name == "showHtml",
                  let dic = message.body as? [String: Any],
                  let body = dic["responseText"] as? String {
            let url = dic["url"] as? String
            showHtml(url: url, body: body)
        } else if message.name == "upMyZfbInfo",
                  let dic = message.body as? [String: Any] {
            let url = dic["url"] as? String
            let t1 = dic["t1"] as? String
            let t2 = dic["t2"] as? String
            let type = dic["type"] as? Int
            upMyZfbInfo(url: url, t1: t1 ?? "", t2: t2 ?? "", type: type ?? 0)
        } else if message.name == "upBill",
                  let dic = message.body as? [String: Any],
                  let url = dic["url"] as? String {
            let body = dic["responseText"] as? String
            let currMonth = dic["currMonth"] as? Int
            upBill(url: url, body: body ?? "", sizeMonth: "\(currMonth ?? 0)")
        } else if message.name == "accreditPage",
                  let dic = message.body as? [String: Any],
                  let pageUrl = dic["responseText"] as? String {
            let arr = pageUrl.components(separatedBy: "=")
            if let pageStr = arr.last, let page = Int(pageStr) {
                getAccreditData(webView: webView, totalPage: page)
            }
        } else if message.name == "tbAuthenticationName",
                  let dic = message.body as? [String: Any],
                  let name = dic["name"] as? String,
                  let idCard = dic["idCard"] as? String{
            let url = dic["url"] as? String
            tbAuthenticationName(url: url, name: name, idCard: idCard)
        }
    }
    
    func ajaxDone(body: String) {
        let content = body.toDictionary()
        if let content = content?["content"] as? [String: Any] {
            if let data = content["data"] as? [String: Any],
               let ck = data["ck"] as? String {
                HUD.wait(info: "授权中...")
                let linkUrl = "taobao://login.taobao.com/qrcodeCheck.htm?lgToken=\(ck)&tbScanOpenType=Notification"
                UIApplication.shared.open(URL(string: linkUrl)!)
            }
        }
    }
}

extension TaoBaoAuthorizedManager: WKNavigationDelegate{
  
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.hasSuffix("https://login.taobao.com/") == true{
            let injectionJSString = "(function() {\n" +
            "    var origOpen = XMLHttpRequest.prototype.open;var url = arguments[1];\n"  +
            "    XMLHttpRequest.prototype.open = function() {\n"  +
            "        this.addEventListener('load', function() {\n"  +
            "            var data = {\"url\":url,\"responseText\":this.responseText};  \n" +
            "            window.webkit.messageHandlers.ajaxDone.postMessage(data);  \n" +
            "        });\n"  +
            "        origOpen.apply(this, arguments);\n"  +
            "    };\n"  +
            "})();"
            
            webView.evaluateJavaScript(injectionJSString){ data, error in}
            /// 点击二维码
            let clickJs = "document.getElementsByClassName(\"icon-qrcode\")[0].click();"
            webView.evaluateJavaScript(clickJs){ data, error in }
        }
        let absoluteString = webView.url?.absoluteString
        DispatchQueue.global().async { [weak self] in
            if absoluteString?.hasPrefix("https://i.taobao.com/my_taobao.htm") == true {
                DispatchQueue.main.async { [weak self] in
                    self?.loginSuccess(webView: webView, absoluteString: absoluteString)
                    self?.getOrders(webView: webView, absoluteString: absoluteString)
                    self?.getAddress(webView: webView, absoluteString: absoluteString)
                    HUD.clear()
                    self?.callback?(true)
                }
            }
            if absoluteString?.hasPrefix("https://i.taobao.com/my_taobao.htm") == true,
                self?.getAddress == true {
                Thread.sleep(forTimeInterval: 0.1)
                // 所有操作都完成后，进行跳转支付宝
                let removeBlankJS = "var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','_self');}"
                
                self?.evaluateJavaScript(removeBlankJS )
                Thread.sleep(forTimeInterval: 0.5)
                
                let gotoAliJS = "document.getElementById(\"J_MyAlipayInfo\").getElementsByTagName(\"a\")[1].click()"
                self?.evaluateJavaScript(gotoAliJS)
            }
            
            self?.getTbfoot(webView: webView, absoluteString: absoluteString)
            self?.getTbAuthenticationName(webView: webView, absoluteString: absoluteString)
            self?.getTbHome(webView: webView, absoluteString: absoluteString)
            self?.getWSMsg(webView: webView, absoluteString: absoluteString)
            self?.getWSHome(webView: webView, absoluteString: absoluteString)
            self?.getWSRepayHome(webView: webView, absoluteString: absoluteString)
            self?.getWSRepayRecord(webView: webView, absoluteString: absoluteString)
            self?.getSwitchPersonal(webView: webView, absoluteString: absoluteString)
            self?.getZFBAccount(webView: webView, absoluteString: absoluteString)
            self?.getYebPurchase(webView: webView, absoluteString: absoluteString)
            self?.getRecordStandard(webView: webView, absoluteString: absoluteString)
            self?.getAliBaseMsg(webView: webView, absoluteString: absoluteString)
            self?.getMdeductAndToken(webView: webView, absoluteString: absoluteString)
            self?.getAuthTokenManage(webView: webView, absoluteString: absoluteString)
            self?.getAliMessager(webView: webView, absoluteString: absoluteString)
            self?.getÅssetBankList(webView: webView, absoluteString: absoluteString)
            self?.getAlipayError(webView: webView, absoluteString: absoluteString)
            self?.getCheckSecurity(webView: webView, absoluteString: absoluteString)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let property = ["error": error.localizedDescription,
                        "url": webView.url?.absoluteString ?? ""]
        TrackManager.default.track(.TBErrorMessage, property: property)
    }
}
