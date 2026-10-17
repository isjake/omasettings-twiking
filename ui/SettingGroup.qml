import QtQuick
import qs.Commons
import qs.Ui
import "." as Local

Column {
  id: group
  property string title: ""
  property string note: ""
  // Everything under a heading is stepped in from it, so which rows belong to
  // which heading is a matter of looking rather than of reading.
  property real indent: title !== "" ? Style.space(14) : 0
  default property alias content: groupContent.data

  width: parent ? parent.width : 0
  spacing: Style.space(10)

  // A group whose rows have all been filtered away goes with them, heading
  // and all, or the page fills with headings over nothing.
  property var nav: null
  Component.onCompleted: {
    var node = group.parent
    while (node) {
      if (node.searching !== undefined) { group.nav = node; break }
      if (node.app !== undefined && node.app !== null && node.app.searching !== undefined) {
        group.nav = node.app
        break
      }
      node = node.parent
    }
  }

  readonly property bool searchEmpty: {
    if (!group.nav || group.nav.searching !== true) return false
    var kids = groupContent.children
    for (var i = 0; i < kids.length; i++) {
      // Asked of the row itself, never of its `visible`. QML's `visible` is
      // *effective* visibility — false whenever any ancestor is hidden — so a
      // group deciding its own `visible` from its children's `visible` reads
      // a value that depends on the answer. Hiding the window hid every row,
      // every group under a search then counted itself empty, and reopening
      // the window drew the page blank until the search was cleared.
      //
      // `searchHidden` is the row's own verdict on the search term and
      // depends on nothing above it. `implicitHeight` and not `height` for the
      // same reason: a laid-out height is zero while the group is hidden. A
      // Repeater sits among the rows it made and asks for no height, which is
      // what keeps it from counting as content.
      if (kids[i].searchHidden !== true && kids[i].implicitHeight > 0) return false
    }
    return true
  }

  visible: !searchEmpty

  Text {
    textFormat: Text.PlainText
    visible: group.title !== ""
    text: group.title
    color: Local.Palette.foreground
    font.family: Local.Palette.fontFamily
    font.pixelSize: Style.font.subtitle
    font.bold: true
  }

  Text {
    textFormat: Text.PlainText
    visible: group.note !== ""
    x: group.indent
    width: group.width - group.indent
    text: group.note
    wrapMode: Text.WordWrap
    color: Local.Palette.muted
    font.family: Local.Palette.fontFamily
    font.pixelSize: Style.font.caption
  }

  Column {
    id: groupContent
    x: group.indent
    width: group.width - group.indent
    spacing: Style.space(12)
  }
}
