# SentinelOne AddEvents API Tester

![S1 AddEvents API](https://img.shields.io/badge/S1_AddEvents-API_Tester-blue?style=for-the-badge&logo=sentinelone)
![Agentless](https://img.shields.io/badge/Agentless-Test_Logs_Without_Installing_Anything-green?style=for-the-badge)
![Zsh Compatible](https://img.shields.io/badge/Zsh-Compatible-yellow?style=for-the-badge&logo=gnu-bash)
![POC Ready](https://img.shields.io/badge/POC_Ready-Test_Before_You_Commit-orange?style=for-the-badge)

## 🔥 Why This Exists (Customer Problem)

Deploying a **POC/POV** for log ingestion? Not every customer wants to **immediately install the SentinelOne (S1) Collector agent**. Some face **change control bottlenecks**, while others want to validate **addEvents API-based log ingestion** before making a decision.

This script provides a **simple, agentless approach** to test the **SentinelOne addEvents API**, simulating real-time log events without requiring **syslog** or the **S1 Collector agent**.

---

## 🎯 What This Script Does

- **Sends randomized event data** to SentinelOne's `addEvents` API.
- **Supports both 1Password (`op read`) and traditional `.env` authentication.**
- **Generates unique session IDs (UUIDs)** for each request.
- **Supports rapid testing** for customers validating API ingestion before deploying the **S1 Collector**.

🔗 **Official SentinelOne Docs for Reference:**

- **[addEvents API - Best Practices](https://community.sentinelone.com/s/article/000008985)**
- **[SDL API Keys](https://community.sentinelone.com/s/article/000006763)**
- **[SDL API - addEvents](https://community.sentinelone.com/s/article/000006773)**
- **[S1 Collector](https://community.sentinelone.com/s/article/000006807)**

---

## ⚡ Quick Start

### 📥 **1. Install Prerequisites**

Make sure you have:

- **[1Password CLI](https://developer.1password.com/docs/cli/)** (`op`) (Optional, for secure token retrieval)
- **[cURL](https://curl.se/)** (for API requests)
- **uuidgen** (for unique session IDs)
- **awk** (for random float values)
- **Zsh** (script is optimized for Zsh, but can be adapted for Bash)

---

### ⚙️ **2. Configure Your Environment**

1. Clone this repository:

   ```sh
   git clone https://github.com/sva-s1/addEvents.git
   cd addEvents
   ```

2. Create a `.env` file:

   - **For 1Password users**:

     ```
     SDL_LOG_ACCESS_WRITE_KEY="op://1pw-vault-name/1pw-record-name/SDL_LOG_ACCESS_WRITE_KEY"
     ```

   - **For traditional `.env` users** (no 1Password integration):
     ```
     SDL_LOG_ACCESS_WRITE_KEY="some-token-value-here"
     ```

3. **Verify API Key Retrieval**:
   - **If using 1Password**:
     ```sh
     op read $SDL_LOG_ACCESS_WRITE_KEY
     ```
   - **If using a traditional `.env` file**:
     ```sh
     echo $SDL_LOG_ACCESS_WRITE_KEY
     ```

---

### ▶️ **3. Run the Script**

Instead of making the script executable, run it with Zsh:

```sh
zsh addEvents.sh
```

### ✅ **Successful Output Example**

```
🔐 Using 1Password integration to retrieve token...
📢 Selected Message: Connection established
{"bytesCharged":0,"status":"success"}

🔑 Using direct API key from .env
📢 Selected Message: Request received
{"bytesCharged":0,"status":"success"}
```

This confirms that the event was successfully sent to SentinelOne’s `addEvents` API.

---

## 🛠 How It Works

Each execution of the script:

1. **Retrieves** the SentinelOne API token from **1Password** or a traditional `.env` file.
2. **Generates random event attributes**, including:
   - Thread ID, Severity (1-4), Record ID, Latency, Length.
3. **Assigns a unique UUID session ID** per request.
4. **Builds and sends a structured JSON payload** to SentinelOne’s `addEvents` API.

---

## 📜 Sample JSON Payload Sent to SentinelOne

```json
{
  "session": "c91219b5-8d5f-4b2e-9a7d-fb8c3f8a4c47",
  "events": [
    {
      "thread": "7",
      "ts": "1710554388237000000",
      "attrs": {
        "message": "Request received",
        "dataSource.category": "security",
        "dataSource.name": "API-Test",
        "dataSource.vendor": "SentinelOne",
        "recordId": 12345,
        "latency": 32.7,
        "length": 15432,
        "severity": 2,
        "dataset": "agentless-addEvents",
        "parser": "json"
      }
    }
  ]
}
```

---

## 🛠 Customization Options

Modify these script values to tailor event data:

- **Modify event messages:**
  ```zsh
  MESSAGES=("Request received" "Response sent" "Record retrieved" "Connection established" "Session terminated")
  ```
- **Adjust random value ranges:**
  ```zsh
  SEV=$((RANDOM % 4 + 1))      # Severity (1-4)
  LATENCY=$(awk -v min=5 -v max=50 'BEGIN{srand(); print min+rand()*(max-min)}')  # Latency (5-50ms)
  ```

---

## 🐛 Troubleshooting

### 🔑 **Authentication Issues**

- **If using 1Password**, ensure you are signed in:
  ```sh
  op signin
  ```
- **If using a traditional `.env`**, ensure the API key is correct:
  ```sh
  echo $SDL_LOG_ACCESS_WRITE_KEY
  ```

### 🌐 **API Connection Issues**

- **Ensure your SentinelOne API URL is correct**:
  ```zsh
  echo $ADD_EVENTS_API_URL
  ```
- **Check SentinelOne logs** if requests fail.

---

## 📄 License

This project is licensed under the MIT License.

---

## 💡 Why This Matters for SentinelOne Customers

✔ **Simplifies POC/POV Testing** – No need to install the **S1 Collector agent** just to validate log ingestion.
✔ **Agentless Validation** – Some customers **can't install an agent** due to **change control or security policies**.
✔ **Faster Buy-in** – Engineers can **test first**, evaluate data flow, and later decide on full deployment.

🔥 **Need to prove SentinelOne log ingestion?**
**Use this script to show how easy it is to send API-based logs!**
