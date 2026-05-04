require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');

async function run() {
    try {
        const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
        console.log("Initialized AI");
        const response = await ai.models.generateContent({
            model: 'models/gemini-2.0-flash',
            contents: 'say hello',
        });
        console.log("Response:", response.text);
    } catch (e) {
        console.error("Error:", e);
    }
}
run();
