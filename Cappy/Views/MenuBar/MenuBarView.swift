import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            Button(action: appState.startRegionCapture) {
                HStack {
                    Text("Capture Region")
                    Spacer()
                    Text("⇧⌘5")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }

            Button(action: appState.startFullScreenCapture) {
                HStack {
                    Text("Capture Full Screen")
                    Spacer()
                    Text("⇧⌘6")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }

            Button(action: appState.startWindowCapture) {
                HStack {
                    Text("Capture Window")
                    Spacer()
                    Text("⇧⌘7")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }

            Divider()

            Button(action: appState.openScreenshotsFolder) {
                HStack {
                    Text("Open Screenshots Folder")
                    Spacer()
                }
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
                HStack {
                    Text("Keyboard Shortcuts")
                    Spacer()
                }
            }

            Button(action: {
                NSApplication.shared.orderFrontStandardAboutPanel()
            }) {
                HStack {
                    Text("About Cappy")
                    Spacer()
                }
            }

            Divider()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Text("Quit Cappy")
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }
        }
    }
}
