# ZeeMailer - AI-Assisted Email Marketing Tool

ZeeMailer is an intelligent, high-converting cold outreach and follow-up email tool. It leverages the Google Gemini AI API to automatically draft personalized emails based on your target niche and seamlessly sends them out using your preferred SMTP server.

---

## 🚀 Installation Instructions

> **Note:** The installer will automatically install Node.js LTS if it is not already present on your system. No manual setup required.

### 🐧 For Linux Users

1. Open your terminal and navigate to the ZeeMailer folder:
   ```bash
   cd /path/to/zeemailer
   ```
2. Make the installer executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the installer:
   ```bash
   ./install.sh
   ```
4. **Done!** Launch the app by:
   - Double-clicking the **ZeeMailer** icon on your Desktop, **or**
   - Typing `zeemailer` in any terminal

---

### 🪟 For Windows Users

1. Open the `zeemailer` folder in File Explorer.
2. Double-click **`install.bat`** to run the installer.
   - If prompted by Windows Defender, click **"More info"** → **"Run anyway"**.
3. The installer will automatically install Node.js and all dependencies.
4. **Done!** Launch the app by:
   - Double-clicking the **ZeeMailer** icon on your Desktop, **or**
   - Opening Command Prompt/PowerShell and typing `zeemailer`

---

## 🔄 Updating ZeeMailer

When a new version of ZeeMailer is released, follow these steps to update:

### If you installed via Git (Recommended)

#### 🐧 Linux

```bash
cd /path/to/zeemailer
git pull origin main
npm install --omit=dev
```
Your settings (`.env`) and data (`data/`) are safe — they are not overwritten by an update.

#### 🪟 Windows

Open Command Prompt, navigate to the ZeeMailer folder, then run:
```cmd
cd C:\path\to\zeemailer
git pull origin main
npm install --omit=dev
```

### If you downloaded a ZIP (without Git)

1. **Back up your data first:**
   - Copy your `.env` file somewhere safe
   - Copy the `data/` folder somewhere safe

2. Download the latest ZIP from the source and extract it, **replacing** the old folder.

3. **Restore your data:**
   - Put your `.env` file back in the `zeemailer/` folder
   - Put the `data/` folder back

4. Re-run the installer:
   - **Linux:** `./install.sh`
   - **Windows:** Double-click `install.bat`

> ⚠️ **Your `.env` file contains your email credentials and API key. Never overwrite it with a blank one from the update package.**

---

## 🔑 First-Time Setup

When you launch ZeeMailer for the first time, you will be asked to enter:

| Field | Example |
|---|---|
| SMTP Email | `support@yourdomain.com` |
| Email Password | Your email account password |
| SMTP Host | `smtp.hostinger.com` / `smtp.gmail.com` |
| SMTP Port | `465` (SSL) or `587` (TLS) |
| Gemini API Key | Get it free from [aistudio.google.com](https://aistudio.google.com/app/apikey) |

---

## Developed with ❤️ by Muhammad Zeeshan
Contact: [malikmuhammadzeeshanpahore@gmail.com](mailto:malikmuhammadzeeshanpahore@gmail.com)
