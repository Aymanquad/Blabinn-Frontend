const os = require("os");

function getLocalIPAddress() {
  const interfaces = os.networkInterfaces();

  console.log("🌐 Network Interfaces:");

  for (const name of Object.keys(interfaces)) {
    const networkInterface = interfaces[name];

    for (const interface of networkInterface) {
      // Skip internal and non-IPv4 addresses
      if (interface.family === "IPv4" && !interface.internal) {
        console.log(`📡 ${name}: ${interface.address}`);

        // Check if it's likely a local network IP
        if (
          interface.address.startsWith("192.168.") ||
          interface.address.startsWith("10.") ||
          interface.address.startsWith("172.")
        ) {
          console.log(`✅ Recommended for Flutter: ${interface.address}`);
        }
      }
    }
  }

  console.log("\n📋 Instructions:");
  console.log(
    "1. Look for an IP address starting with 192.168.x.x, 10.x.x.x, or 172.x.x.x"
  );
  console.log("2. Update lib/core/config.dart with your actual IP address");
  console.log("3. Update blabbin-backend/src/config/index.js CORS settings");
  console.log("4. Restart both the backend server and Flutter app");
}

getLocalIPAddress();
