import os
import sqlite3
import hashlib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key) if api_key else None
app = FastAPI(title="MSOT Club Activities & Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def init_db():
    conn = sqlite3.connect("club_chat.db")
    cursor = conn.cursor()
    
    # 1. Users table with institutional roles
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            identifier TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT CHECK(role IN ('committee', 'president', 'vp', 'faculty', 'student', 'admin')) NOT NULL
        )
    """)

    # 2. Chat history table linked to users
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            user_prompt TEXT NOT NULL,
            bot_reply TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    """)
    
    # 3. Insert default test accounts if empty
    cursor.execute("SELECT COUNT(*) FROM users")
    if cursor.fetchone()[0] == 0:
        default_users = [
            ("committee@msot.edu", "Club Committee (President & VP)", hash_password("admin123"), "committee"),
            ("president@msot.edu", "Club President", hash_password("admin123"), "president"),
            ("vp@msot.edu", "Club Vice President", hash_password("vp123"), "vp"),
            ("faculty@msot.edu", "Prof. Mentor", hash_password("faculty123"), "faculty"),
            ("student@msot.edu", "Priyanshu", hash_password("student123"), "student"),
        ]
        cursor.executemany(
            "INSERT INTO users (identifier, name, password_hash, role) VALUES (?, ?, ?, ?)",
            default_users
        )
        print("✓ Created test accounts: Committee, President, VP, Faculty, Student")
    else:
        cursor.execute("SELECT id FROM users WHERE identifier = 'committee@msot.edu'")
        if not cursor.fetchone():
            cursor.execute(
                "INSERT OR IGNORE INTO users (identifier, name, password_hash, role) VALUES (?, ?, ?, ?)",
                ("committee@msot.edu", "Club Committee (President & VP)", hash_password("admin123"), "committee")
            )
            print("✓ Seeded merged Club Committee account (committee@msot.edu)")

    conn.commit()
    conn.close()

init_db()

class LoginRequest(BaseModel):
    identifier: str
    password: str

class PromptRequest(BaseModel):
    prompt: str
    user_id: int = None

@app.post("/api/login")
def login(data: LoginRequest):
    conn = sqlite3.connect("club_chat.db")
    cursor = conn.cursor()
    
    hashed_pwd = hash_password(data.password)
    cursor.execute(
        "SELECT id, identifier, name, role FROM users WHERE identifier = ? AND password_hash = ?",
        (data.identifier.strip().lower(), hashed_pwd)
    )
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid Email/ID or password.")

    return {
        "status": "success",
        "user": {
            "id": user[0],
            "identifier": user[1],
            "name": user[2],
            "role": user[3]
        }
    }

@app.post("/api/chat")
def handle_chat(req: PromptRequest):
    if not client:
        bot_reply = "MSOT Club Assistant: I'm active and ready to help! To enable live Gemini generative answers, set your GEMINI_API_KEY in .env."
    else:
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=req.prompt
            )
            bot_reply = response.text
        except Exception as e:
            bot_reply = f"MSOT Assistant Error: {str(e)}"

    conn = sqlite3.connect("club_chat.db")
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO messages (user_id, user_prompt, bot_reply) VALUES (?, ?, ?)",
        (req.user_id, req.prompt, bot_reply)
    )
    conn.commit()
    conn.close()

    return {"reply": bot_reply}