// MARK: - Application Main Entry Point
/// This is the entry point called by ESP-IDF bootloader
/// Using @_cdecl to generate a C-compatible symbol
@_cdecl("app_main")
func app_main() {
    print("Hi!")
}
