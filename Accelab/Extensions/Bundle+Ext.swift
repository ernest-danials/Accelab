//
//  Bundle+Ext.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-22.
//

import Foundation

extension Bundle {
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
    }
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    var versionBuildString: String {
        "\(appVersion) (\(appBuild))"
    }
}
