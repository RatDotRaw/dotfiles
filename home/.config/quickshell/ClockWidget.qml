import Quickshell
import QtQuick

import "procs"

Text {
  anchors.centerIn: parent
  text: `${DateTime.time} • ${DateTime.shortDate}`
}