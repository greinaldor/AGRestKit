**Author**: _Adrien Greiner_ <br/>
**version**: _0.1.1_ <br/>
**ios version**: _7+_

# __Introduction__

The AGRestKit is a modern Objective-C framework for implementing **RESTful** web servivces client on iOS. It is designed to be simple and easy to use but also highly customizable.
Its modular architecture let you extend/replace core modules as : session management, server, response serialization, logging or object mapping.

By default, AGRestKit provides all needed modules to implement your own JSON API client, only few configuration is needed to make it up and running. 

The AGRestKit is built on top of AFNetworking and also massively use Bolts Framework. It has been designed to take profit, as much as possible, 
of available threads and manages its own pool of concurrent queues to dispatch the work load.

## Features

* Asynchronous / Synchronous REST requests
* Object Mapping
* Caching (___work in progress___, not available in the current version)
* User Session Management
* Network Monitoring
* Logging

## Core Architecture

The diagram below presents the core architecture of the framework. As a core principle, the framework is articulated around a
set of protocols that declare public interfaces for every subpart of the system. Each module has its own protocol. This way,
every module are decoupled from each other and can be easily replaced or extended.

The AGRest class is the public interface where the core modules can be accessed or replaced and the framework configured.
AGRest class holds a private instance of AGRestManager, this instance is initialized once `initializeRestWithBaseUrl:` is called.

The AGRestManager class is the central manager where all modules are accessed internally, each module is accessed through its own
serial access `dispatch_queue` ensuring thread-safety. The AGRestManager exposes its internal modules by conforming a set of
protocol that acts as 'provider'. AGRestManager owm a AGRestCore instance that is used as internal controllers provider.

The AGRestCore class is the internal manager for the AGRestManager class. It owns internal controllers which are susceptible to be used
by the AGRestManager or its submodules.

Each module holds a pointer to the shared AGRestManager instance as a dataSource. This way, each module can access other modules
internally in order to complete their tasks. For instance, the AGRestSessionController might access the AGRestSessionStore through its
dataSource.

<div style="display:block; vertical-align:middle; margin: 0 auto;">
    <img style="display: block; margin: 0 auto;" src="docs/docs/AGRestKit_Architecture.jpg">
</div>

## Dependencies

* [AFNetworking](https://github.com/AFNetworking/AFNetworking)
* [Bolts Framework](https://github.com/BoltsFramework/Bolts-iOS)
* [OCMapper](https://github.com/aryaxt/OCMapper)
* [Valet](https://github.com/square/Valet)
* [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)

# __Getting Started__

## Installation

Install the SDK from the private pod and add those line to your _Podfile_ :

~~~
source 'git@bitbucket.org:socialsuperstore/ios-private-specs.git'

pod 'AGRestKit', :git => 'git@bitbucket.org:socialsuperstore/AGRestKit-ios-pod.git', :tag => '0.1.1'
~~~

## Initialize the SDK

Before using AGRestKit you have to initialize it with your API base url :

~~~
[AGRest initializeRestWithBaseUrl:<<API URL>>];
~~~

## Create your first model

## Send your first request
