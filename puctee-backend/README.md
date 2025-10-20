# Puctee Backend API

A FastAPI-powered backend service for lateness prevention iOS application. This project demonstrates modern backend development practices, complex database relationships, real-time notifications, and location-based services.

> 📱 **Frontend Repository**: The iOS app for this backend is on [puctee](https://github.com/KojiroTsugaru/puctee).

## 🚀 Project Overview

Puctee Backend is a comprehensive social planning API that helps friends coordinate meetups with built-in accountability features. Users can create plans, invite friends, set penalties for tardiness, and track attendance through location-based check-ins. The platform promotes punctuality and reliability through gamified trust scoring and social accountability.

## 🛠️ Tech Stack

- **Framework**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL (Neon/Supabase) with SQLAlchemy (Async ORM)
- **Authentication**: JWT tokens with bcrypt password hashing
- **Notifications**: Apple Push Notification service (APNs)
- **Server**: Cloudflare Workers (Serverless)
- **Cache**: Redis (Upstash)
- **Storage**: AWS S3 (can migrate to Cloudflare R2)
- **Testing**: pytest with FastAPI TestClient
- **Documentation**: Auto-generated OpenAPI/Swagger docs

## 🏗️ Architecture

The Puctee backend follows a modern serverless architecture using Cloudflare Workers and Neon/Supabase.

```mermaid
flowchart LR
    user["iOS App (SwiftUI)"]
    
    subgraph Cloudflare ["Cloudflare"]
        Workers["Workers (FastAPI)"]
        Secrets["Workers Secrets"]
    end
    
    subgraph Database ["Database"]
        Neon["Neon/Supabase PostgreSQL"]
    end
    
    subgraph Cache ["Cache"]
        Redis["Upstash Redis"]
    end
    
    subgraph Storage ["Storage"]
        S3["AWS S3"]
    end

    APNs["Apple Push Notification Service"]

    %% Request flow
    user -- "HTTPS / JSON" --> Workers
    Workers -- "SQL (TCP)" --> Neon
    Workers -- "Cache Operations" --> Redis
    Workers -- "Object Operations" --> S3
    Workers -- "Fetch Secrets" --> Secrets
    user -- "Upload/Download" --> S3

    %% Notification flow
    Workers -- "Send Push Notification" --> APNs
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

### Option 1: Deploy to Cloudflare Workers (Production)

#### 1. Clone the Repository

```bash
git clone https://github.com/KojiroTsugaru/puctee-backend.git
cd puctee-backend
```

#### 2. Install Wrangler CLI

```bash
npm install -g wrangler
```

#### 3. Setup Cloudflare Workers

Run the interactive setup script:

```bash
./setup-cloudflare.sh
```

This will:
- Login to Cloudflare
- Configure all required secrets (DATABASE_URL, SECRET_KEY, etc.)
- Prepare your environment for deployment

#### 4. Setup Database

Create a Neon or Supabase database and run migrations:

```bash
# Set your database URL
export DATABASE_URL="postgresql://user:pass@host/db?sslmode=require"

# Run migrations
alembic upgrade head
```

#### 5. Deploy

```bash
./deploy.sh production
```

Your API will be available at: `https://puctee-api.your-subdomain.workers.dev`

📖 **Documentation**:
- [Cloudflare Migration Guide](./CLOUDFLARE_MIGRATION.md) - Complete migration instructions
- [Supabase Realtime Setup](./SUPABASE_REALTIME.md) - WebSocket migration to Supabase

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
# ... other variables
```

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