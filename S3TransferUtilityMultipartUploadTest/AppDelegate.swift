//
//  AppDelegate.swift
//  S3TransferUtilityMultipartUploadTest
//
//  Created by kimitake.miyashita on 2019/02/12.
//  Copyright © 2019 kimitake.miyashita. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        AWSDDLog.sharedInstance.logLevel = .verbose
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)

        AWSS3TransferUtility.register(
            with: createServiceConfiguration(),
            transferUtilityConfiguration: createTransferUtilityConfiguration(),
            forKey: "test"
        )

        AWSS3TransferUtility.s3TransferUtility(forKey: "test")!.configuration.credentialsProvider.invalidateCachedTemporaryCredentials()

        runUpload()

        return true
    }

    struct Config {
        // enter appropriate region
        static let regionType = AWSRegionType.APNortheast1

        // enter appropriate identity pool id
        static let cognitoIdentityPoolId = ""

        // enter appropriate cognito identity id
        static let cognitoIdentityId = ""

        // enter appropriate cognito token
        static let cognitoToken = ""

        // enter upload destination s3 bucket with permitted by cognito
        static let s3Bucket = ""

        // enter upload destination s3 key permitted by cognito
        static let s3Key = ""
    }

    static func debugPrint(message: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        print("\(df.string(from: Date())) [debug print] - \(message)")
    }

    // Imitated this site "iOS - Swift" paragraph
    // https://docs.aws.amazon.com/cognito/latest/developerguide/developer-authenticated-identities.html
    class DeveloperCognitoCredentialProvider: AWSCognitoCredentialsProviderHelper {
        override func token() -> AWSTask<NSString> {
            AppDelegate.debugPrint(message: "token() - DeveloperCognitoCredentialProvider")
            return AWSTask<NSString>(result: nil).continueWith(block: { (_) -> AWSTask<NSString> in
                self.identityId = Config.cognitoIdentityId
                return AWSTask<NSString>(result: Config.cognitoToken as NSString)
            }) as! AWSTask<NSString>
        }
    }

    func createServiceConfiguration() -> AWSServiceConfiguration {
        let developerCognitoCredentialProvider = DeveloperCognitoCredentialProvider(
            regionType: Config.regionType,
            identityPoolId: Config.cognitoIdentityPoolId,
            useEnhancedFlow: true,
            identityProviderManager: nil
        )

        let cognitoCredentialProvider = AWSCognitoCredentialsProvider(
            regionType: Config.regionType,
            identityProvider: developerCognitoCredentialProvider
        )
        return AWSServiceConfiguration(
            region: Config.regionType,
            credentialsProvider: cognitoCredentialProvider
        )
    }

    func createTransferUtilityConfiguration() -> AWSS3TransferUtilityConfiguration {
        let transferUtilityConfiguration = AWSS3TransferUtilityConfiguration()
        transferUtilityConfiguration.multiPartConcurrencyLimit = 1
        transferUtilityConfiguration.retryLimit = 3
        return transferUtilityConfiguration
    }

    func runUpload() {
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 3.0)
            self.upload()
        }
    }

    func uploadDateString() -> String {
        let f = DateFormatter()
        f.timeStyle = .full
        f.dateStyle = .full
        return f.string(from: Date())
    }

    func upload() {
        AppDelegate.debugPrint(message: "upload() - start")
        let uploadDateString = self.uploadDateString()

        AppDelegate.debugPrint(message: "upload() - uploadDateString:\(uploadDateString)")

        let completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock = { (task, error) -> Void in
            AppDelegate.debugPrint(message: "upload() - completionHandler")
            self.runUpload()
        }
        AWSS3TransferUtility.s3TransferUtility(forKey: "test")!.uploadUsingMultiPart(
            data: uploadDateString.data(using: .utf8)!,
            bucket: Config.s3Bucket,
            key: Config.s3Key,
            contentType: "text/plain",
            expression: nil,
            completionHandler: completionHandler).continueWith { (task) -> Any? in
                AppDelegate.debugPrint(message: "upload() - uploadUsingMultiPart - continueWith:\(task)")
                if let status = task.result?.status {
                    AppDelegate.debugPrint(message: "upload() - uploadUsingMultiPart - continueWith - task.result.status:\(status.rawValue)")
                }
                return nil;
        }
    }
}
