// with this line our type becomes a Singleton
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
  id: root

  property var clock: SystemClock {
    precision: SystemClock.Seconds
  }

  property string time: Qt.formatDateTime(clock.date, "hh:mm")
  property string shortDate: Qt.formatDateTime(clock.date, "dd/MM")
  property string date: Qt.formatDateTime(clock.date, "dd/MM/yyyy")
  property string longDate: Qt.formatDateTime(clock.date, "dddd, dd/MM")
  property string collapsedCalendarFormat: Qt.formatDateTime(clock.date, "dddd, dd MMMM")

  // Process {
  //   id: dateProc
  //   command: ["date"]
  //   running: true

  //   stdout: StdioCollector {
  //     onStreamFinished: root.time = this.text
  //   }
  // }

  Timer {
    interval: 500
    repeat: true
    running: true
    // onTriggered: dateProc.running = true
    onTriggered: {

    }
  }
}