import express from "express";
import fetch from "node-fetch";
import dotenv from "dotenv";
import cors from "cors";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.post("/chat", async (req, res) => {
  const { provider, model, messages, max_tokens } = req.body;

  try {
    if (provider === "anthropic") {
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": process.env.ANTHROPIC_API_KEY,
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01"
        },
        body: JSON.stringify({ model, max_tokens, messages }),
      });
      const data = await response.json();
      return res.json(data);
    }

    if (provider === "openai") {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model,
          messages,
          max_tokens
        }),
      });
      const data = await response.json();
      return res.json(data);
    }

    res.status(400).json({ error: "Invalid provider" });

  } catch (err) {
    console.error("Proxy error:", err);
    res.status(500).json({ error: err.toString() });
  }
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));
