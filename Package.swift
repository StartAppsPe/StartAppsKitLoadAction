import PackageDescription

let package = Package(
    name: "StartAppsKitLoadAction",
    dependencies: [
        .Package(url: "https://github.com/StartAppsPe/StartAppsKitLogger.git", versions: Version(0,1,0)..<Version(1, .max, .max)),
        .Package(url: "https://github.com/StartAppsPe/StartAppsKitExtensions.git", versions: Version(1,0,0)..<Version(1, .max, .max))
    ]
)
