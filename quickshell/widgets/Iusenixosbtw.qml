import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import "./../color"
import "./../windows"
import "./../radialmenus"

Rectangle { // Icon Widget Root
	id: iuseNixosbtw
	anchors {
		verticalCenter: parent.verticalCenter
	}
	implicitHeight: Theme.h3 
	implicitWidth: iuseNixosbtwtext.implicitWidth + Theme.impW 
	radius: Theme.rad 
	color: Theme.trans 
	//
	Text { //Icon
		id: iuseNixosbtwtext
		anchors.centerIn: parent 
		text: "󱄅"
		color: Theme.fg0
		font {
			pixelSize: 35
			bold: true 
			family: Theme.fnt 
		}
	}
	MouseArea {
	    anchors.fill: parent
	    onClicked: gearwheel.visible = !gearwheel.visible
	}
	Radialmenu {
	    id: gearwheel 
	    visible: false 
	}
}
