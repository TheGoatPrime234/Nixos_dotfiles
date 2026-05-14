import QtQuick
import QtQuick.Layouts
import "./../color"

Item {
    id: root
    anchors.fill: parent
    clip: true
    property string text: ""
    property real iconWidth: 0

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spc2
        Item { Layout.preferredWidth: root.iconWidth + Theme.spc2 }
        Text {
            id: islandTextItem
            text: root.text
            font.family: Theme.fnt
            font.pixelSize: Theme.t1
            font.bold: true
            color: Theme.fg0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.rightMargin: (Theme.rad / 2)
        }
    }
}
