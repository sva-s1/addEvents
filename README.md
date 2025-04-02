# Agentless POC for SentinelOne Singularity Data Lake

![SDL Agentless POC](https://img.shields.io/badge/SDL_Agentless-POC-blue?style=for-the-badge&logo=sentinelone)
![syslog RFC 3164 & 5424](https://img.shields.io/badge/Syslog-RFC_3164_&_5424-lightgrey?style=for-the-badge)
![1Password Compatible](https://img.shields.io/badge/1Password-Compatible-blue?style=for-the-badge)
![Bash Script](https://img.shields.io/badge/Bash-Script-green?style=for-the-badge&logo=gnu-bash)

## 🔥 Why This Exists

Many **existing or prospective SentinelOne customers** want an **agentless alternative** to quickly validate **log ingestion** in **non-production** environments (e.g., POC/POV, Dev, QA). Rather than waiting on **change control** or coordinating with OS teams to install the [S1 Collector](#s1-collector-vs-api-ingestion), this script sends events **directly** to the **same `addEvents` API** used by the **S1 Collector**—just **without** the need to install an agent.

> **Recommended Use Case**: Accelerate your **POC/POV** or other **pre-production** testing scenarios. Quickly **validate ingestion flows** without additional software overhead—so you can **iterate faster**, gather feedback, and make decisions sooner.

---

## 🎯 Key Features

- **Interactive Region Selection**: Choose the correct **Singularity Data Lake** ingest URL (us1, ca1, eu1, ap1, etc.).
- **Syslog RFC Choice**: Pick either **RFC 3164** or **RFC 5424**-style event generation.
- **Transformer-Themed Hostnames**: Randomly cycles through “Autobot” or “Decepticon” hostnames to keep your logs fun.
- **1Password or .env Support**: Optionally fetch your **SentinelOne API key** from a **1Password vault** (via `op read`), or supply it directly in a `.env` file.
- **Simple Search Tagging**: Automatically adds a `search_tag` you can use to find events in **SentinelOne’s** console.

---

## 📂 Prerequisites

1. **[curl](https://curl.se/)** for sending HTTP requests.
2. **[uuidgen](https://linux.die.net/man/1/uuidgen)** (or fallback to `/proc/sys/kernel/random/uuid`).
3. **Bash** (the script uses `#!/bin/bash`).
4. (Optional) **[1Password CLI](https://developer.1password.com/docs/cli/)** if you want to pull your SentinelOne token from a 1Password vault.

---

## ⚙️ Setup & Configuration

1. **Clone This Repository**:

   ```sh
   git clone https://github.com/sva-s1/addEvents.git
   cd addEvents
   ```

2. **Create a `.env` File** in the project folder. For example:

   ```bash
   # If using 1Password:
   SDL_LOG_ACCESS_WRITE_KEY="op://My1PasswordVault/MySDLKeyRecord/SDL_LOG_ACCESS_WRITE_KEY"

   # Or, if using a direct token (no 1Password integration):
   # SDL_LOG_ACCESS_WRITE_KEY="YOUR_ACTUAL_SDL_TOKEN"
   ```

   > **Important**: Make sure to **remove** one approach (1Password vs. direct token) depending on your use case.

3. **Install 1Password CLI** (optional, only if you’re pulling the token from 1Password):
   ```sh
   brew install --cask 1password/tap/1password-cli    # macOS
   # or see docs for Linux/Windows instructions
   ```

---

## ▶️ Running the Script

1. **Make the Script Executable** (optional):

   ```sh
   chmod +x agentless_poc.sh
   ```

2. **Execute**:

   ```sh
   ./agentless_poc.sh
   ```

   or

   ```sh
   bash agentless_poc.sh
   ```

3. **Follow Prompts**:
   - **Select your region** (e.g., `us1`, `eu1`, `ca1`, etc.).
   - **Choose which syslog RFC** you’d like to simulate: **3164** (traditional) or **5424** (NIST SP 800-53 preferred).
   - The script randomizes the rest (server name, event message, timestamps, etc.).

### Example CLI Walkthrough

```
$ bash agentless_poc.sh

Agentless Testing Approach for Non-Production (POC) to Send Data to SentinelOne's Singularity Data Lake
Choose SentinelOne Singularity Data Lake base ingest URL:
1) https://xdr.us1.sentinelone.net (default)
2) https://xdr.ca1.sentinelone.net
3) https://xdr.eu1.sentinelone.net
4) https://xdr.ap1.sentinelone.net
5) https://xdr.aps1.sentinelone.net
6) https://xdr.apse2.sentinelone.net
Enter your choice (1-6) [1]:
```

The script continues, retrieving your token from `.env` (or 1Password), generating random data, and posting to SentinelOne’s `addEvents` API.

---

## ✅ Sample Output

```
Using direct API key from .env
Selected URL: https://xdr.us1.sentinelone.net/api/addEvents

Both Syslog RFC 3164 and RFC 5424 satisfy the logging requirements...

Which log event sample would you like to send?
1) Syslog RFC 3164 (default)
2) Syslog RFC 5424 (NIST SP 800-53 preferred)
Enter your choice (1-2) [1]:

Randomized values:
Session ID: 11e59c7c-1ae2-47e3-8718-3c85c670fffe
Search Tag: 3bb6d731-f88e-4f55-805c-18f33c753e7a
Thread: 4
Severity: 2
ServerId (Transformer Name): starscream
RFC3164 chosen, hostname in message will be: nemesis
Message: Invalid login attempt

Response from https://xdr.us1.sentinelone.net/api/addEvents:
{"bytesCharged":0,"status":"success"}
HTTP Status: 200
Event sent successfully to https://xdr.us1.sentinelone.net/api/addEvents
Sent message content was:
<34> Mar 20 14:37:02 nemesis su: 'Invalid login attempt' for nemesis on /dev/pts/8

To locate this event in SDL, use the following EVENT SEARCH...
search_tag = '3bb6d731-f88e-4f55-805c-18f33c753e7a'
```

When the HTTP status is **200**, the event has been accepted by SentinelOne.

---

## 🔎 Finding Your Events in SentinelOne

1. Open the **SentinelOne Management Console** and navigate to **Singularity Data Lake**.
2. Choose the **scope** (Global, Account, Site, or Group).
3. Set time range to include your test (e.g., last 10 minutes).
4. Search on the auto-generated `search_tag` (from the script’s output).
5. View the ingested logs and confirm they arrived correctly.

> See [SentinelOne’s Search Guide](https://community.sentinelone.com/s/article/000006386) for advanced filtering.

---

## 🏗 Script Internals & Customization

- **Random Transformers Hostnames**: The script picks from a short list of Autobot/Decepticon names and decides if the RFC3164 `hostname` field is `teletraan1` (Autobot) or `nemesis` (Decepticon).
- **RFC3164 vs. RFC5424**:
  - **RFC3164** messages have a `"<PRI> TIMESTAMP hostname su: 'message'..."` structure.
  - **RFC5424** includes structured data fields and precise timestamps in the format `YYYY-MM-DDThh:mm:ss.ssssssZ`.
- **Customizable syslog messages**: Adjust the arrays for `RFC3164_MESSAGES` or `RFC5424_MESSAGES` to reflect logs relevant to your environment.
- **Severity & Thread**: Randomly generated each run (configured in the script near `$((RANDOM % ... ))`).
- **Search Tag**: A random UUID appended to each event, making search & correlation trivial.

Feel free to edit any parts of the script to align with your internal naming conventions, event structures, or testing requirements.

---

## 📚 References

- **[S1 SDL addEvents API](https://community.sentinelone.com/s/article/000006773)**
- **[S1 Collector](https://community.sentinelone.com/s/article/000006807)**
- **[S1 Tenant Region Endpoints](https://community.sentinelone.com/s/article/000004961)**
- **[NIST SP 800-53 Guidelines](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)**
- **[Syslog RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164) | [Syslog RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424)**

---

## 🛡 License

This project is distributed under the **MIT License**. See the [`LICENSE`](LICENSE) file for details.

**Trademarks:**

- “SentinelOne (S1),” “Scalyr,” and “Dataset” are registered trademarks of their respective owners. This project is **not** affiliated with nor endorsed by those entities in any way.

<br>

---

## 🙌 Contributing

Pull requests and issue reports are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

### Enjoy Quick, Agentless Log Testing

This script offers an **agentless** method to validate your SentinelOne ingestion pipeline before any production deployments. Spin it up, send some syslog-styled events, and confirm they appear in **Singularity Data Lake** with minimal friction.

> **Pro Tip**: Tweak the script to replicate specific log scenarios or compliance needs you might have. Happy testing!

---

## 🗓 Upcoming Releases

- **More custom log sources**  
  Additional sample data generators (e.g., firewall, database, container logs).

- **Custom synthetic event log generation pipeline**  
  A GitHub Actions workflow for automated event creation and ingestion testing — _alleviating the need to run a local script_.

- **Web UI alternative**  
  A lightweight web interface to trigger and view log generation without a command-line script.
