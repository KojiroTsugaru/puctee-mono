from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.api.routers import auth, users, friends, notifications, invite, scheduler
from app.api.routers.plans import router as plans_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield  # API server is now running

app = FastAPI(
    title="Puctee API",
    description="Puctee Backend API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict appropriately in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(friends.router, prefix="/api/friends", tags=["friends"])
app.include_router(plans_router, prefix="/api/plans", tags=["plans"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(invite.router, tags=["invite"])
app.include_router(scheduler.router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "Welcome to Puctee API"}

@app.get("/health")
def health():
    return {"ok": True}