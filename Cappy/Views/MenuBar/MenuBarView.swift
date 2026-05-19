import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            Button(action: appState.startRegionCapture) {
                Label("Capture Region", systemImage: "selection.pin.in.out")
            }

            Button(action: appState.startFullScreenCapture) {
                Label("Capture Full Screen", systemImage: "macwindow.on.rectangle")
            }

            Button(action: appState.startWindowCapture) {
                Label("Capture Window", systemImage: "macwindow")
            }

            Divider()

            Button(action: appState.openScreenshotsFolder) {
                Label("Open Screenshots Folder", systemImage: "folder")
            }

            Divider()

            Button(action: {
                let alert = NSAlert()
                alert.messageText = "Keyboard Shortcuts"
                alert.informativeText = """
                Capture Region    ⇧⌘5
                Capture Full Screen   ⇧⌘6
                Capture Window     ⇧⌘7
                Open Folder        —
                Quit Cappy         ⌘Q

                Editor:
                Undo    ⌘Z
                Redo    ⇧⌘Z
                Save    ⌘S
                """
                alert.runModal()
            }) {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
            }

            Button(action: {
                NSApplication.shared.orderFrontStandardAboutPanel()
            }) {
                Label("About Cappy", systemImage: "info.circle")
            }

            Divider()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit Cappy", systemImage: "power")
            }
        }
    }
}
