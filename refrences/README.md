# 💰 Financial Tracker AI

A next-generation personal finance application powered by Generative AI. This app combines a sleek, modern "Glassmorphism" UI with advanced voice capabilities, allowing users to track expenses and income simply by speaking naturally in English or Arabic.

## ✨ Key Features

### 🎙️ AI Voice Agent
*   **Natural Language Input**: Just say "I spent 50 riyals on groceries" or "استلمت راتب 5000 ريال".
*   **Smart Parsing**: The AI automatically extracts the **Amount**, **Category**, **Type** (Income/Expense), and **Description**.
*   **Multilingual Support**: Fully optimized for **English (US)** and **Arabic (Egypt/Saudi)**.
*   **Real-time Transcription**: See what you are saying instantly as you speak.

### 📊 Dashboard & Management
*   **Transaction Command Center**: A quick-add interface for both voice and text.
*   **Pending Transactions**: Voice inputs are held in a "staging area" for your review before being saved.
*   **Edit with Voice**: You can modify pending items by speaking (e.g., "Change amount to 20").
*   **Local Persistence**: Your data lives in your browser (LocalStorage) – private and fast.

### 🎨 Modern UI/UX
*   **Glassmorphism Design**: Premium aesthetic with blur effects, mesh gradients, and smooth animations (Framer Motion).
*   **Responsive Layout**: Adapts perfectly from desktop sidebars to mobile bottom navigation.
*   **Customization**: Switch currencies (Default: SAR) and voice languages via Settings.

---

## 🤖 AI Configuration

This project leverages the **Ollama** ecosystem to run powerful Large Language Models directly for the application logic.

### 1. Model Architecture
*   **Provider**: [Ollama](https://ollama.com/)
*   **Model**: `gpt-oss:120b-cloud` (High-performance 120B parameter model)
*   **Library**: `ollama/browser` for direct client-side interaction.

### 2. Implementation Strategy
Instead of a heavy backend, the app communicates directly with the AI model via a lightweight proxy:
*   **Proxy (`vite.config.js`)**: Forwards requests from `/ollama` -> `https://ollama.com` to bypass Browser CORS restrictions during development.
*   **Netlify Edge (`netlify.toml`)**: A similar redirect rule allows this to work in production without a dedicated server.

### 3. Prompt Engineering
The AI is guided by specialized prompts to handle multilingual financial data:

*   **Logic**: It translates Arabic input to English JSON keys (`amount`, `category`, `title`) while preserving context.
*   **System Role**: `You are a helpful financial assistant that outputs raw JSON.`
*   **Transaction Parsing Prompt**:
    ```text
    Required fields for each object:
    - title: string (short English header, e.g. "Grocery Run", "Salary Error"). IF INPUT IS ARABIC, TRANSLATE TITLE.
    - description: string (detailed explanation). IF INPUT IS ARABIC, TRANSLATE DESCRIPTION TO ENGLISH.
    - amount: number (positive value)
    - type: "income" or "expense"
    - category: string (e.g., Food, Transport, Salary)

    The input text may be in English or Arabic. Treat it as a financial transaction.
    
    Text: "${text}"
    
    Return ONLY the JSON. Do not include markdown formatting.
    ```
*   **Modification Prompt**:
    ```text
    Update this JSON object based on the user's instruction.
    The instruction might be in English or Arabic. Understand the intent and update the JSON accordingly.
    
    Current Object:
    ${JSON.stringify(currentTransaction)}
    
    Instruction: "${instruction}"
    
    Return ONLY the updated JSON object. Do not include markdown formatting.
    ```

---

