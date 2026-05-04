require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');
const csv = require('csv-parser');
const nodemailer = require('nodemailer');
const { GoogleGenAI } = require('@google/genai');
// ESM dynamic import will be used for 'open'

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

const upload = multer({ dest: 'uploads/' });

// Ensure directories exist
if (!fs.existsSync('data')) fs.mkdirSync('data');
if (!fs.existsSync('uploads')) fs.mkdirSync('uploads');

const envPath = path.join(__dirname, '.env');
const analyticsPath = path.join(__dirname, 'data', 'analytics.json');
const sentPath = path.join(__dirname, 'data', 'sent.csv');

// --- Helper Functions ---
function getAnalytics() {
    if (fs.existsSync(analyticsPath)) {
        return JSON.parse(fs.readFileSync(analyticsPath, 'utf8'));
    }
    return { totalEmailsSent: 0, totalFollowUps: 0, niches: [] };
}

function saveAnalytics(data) {
    fs.writeFileSync(analyticsPath, JSON.stringify(data, null, 2));
}

function getSentEmails() {
    return new Promise((resolve) => {
        if (!fs.existsSync(sentPath)) {
            return resolve(new Set());
        }
        const sent = new Set();
        fs.createReadStream(sentPath)
            .pipe(csv())
            .on('data', (row) => {
                if (row.email) sent.add(row.email.trim().toLowerCase());
            })
            .on('end', () => resolve(sent));
    });
}

function appendToSent(email) {
    const row = `${email}\n`;
    if (!fs.existsSync(sentPath)) {
        fs.writeFileSync(sentPath, `email\n${row}`);
    } else {
        fs.appendFileSync(sentPath, row);
    }
}

// --- Endpoints ---

// Status: Check if setup is needed
app.get('/api/status', (req, res) => {
    const isSetup = fs.existsSync(envPath) && process.env.EMAIL_USER && process.env.GEMINI_API_KEY;
    res.json({ isSetup: !!isSetup });
});

// Setup: Save credentials
app.post('/api/setup', (req, res) => {
    const { emailUser, emailPass, emailHost, emailPort, geminiKey } = req.body;
    const envContent = `EMAIL_USER=${emailUser}\nEMAIL_PASS="${emailPass}"\nEMAIL_HOST=${emailHost}\nEMAIL_PORT=${emailPort}\nGEMINI_API_KEY=${geminiKey}\n`;
    fs.writeFileSync(envPath, envContent);
    // Reload env
    require('dotenv').config({ override: true });
    res.json({ success: true });
});

// Upload: Parse file and return headers & data
app.post('/api/upload', upload.single('file'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const filePath = req.file.path;
    const ext = path.extname(req.file.originalname).toLowerCase();
    
    let headers = [];
    let data = [];

    try {
        if (ext === '.csv') {
            fs.createReadStream(filePath)
                .pipe(csv())
                .on('headers', (hdr) => headers = hdr)
                .on('data', (row) => data.push(row))
                .on('end', () => {
                    fs.unlinkSync(filePath);
                    res.json({ headers, data });
                });
        } else if (ext === '.xlsx' || ext === '.xls') {
            const workbook = xlsx.readFile(filePath);
            const sheetName = workbook.SheetNames[0];
            const sheet = workbook.Sheets[sheetName];
            data = xlsx.utils.sheet_to_json(sheet, { defval: '' });
            if (data.length > 0) {
                headers = Object.keys(data[0]);
            }
            fs.unlinkSync(filePath);
            res.json({ headers, data });
        } else {
            res.status(400).json({ error: 'Unsupported file type' });
        }
    } catch (e) {
        res.status(500).json({ error: 'Error processing file' });
    }
});

// Generate Template
app.post('/api/generate-template', async (req, res) => {
    const { campaignType, agencyName, niche } = req.body;
    
    if (!process.env.GEMINI_API_KEY) {
        return res.status(400).json({ error: 'Gemini API Key is missing. Please complete setup first.' });
    }

    try {
        const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
        
        let prompt = `You are an expert copywriter. `;
        if (campaignType === 'new') {
            prompt += `Write a highly converting cold outreach email for a ${agencyName} agency targeting the ${niche} niche. `;
            prompt += `Use placeholders like [Name], [Company], and [Phone] where applicable. `;
            prompt += `The tone should be professional but engaging. Do not include subject line in the body, just provide the email body. Keep it concise.`;
        } else {
            prompt += `Write a polite follow-up email for a ${agencyName} agency targeting the ${niche} niche. `;
            prompt += `Assume we sent them an email recently. Use placeholders like [Name] and [Company]. Keep it brief and focused on getting a reply.`;
        }

        const response = await ai.models.generateContent({
            model: 'models/gemini-2.5-flash',
            contents: prompt,
        });

        let template = response.text;
        res.json({ template });
    } catch (e) {
        console.error('Gemini API Error:', e.message || e);
        // Parse specific error types for better user messages
        let userMsg = 'Failed to generate template. Please try again.';
        if (e.status === 429 || (e.message && e.message.includes('429'))) {
            userMsg = 'Gemini API quota exceeded. Your free tier limit has been reached. Please create a new API key at https://aistudio.google.com/app/apikey or wait until your quota resets.';
        } else if (e.status === 403 || (e.message && e.message.includes('403'))) {
            userMsg = 'Gemini API key is invalid or not authorized. Please check your API key in Settings.';
        } else if (e.status === 404 || (e.message && e.message.includes('404'))) {
            userMsg = 'Gemini model not found. Please contact support.';
        }
        // Always send a response — never let the server crash
        if (!res.headersSent) {
            res.status(500).json({ error: userMsg });
        }
    }
});

