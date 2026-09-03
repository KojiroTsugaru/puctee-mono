# Puctee Backend API

A FastAPI-powered backend service for lateness prevention iOS application. This project demonstrates modern backend development practices, complex database relationships, real-time notifications, and location-based services.

> 📱 **Frontend Repository**: The iOS app for this backend is on [puctee](https://github.com/KojiroTsugaru/puctee).

## 🚀 Project Overview

Puctee Backend is a comprehensive social planning API that helps friends coordinate meetups with built-in accountability features. Users can create plans, invite friends, set penalties for tardiness, and track attendance through location-based check-ins. The platform promotes punctuality and reliability through gamified trust scoring and social accountability.

## 🛠️ Tech Stack

- **Framework**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL (Supabase) with SQLAlchemy (Async ORM)
- **Authentication**: JWT tokens with bcrypt password hashing
- **Notifications**: Apple Push Notification service (APNs)
- **Server**: Railway
- **Cache**: Supabase Realtime (or Redis if needed)
- **Storage**: Supabase Storage
- **Testing**: pytest with FastAPI TestClient
- **Documentation**: Auto-generated OpenAPI/Swagger docs

## 🏗️ Architecture

The Puctee backend follows a modern cloud architecture using Railway and Supabase.

```mermaid
flowchart LR
    user["iOS App (SwiftUI)"]
    
    subgraph Railway ["Railway"]
        API["FastAPI Server"]
        Env["Environment Variables"]
    end
    
    subgraph Database ["Database"]
        Supabase["Supabase PostgreSQL"]
        Realtime["Supabase Realtime"]
    end
    
    subgraph Storage ["Storage"]
        ObjectStorage["Supabase Storage"]
    end

    APNs["Apple Push Notification Service"]

    %% Request flow
    user -- "HTTPS / JSON" --> API
    API -- "SQL (Async)" --> Supabase
    API -- "WebSocket" --> Realtime
    API -- "Object Operations" --> ObjectStorage
    API -- "Read Secrets" --> Env
    user -- "Download public images" --> ObjectStorage

    %% Notification flow
    API -- "Send Push Notification" --> APNs
    APNs -- "Push Message" --> user
```

## ✨ Features

- **User Authentication**: JWT-based secure authentication and user management
- **Friend System**: Send/accept friend requests with bidirectional relationship management
- **Plan Management**: Create events, invite participants, track attendance status
- **Location Services**: GPS-based check-ins for plan verification
- **Accountability System**: Penalty management with proof submission for tardiness
- **Trust Scoring**: Gamified reliability tracking based on punctuality history
- **Real-time Notifications**: Push notifications with APNs for invitations, updates, and reminders
- **Complex Relationships**: Advanced SQLAlchemy patterns with eager loading optimization

### Supabase Storage setup

Create a public Storage bucket named `images`, then set these server environment variables:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SECRET_KEY=sb_secret_...
SUPABASE_STORAGE_BUCKET=images
```

The secret key belongs only in the backend environment. Do not add it to the iOS app or commit it to source control. A legacy `SUPABASE_SERVICE_ROLE_KEY` is also supported. Existing S3 URLs already stored in the database are not copied by this code change; migrate those objects and update their database URLs separately if they must remain available.

## 📚 API Documentation

### Key Endpoints
- **Authentication**: `/auth/login`, `/auth/signup`, `/auth/refresh`
- **Users**: `/users/me`, `/users/me/trust-stats`
- **Friends**: `/friends/invite`, `/friends/accept/{invite_id}`, `/friends/{friend_id}`
- **Plans**: `/plans/`, `/plans/list`, `/plans/{plan_id}/checkin`

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Node.js 18+ (for Wrangler CLI)
- Cloudflare account (free tier available)
- Neon or Supabase account (for PostgreSQL database)

### Option 1: Deploy to Railway (Recommended)

Railway provides the easiest deployment experience with full FastAPI support.

#### Quick Start

1. **Push to GitHub**
   ```bash
   git push origin main
   ```

2. **Deploy to Railway**
   - Visit [railway.app](https://railway.app)
   - Click "New Project" → "Deploy from GitHub repo"
   - Select `puctee-mono` repository
   - Set root directory: `puctee-backend`

3. **Configure Environment Variables**
   - Add all variables from `.env.example`
   - Railway Dashboard → Variables

4. **Done!**
   - Your API will be at: `https://your-project.up.railway.app`

**Full Guide**: [Railway Deployment Guide](./RAILWAY_DEPLOYMENT.md)

---

### Option 2: Local Development

#### 1. Clone and Setup

```bash
git clone https://github.com/KojiroTsugaru/puctee-backend.git
cd puctee-backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/puctee"
SECRET_KEY="your_secret_key_here"
APNS_AUTH_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
# ... other variables
```

`APNS_AUTH_KEY` replaces the former AWS Secrets Manager configuration. Set it
to the full contents of your Apple `.p8` key. If your hosting provider only
accepts single-line values, encode line breaks as literal `\n` sequences.

#### 3. Run Database Migrations

```bash
alembic upgrade head
```

#### 4. Run the Application

```bash
uvicorn app.main:app --reload
```

The API will be available at `http://127.0.0.1:8000`.

#### 5. Running Tests

```bash
pytest
```

## 📝 License

This project is part of a portfolio showcase. Feel free to use as reference for your own projects.

## 🤝 Contributing

This is a portfolio project demonstrating advanced FastAPI development patterns, complex database relationships, and real-time notification systems.

---

**Built with ❤️ using FastAPI, SQLAlchemy, and modern Python development practices**
