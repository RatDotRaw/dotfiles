// RoundCorner.qml
import QtQuick
import QtQuick.Shapes


Item {
    id: root

    enum Corner { TopLeft, TopRight, BottomLeft, BottomRight }
    property int corner: RoundCorner.Corner.TopLeft
    property int size: 12
    property color color: "black"

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors {
            top:    corner < 2  ? parent.top    : undefined  // TopLeft=0, TopRight=1
            bottom: corner >= 2 ? parent.bottom : undefined  // BottomLeft=2, BottomRight=3
            left:   corner % 2 === 0 ? parent.left  : undefined
            right:  corner % 2 === 1 ? parent.right : undefined
        }
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp
            strokeWidth: 0
            fillColor: root.color
            startX: corner % 2 === 0 ? 0 : root.size
            startY: corner < 2 ? 0 : root.size

            PathAngleArc {
                moveToStart: false
                centerX: root.size - sp.startX
                centerY: root.size - sp.startY
                radiusX: root.size
                radiusY: root.size
                startAngle: [180, 270, 90, 0][root.corner]
                sweepAngle: 90
            }
            PathLine { x: sp.startX; y: sp.startY }
        }
    }
}