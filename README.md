# Valvoa

<p align="center">
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
    <a href="https://twitter.com/omnijarstudio">
        <img src="https://img.shields.io/badge/contact-@omnijarstudio-blue.svg?style=flat" alt="Twitter: @omnijarstudio" />
    </a>
    <a href="https://img.shields.io/badge/os-macOS-green.svg?style=flag">
        <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flag" alt="macOS" />
    </a>
    <a href="https://img.shields.io/badge/os-linux-green.svg?style=flag">
        <img src="https://img.shields.io/badge/os-linux-green.svg?style=flag" alt="Linux" />
    </a>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat" alt="License: MIT" />
    </a>
</p>

**Valvoa** is a Swift project that provides a brokered agent for providing metrics for, and monitoring, 
Swift projects. Although specifically built for [Naamio](https://gitlab.com/Omnijar/Naamio), it works 
just as well on a variety of different Swift projects.

Valvoa instruments the Swift runtime for performance monitoring, providing the monitoring data 
programatically via an API.

Valvoa provides the following built-in data collection sources:

 Source             | Description
:-------------------|:-------------------------------------------
 Environment        | Machine and runtime environment information
 CPU                | Process and system CPU
 Memory             | Process and system memory usage
 Latency            | Dispatch Queue latency

 SwiftMetricsKitura adds the additional collection source:

 Source             | Description
:-------------------|:-------------------------------------------
 HTTP               | HTTP metric information


## Getting Started
### Prerequisites

The Valvoa agent supports the following runtime environments:

* **Swift 4** on:
  * 64-bit runtime on Linux (Ubuntu 16.04, 17.10)
  * 64-bit runtime on macOS (x64)

<a name="install"></a>
### Installation
Metrics for Swift can be installed by adding a dependency into your `Package.swift` file:

```swift
dependencies: [
   .Package(url: "https://github.com/Naamio/Valvoa.git", majorVersion: #, minor: #),
]
```

Swift Package manager will automatically clone the code required and build it during compilation of your program:
  * Linux: `swift build`
  * macOS: `swift build -Xlinker -lc++`

<a name="config"></a>
### Configuring Valvoa
Once **Valvoa** is added as a dependency to your Swift application, you should find a configuration file inside the `.build` folder, `.build/checkouts/Valvoa.git--<id>/valvoa.properties` (or the `Packages` directory for older versions of Swift, `Packages/Valvoa-<version>/valvoa.properties`). This is used to configure connection options, logging and data source options.

Valvoa will attempt to load `swiftmetrics.properties` from one of the following locations (in order):

1. The current working directory.
2. The `.build/checkouts/Valvoa.git--<id>` directory (or `Packages/Valvoa-<version>` for older versions of Swift).

Please note that the default configuration has minimal logging enabled.

## Running Valvoa
<a name="run-local"></a>
### Modifying your application

To load `Valvoa` and get the base monitoring API, add the following to the start-up code for your application:
```swift
import Valvoa

let valvoa = try Valvoa()
let monitoring = valvoa.monitor()
```

If you would like to monitor Kitura HTTP data as well, then use the following instead:
```swift
import Valvoa
import ValvoaHTTP

let sm = try Valvoa()
ValvoaHTTP(agent: valvoa)
let monitoring = valvoa.monitor()
```

### Prometheus Support

To use SwiftMetrics to provide a [prometheus](https://prometheus.io/) endpoint, you add the following code to your application
```swift
import Valvoa
import ValvoaPrometheus

// Enable Valvoa Monitoring
let sm = try Valvoa()   

// Pass Valvoa to ValvoaPrometheus
let valvoaPrometheus = try ValvoaPrometheus(agent: valvoa)
```

By default, ValvoaPrometheus will provide the prometheus endpoint under `http://<hostname>:<port>/metrics`

The port being used is logged to the console when your application starts:

 * ValvoaPrometheus : Starting on port 8080

### Valvoa Agent

Valvoa() returns the Valvoa Agent - this runs parallel to your code and receives and emits data about your application to any connected clients. The `valvoa.monitor()` call returns a Valvoa Local Client, connected to the Agent `valvoa` over a local connection.

You can then use the monitoring object to register callbacks and request information about the application:
```swift
monitoring.on({ (env: InitData) in
   for (key, value) in env {
      print("\(key): \(value)\n")
   }
})

func processCPU(cpu: CPUData) {
   print("\nThis is a custom CPU event response.\n cpu.timeOfSample = \(cpu.timeOfSample),\n cpu.percentUsedByApplication = \(cpu.percentUsedByApplication),\n cpu.percentUsedBySystem = \(cpu.percentUsedBySystem).\n")
}

monitoring.on(processCPU)
```

In order to monitor your own custom data, you need to implement a struct that implements 
the base Valvoa data protocol, SMData. This has no required fields so you can put in just 
the data you're interested in.
```swift
private struct SnoozeData: ValvoaData {
   let cycleCount: Int
}

private func snoozeMessage(data: SnoozeData) {
   print("\nAlarm has been ignored for \(data.cycleCount) seconds!\n")
}

monitoring.on(snoozeMessage)

valvoa.emitData(SnoozeData(cycleCount: 40))

//prints "Alarm has been ignored for 40 seconds!"
```

<a name="api-doc"></a>
## API Documentation

### Valvoa.start()
Starts the Valvoa Agent. If the agent is already running this function does nothing.

### ValvoaMetrics.stop()
Stops the Valvoa Metrics Agent. If the agent is not running this function does nothing.

### ValvoaMetrics.setPluginSearch(toDirectory: URL)
Sets the directory that Valvoa Metrics will look in for data source / connector plugins.

### ValvoaMetrics.monitor() -> ValvoaMonitor
Creates a Valvoa Metrics Local Client instance, connected to the Valvoa Metrics Agent specified by 'ValvoaMetrics'. This can subsequently be used to get environment data and subscribe to data generated by the Agent. This function will start the Valvoa Metrics Agent if it is not already running.

### ValvoaMetrics.emitData<T: ValvoaData( _: T)
Allows you to emit custom Data specifying the type of Data as a string. Data to pass into the event must implement the ValvoaMetricsData protocol.

### ValvoaMonitor.getEnvironmentData() -> [ String : String ]
Requests a Dictionary object containing all of the available environment information for the running application. If called before the 'initialized' event has been emitted, this will contain either incomplete data or no data.

### ValvoaMonitor.on<T: ValvoaData>((T) -> ())
If you supply a closure that takes either a *[pre-supplied API struct](#api-structs)* or your own custom struct that implements the ValvoaData protocol,  and returns nothing, then that closure will run when the data in question is emitted.

### ValvoaMetricsHTTP(agent: ValvoaMetrics) (when importing ValvoaMetricsHTTP)
Creates a ValvoaMetricsHTTP instance, which will monitor HTTP metrics and emit them via the ValvoaMetrics instance specified.

<a name="api-structs"></a>
## API Data Structures

All of the following structures implement the SMData protocol to identify them as available to be used by ValvoaMetrics.
```swift
public protocol ValvoaMetricsData {
}
```

### CPU data structure
Emitted when a CPU monitoring sample is taken.
* `public struct CPUData: SMData`
    * `timeOfSample` (Int) the system time in milliseconds since epoch when the sample was taken.
    * `percentUsedByApplication` (Float) the percentage of CPU used by the Swift application itself. This is a value between 0.0 and 1.0.
    * `percentUsedBySystem` (Float) the percentage of CPU used by the system as a whole. This is a value between 0.0 and 1.0.

### Memory data structure
Emitted when a memory monitoring sample is taken.
* `public struct MemData: SMData`
    * `timeOfSample` (Int) the system time in milliseconds since epoch when the sample was taken.
    * `totalRAMOnSystem` (Int) the total amount of RAM available on the system in bytes.
    * `totalRAMUsed` (Int) the total amount of RAM in use on the system in bytes.
    * `totalRAMFree` (Int) the total amount of free RAM available on the system in bytes.
    * `applicationAddressSpaceSize` (Int) the memory address space used by the Swift application in bytes.
    * `applicationPrivateSize` (Int) the amount of memory used by the Swift application that cannot be shared with other processes, in bytes.
    * `applicationRAMUsed` (Int) the amount of RAM used by the Swift application in bytes.

### HTTP data structure (when including SwiftMetricsKitura)
Emitted when an HTTP monitoring sample is taken.
* `public struct HTTPData: SMData`
    * `timeOfRequest` (Int) the system time in milliseconds since epoch when the request was made.
    * `url` (String) the request url.
    * `duration` (Double) the duration in milliseconds that the request took.
    * `statusCode` (HTTPStatusCode) the HTTP status code of the request.
    * `requestMethod` (String) the method {GET SET} of the request.

### Initialized data structure
Emitted when all expected environment samples have been received, signalling a complete set of environment variables is available for ValvoaMonitor.getEnvironmentData().
* `public struct InitData: ValvoaMetricsData`
    * `data` ([String: String] Dictionary) of environment variable name:value pairs. The contents vary depending on system.

### Environment data structure
Emitted when an environment sample is taken. The Dictionary obtained with this data may not represent the complete set of environment variables.
* `public struct EnvData: ValvoaMetricsData`
    * `data` ([String: String] Dictionary) of environment variable name:value pairs. The contents vary depending on system.

### Latency data structure
Emitted when a Latency sample is taken.
* `public struct LatencyData: ValvoaMetricsData`
    * `timeOfSample` (Int) the system time in milliseconds since epoch when the sample was taken.
    * `duration` (Double) the duration the sample waited in the dispatch queue to be executed.

## Samples

There are two samples available:
* `commonSample` demonstrates how to get data from the common data types, using the API.
* `emitSample` demonstrates the use of Custom Data emission and collection.

To use either, navigate to their directory and issue `swift build` (on macOS, `swift build -Xlinker -lc++`)

### Checking Valvoa Metrics has started
By default, a message similar to the following will be written to console output when Valvoa Metrics starts:

`[Fri Aug 21 09:36:58 2015] com.ibm.diagnostics.healthcenter.loader INFO: Valvoa Metrics 1.0.1-201508210934 (Agent Core 3.0.5.201508210934)`

### Error "Failed to open library .../libagentcore.so: /usr/lib64/libstdc++.so.6: version `GLIBCXX_3.4.15' not found"
This error indicates there was a problem while loading the native part of the module or one of its dependent libraries. `libagentcore.so` depends on a particular (minimum) version of the C runtime library and if it cannot be found this error is the result.

Check:

* Your system has the required version of `libstdc++` installed. You may need to install or update a package in your package manager. If your OS does not supply a package at this version, you may have to install standalone software - consult the documentation or support forums for your OS.
* If you have an appropriate version of `libstdc++`installed, ensure it is on the system library path, or use a method (such as setting `LD_LIBRARY_PATH` environment variable on Linux) to add the library to the search path.

## License
This project is released under an MIT open source license.  

## Versioning scheme
This project uses a semver-parsable X.0.Z version number for releases, where X is incremented for breaking changes to the public API described in this document and Z is incremented for bug fixes **and** for non-breaking changes to the public API that provide new function.

## Questions or feedback?

Feel free to [open an issue](https://github.com/Naamio/valvoa/issues/new), or find us [@omnijarstudio on Twitter](https://twitter.com/omnijarstudio).

