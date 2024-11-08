
# PowerDNS Installation Script for Ubuntu 22.04

This script automates the installation and configuration of PowerDNS Authoritative Server with MySQL backend and API support on Ubuntu 22.04. It resolves potential conflicts, sets up SSL, and allows API access from specified IPs.

## Features

- Installs PowerDNS Authoritative Server (4.5.3+)
- Configures MySQL backend for PowerDNS
- Sets up PowerDNS API with secure API key
- Disables `systemd-resolved` to prevent port 53 conflicts
- Generates self-signed SSL certificates for secure API communication
- Allows API access from specified IPs and subnets

## Prerequisites

- Ubuntu 22.04
- Root access

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/Tazhys/powerdns-autoinstaller.git
   cd powerdns-autoinstaller
   ```

2. Make the script executable:
   ```bash
   chmod +x install_pdns.sh
   ```

3. Run the script:
   ```bash
   sudo ./install_pdns.sh
   ```

4. After the installation, credentials will be printed and saved to `pdns_credentials.txt`.

## Configuration

By default, the script allows API access from:
- `127.0.0.1` (localhost)
- `::1` (IPv6 localhost)
- `` (external subnet)
- `` (specific IP)

You can modify the `EXTERNAL_SUBNET` and `EXTRA_IP` variables in the script to suit your environment.

## Notes

- Ensure that port `8081` is open in your firewall for external API access.
- Use `curl` to test the API:
  ```bash
  curl -k -H "X-API-Key: <your_api_key>" https://<your-server-ip>:8081/api/v1/servers
  ```

## License

This project is licensed under the [MIT License](LICENSE).
