# Yamcs TrySpace

This repository is a fork of the [Yamcs Quickstart](https://github.com/yamcs/quickstart).

This repository holds the source code to start a basic Yamcs application that monitors a simulated spacecraft in low earth orbit.

You may find it useful as a starting point for your own project.


## Prerequisites

* Java 17+
  * For Ubuntu WSL
    * sudo apt install openjdk-17-jdk
    * Add the following to your `~/.bashrc` file:
      * export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
      * export PATH=$JAVA_HOME/bin:$PATH
* Linux x64/aarch64, macOS x64/aarch64, or Windows x64

A copy of Maven is also required, however this gets automatically downloaded an installed by using the `./mvnw` shell script as detailed below.


## Running Yamcs

Here are some commands to get things started:

Compile this project:

    ./mvnw compile

Start Yamcs on localhost:

    ./mvnw yamcs:run

Same as yamcs:run, but allows a debugger to attach at port 7896:

    ./mvnw yamcs:debug
    
Delete all generated outputs and start over:

    ./mvnw clean

This will also delete Yamcs data. Change the `dataDir` property in `yamcs.yaml` to another location on your file system if you don't want that.


## Telemetry

To start pushing CCSDS packets into Yamcs, run the included Python script:

    python simulator.py

This script will send packets at 1 Hz over UDP to Yamcs. There is enough test data to run for a full calendar day.

The packets are a bit artificial and include a mixture of HK and accessory data.


## Telecommanding

This project defines a few example CCSDS telecommands. They are sent to UDP port 10025. The simulator.py script listens to this port. Commands  have no side effects. The script will only count them.


## Bundling

Running through Maven is useful during development, but it is not recommended for production environments. Instead bundle up your Yamcs application in a tar.gz file:

    ./mvnw package
