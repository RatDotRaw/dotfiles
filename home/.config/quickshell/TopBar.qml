import Quickshell
import Quickshell.Io
import QtQuick

import "modules"

Scope {
  id: root
  property int barHeight: 30

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: barHeight

        ClockWidget {}

        PanelWindow {
          id: leftCorner
          screen: modelData
          width: barHeight/2; height: barHeight/2
          color: "transparent"

          anchors { top: true; left: true }
          margins { top: 0; left: 0 }

          RoundCorner {
              anchors.fill: parent
              corner: RoundCorner.Corner.TopLeft  // flipped!
              size: parent.width
              color: '#ffffff'
          }
        }
        PanelWindow {
          id: rightCorner
          screen: modelData
          width: barHeight/2; height: barHeight/2
          color: "transparent"

          anchors { top: true; right: true }
          margins { top: 0; left: 0 }

          RoundCorner {
              anchors.fill: parent
              corner: RoundCorner.Corner.TopRight  // flipped!
              size: parent.width
              color: '#ffffff'
          }
        }
      }
      
    }
  }
}