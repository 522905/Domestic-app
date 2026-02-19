/// Printer type enumerations for device identification
enum PrinterType {
  bluetooth, // MLP 360 and other Bluetooth printers
  sunmi, // Sunmi V2s built-in printer
}

/// Printer connection status
enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}