// Send Campaign
app.post('/api/send-campaign', async (req, res) => {
    const { subject, template, data, mapping, campaignType, niche, customVars } = req.body;
    
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS || !process.env.EMAIL_HOST || !process.env.EMAIL_PORT) {
        return res.status(400).json({ error: 'Email configuration is missing.' });
    }

    const transporter = nodemailer.createTransport({
        host: process.env.EMAIL_HOST,
        port: parseInt(process.env.EMAIL_PORT),
        secure: parseInt(process.env.EMAIL_PORT) === 465,
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS
        }
    });

    const sentEmails = await getSentEmails();
    let sentCount = 0;
    
    // Quick verification
    try {
        await transporter.verify();
    } catch (e) {
        return res.status(500).json({ error: 'Failed to connect to email server. Check credentials.' });
    }

    for (let i = 0; i < data.length; i++) {
        const row = data[i];
        const email = row[mapping.email];
        
        if (!email) continue;
        const normalizedEmail = email.trim().toLowerCase();

        if (campaignType === 'new' && sentEmails.has(normalizedEmail)) {
            console.log(`Skipping ${normalizedEmail} - already sent before.`);
            continue;
        }

        if (campaignType === 'followup' && !sentEmails.has(normalizedEmail)) {
            console.log(`Skipping ${normalizedEmail} - not found in sent list for follow-up.`);
            continue;
        }

        // ── Variable replacement ─────────────────────────────────────────
        let body = template;

        if (customVars && customVars.length > 0) {
            // Use user-defined variable → column mappings
            customVars.forEach(({ varName, colName }) => {
                let value = '';
                if (colName === '__auto_company__') {
                    // Auto-detect company column
                    for (let key in row) {
                        if (key.toLowerCase().includes('company')) { value = row[key]; break; }
                    }
                    if (!value) value = 'your company';
                } else {
                    value = row[colName] || '';
                }
                const regex = new RegExp(`\\[${varName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\]`, 'gi');
                body = body.replace(regex, value);
            });
        } else {
            // Fallback: replace built-in placeholders
            const name = row[mapping.name] || 'there';
            const phone = mapping.phone ? (row[mapping.phone] || '') : '';
            let company = 'your company';
            for (let key in row) {
                if (key.toLowerCase().includes('company')) { company = row[key]; break; }
            }
            body = body
                .replace(/\[Name\]/gi, name)
                .replace(/\[Company\]/gi, company)
                .replace(/\[Phone\]/gi, phone);
        }

        try {
            await transporter.sendMail({
                from: process.env.EMAIL_USER,
                to: normalizedEmail,
                subject: subject || 'Connecting',
                text: body
            });
            
            console.log(`Sent to ${normalizedEmail}`);
            if (campaignType === 'new') {
                appendToSent(normalizedEmail);
            }
            sentCount++;
            
            // Wait 2 seconds between emails to avoid spam filters
            await new Promise(r => setTimeout(r, 2000));
        } catch (e) {
            console.error(`Failed to send to ${normalizedEmail}:`, e.message);
        }
    }

    // Update Analytics
    const analytics = getAnalytics();
    if (campaignType === 'new') {
        analytics.totalEmailsSent += sentCount;
        if (niche && !analytics.niches.includes(niche)) {
            analytics.niches.push(niche);
        }
    } else {
        analytics.totalFollowUps += sentCount;
    }
    saveAnalytics(analytics);

    res.json({ success: true, sentCount });
});

// Get Analytics
app.get('/api/analytics', (req, res) => {
    res.json(getAnalytics());
});

app.listen(PORT, async () => {
    console.log(`Server running on http://localhost:${PORT}`);
    // Open in browser on launch
    try {
        const openModule = await import('open');
        await openModule.default(`http://localhost:${PORT}`);
    } catch (e) {
        console.log('Could not open browser automatically.', e);
    }
});

// Global handlers to prevent server from crashing on unhandled errors
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception (server kept alive):', err.message);
});

process.on('unhandledRejection', (reason) => {
    console.error('Unhandled Promise Rejection (server kept alive):', reason);
});
