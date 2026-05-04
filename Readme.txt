=========================================================
ZeeMailer - AI-Assisted Email Marketing Tool
=========================================================

ZeeMailer is an intelligent, high-converting cold outreach 
and follow-up email tool powered by Google Gemini AI.

NOTE: The installer will automatically install Node.js LTS 
if it is not already present. No manual setup required.

INSTALLATION INSTRUCTIONS
---------------------------------------------------------

[For Linux Users]
1. Open terminal and navigate to the zeemailer folder.
2. Run:   chmod +x install.sh
3. Run:   ./install.sh
4. Done! Launch via Desktop icon or type: zeemailer

[For Windows Users]
1. Double-click install.bat
2. If Windows Defender prompts, click "More info" -> "Run anyway"
3. Done! Launch via Desktop icon or type: zeemailer

UPDATING ZEEMAILER
---------------------------------------------------------
When a new version is released:

[If installed via Git (Recommended)]

  Linux:
    cd /path/to/zeemailer
    git pull origin main
    npm install --omit=dev

  Windows (Command Prompt):
    cd C:\path\to\zeemailer
    git pull origin main
    npm install --omit=dev

  Your .env and data/ folder are NOT touched by git pull.

[If downloaded as ZIP]
1. BACKUP your .env file and data/ folder to a safe place.
2. Extract the new ZIP, replacing the old folder.
3. RESTORE your .env file and data/ folder.
4. Re-run the installer (install.sh or install.bat).

WARNING: Your .env file contains your email password and 
API key. Never replace it with a blank one from the update.

FIRST-TIME SETUP
---------------------------------------------------------
On first launch, you will be asked to enter:
  - SMTP Email Address (e.g., support@yourdomain.com)
  - Email Password
  - SMTP Host (e.g., smtp.hostinger.com or smtp.gmail.com)
  - SMTP Port (465 for SSL, 587 for TLS)
  - Gemini API Key (free from: aistudio.google.com/app/apikey)

=========================================================
Developed with LOVE by Muhammad Zeeshan
Contact: malikmuhammadzeeshanpahore@gmail.com
=========================================================
