"""
API Gateway for MySQL Business-to-Schema
Central entry point for all microservices with routing, authentication, and rate limiting
"""

from fastapi import FastAPI, HTTPException, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
import httpx
import asyncio
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import jwt
import redis
from functools import wraps
import logging
from pydantic import BaseModel, Field
import json
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MySQL Business-to-Schema API Gateway",
    description="Unified API gateway for database operations, ML models, and streaming services",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Redis for caching and rate limiting
try:
    redis_client = redis.Redis(host="localhost", port=6379, decode_responses=True)
    redis_client.ping()
    REDIS_AVAILABLE = True
except:
    logger.warning("Redis not available - caching and rate limiting disabled")
    REDIS_AVAILABLE = False
    redis_client = None

# Microservice registry
MICROSERVICES = {
    "database": {
        "url": os.getenv("DATABASE_SERVICE_URL", "http://localhost:8001"),
        "health": "/health",
        "timeout": 30,
    },
    "ml": {
        "url": os.getenv("ML_SERVICE_URL", "http://localhost:8002"),
        "health": "/health",
        "timeout": 60,
    },
    "streaming": {
        "url": os.getenv("STREAMING_SERVICE_URL", "http://localhost:8003"),
        "health": "/health",
        "timeout": 30,
    },
    "analytics": {
        "url": os.getenv("ANALYTICS_SERVICE_URL", "http://localhost:8004"),
        "health": "/health",
        "timeout": 45,
    },
}

# JWT Configuration
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_HOURS = 24


# Request/Response Models
class AuthRequest(BaseModel):
    username: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 86400


class ServiceRequest(BaseModel):
    service: str
    endpoint: str
    method: str = "GET"
    data: Optional[Dict[str, Any]] = None
    params: Optional[Dict[str, Any]] = None


class ServiceResponse(BaseModel):
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.now)


# Authentication
def create_token(username: str) -> str:
    """Create JWT token"""
    payload = {
        "sub": username,
        "exp": datetime.utcnow() + timedelta(hours=JWT_EXPIRATION_HOURS),
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Verify JWT token"""
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )
        return username
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        )


# Rate Limiting
class RateLimiter:
    def __init__(self, max_requests: int = 100, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds

    async def check_rate_limit(self, client_id: str) -> bool:
        """Check if client has exceeded rate limit"""
        if not REDIS_AVAILABLE:
            return True  # Allow if Redis not available

        key = f"rate_limit:{client_id}"
        try:
            current = redis_client.incr(key)
            if current == 1:
                redis_client.expire(key, self.window_seconds)
            return current <= self.max_requests
        except Exception as e:
            logger.error(f"Rate limiting error: {e}")
            return True  # Allow on error


rate_limiter = RateLimiter()


async def check_rate_limit(request: Request):
    """Rate limit dependency"""
    client_id = request.client.host
    if not await rate_limiter.check_rate_limit(client_id):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Rate limit exceeded"
        )


# Circuit Breaker
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failures = {}
        self.last_failure_time = {}

    async def call(self, service: str, func, *args, **kwargs):
        """Execute function with circuit breaker"""
        # Check if circuit is open
        if service in self.failures:
            if self.failures[service] >= self.failure_threshold:
                if datetime.now() - self.last_failure_time[service] < timedelta(
                    seconds=self.recovery_timeout
                ):
                    raise HTTPException(
                        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                        detail=f"Service {service} is temporarily unavailable",
                    )
                else:
                    # Reset after recovery timeout
                    self.failures[service] = 0

        try:
            result = await func(*args, **kwargs)
            # Reset failures on success
            if service in self.failures:
                self.failures[service] = 0
            return result
        except Exception as e:
            # Increment failure count
            if service not in self.failures:
                self.failures[service] = 0
            self.failures[service] += 1
            self.last_failure_time[service] = datetime.now()
            raise e


circuit_breaker = CircuitBreaker()


# Service Discovery
async def discover_service(service_name: str) -> Dict[str, Any]:
    """Discover service endpoint and health"""
    if service_name not in MICROSERVICES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Service {service_name} not found",
        )

    service = MICROSERVICES[service_name]

    # Check service health
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{service['url']}{service['health']}", timeout=5
            )
            service["status"] = (
                "healthy" if response.status_code == 200 else "unhealthy"
            )
        except:
            service["status"] = "unavailable"

    return service


# Request Routing
async def route_request(
    service_name: str,
    endpoint: str,
    method: str = "GET",
    data: Optional[Dict] = None,
    params: Optional[Dict] = None,
    headers: Optional[Dict] = None,
) -> Dict[str, Any]:
    """Route request to appropriate microservice"""
    service = await discover_service(service_name)

    if service["status"] != "healthy":
        # Try fallback or cache
        if REDIS_AVAILABLE and method == "GET":
            cache_key = f"cache:{service_name}:{endpoint}:{json.dumps(params or {})}"
            cached = redis_client.get(cache_key)
            if cached:
                logger.info(f"Returning cached response for {service_name}/{endpoint}")
                return json.loads(cached)

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Service {service_name} is not available",
        )

    # Make request to microservice
    async with httpx.AsyncClient() as client:
        url = f"{service['url']}{endpoint}"

        try:
            response = await circuit_breaker.call(
                service_name,
                client.request,
                method=method,
                url=url,
                json=data,
                params=params,
                headers=headers,
                timeout=service["timeout"],
            )

            result = response.json()

            # Cache successful GET requests
            if REDIS_AVAILABLE and method == "GET" and response.status_code == 200:
                cache_key = (
                    f"cache:{service_name}:{endpoint}:{json.dumps(params or {})}"
                )
                redis_client.setex(cache_key, 300, json.dumps(result))  # 5 min cache

            return result

        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail=f"Request to {service_name} timed out",
            )
        except Exception as e:
            logger.error(f"Error routing to {service_name}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with {service_name}",
            )


# API Endpoints


@app.get("/")
async def root():
    """API Gateway root endpoint"""
    return {
        "name": "MySQL Business-to-Schema API Gateway",
        "version": "1.0.0",
        "services": list(MICROSERVICES.keys()),
        "docs": "/api/docs",
    }


@app.post("/auth/login", response_model=AuthResponse)
async def login(auth: AuthRequest):
    """Authenticate and get access token"""
    # Simplified authentication - in production use proper auth service
    if auth.username == "admin" and auth.password == "password":
        token = create_token(auth.username)
        return AuthResponse(access_token=token, expires_in=JWT_EXPIRATION_HOURS * 3600)
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
    )


@app.get("/health")
async def health_check():
    """Gateway health check"""
    services_health = {}

    for service_name in MICROSERVICES:
        service = await discover_service(service_name)
        services_health[service_name] = service["status"]

    all_healthy = all(status == "healthy" for status in services_health.values())

    return {
        "gateway": "healthy",
        "services": services_health,
        "overall": "healthy" if all_healthy else "degraded",
        "timestamp": datetime.now().isoformat(),
    }


@app.post(
    "/service", response_model=ServiceResponse, dependencies=[Depends(check_rate_limit)]
)
async def call_service(request: ServiceRequest, username: str = Depends(verify_token)):
    """Route request to a microservice"""
    try:
        result = await route_request(
            service_name=request.service,
            endpoint=request.endpoint,
            method=request.method,
            data=request.data,
            params=request.params,
        )
        return ServiceResponse(success=True, data=result)
    except HTTPException as e:
        return ServiceResponse(success=False, error=e.detail)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return ServiceResponse(success=False, error=str(e))


# Database Operations
@app.get("/api/v1/databases", dependencies=[Depends(check_rate_limit)])
async def list_databases(username: str = Depends(verify_token)):
    """List all available database examples"""
    return await route_request("database", "/databases")


@app.get("/api/v1/databases/{db_name}/schema", dependencies=[Depends(check_rate_limit)])
async def get_database_schema(db_name: str, username: str = Depends(verify_token)):
    """Get schema for specific database"""
    return await route_request("database", f"/databases/{db_name}/schema")


@app.post(
    "/api/v1/databases/{db_name}/generate", dependencies=[Depends(check_rate_limit)]
)
async def generate_data(
    db_name: str, rows: int = 1000, username: str = Depends(verify_token)
):
    """Generate sample data for database"""
    return await route_request(
        "database", f"/databases/{db_name}/generate", method="POST", data={"rows": rows}
    )


# ML Operations
@app.post("/api/v1/ml/predict", dependencies=[Depends(check_rate_limit)])
async def ml_predict(
    model_name: str, data: Dict[str, Any], username: str = Depends(verify_token)
):
    """Make ML prediction"""
    return await route_request(
        "ml", f"/models/{model_name}/predict", method="POST", data=data
    )


@app.get("/api/v1/ml/models", dependencies=[Depends(check_rate_limit)])
async def list_ml_models(username: str = Depends(verify_token)):
    """List available ML models"""
    return await route_request("ml", "/models")


@app.post("/api/v1/ml/train", dependencies=[Depends(check_rate_limit)])
async def train_model(
    model_name: str,
    dataset: str,
    parameters: Optional[Dict] = None,
    username: str = Depends(verify_token),
):
    """Train ML model"""
    return await route_request(
        "ml",
        f"/models/{model_name}/train",
        method="POST",
        data={"dataset": dataset, "parameters": parameters or {}},
    )


# Streaming Operations
@app.post("/api/v1/streaming/publish", dependencies=[Depends(check_rate_limit)])
async def publish_to_stream(
    topic: str, message: Dict[str, Any], username: str = Depends(verify_token)
):
    """Publish message to streaming topic"""
    return await route_request(
        "streaming", f"/topics/{topic}/publish", method="POST", data=message
    )


@app.get("/api/v1/streaming/topics", dependencies=[Depends(check_rate_limit)])
async def list_streaming_topics(username: str = Depends(verify_token)):
    """List available streaming topics"""
    return await route_request("streaming", "/topics")


# Analytics Operations
@app.get("/api/v1/analytics/metrics", dependencies=[Depends(check_rate_limit)])
async def get_metrics(
    database: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    username: str = Depends(verify_token),
):
    """Get analytics metrics"""
    params = {}
    if database:
        params["database"] = database
    if start_date:
        params["start_date"] = start_date
    if end_date:
        params["end_date"] = end_date

    return await route_request("analytics", "/metrics", params=params)


@app.get("/api/v1/analytics/dashboards", dependencies=[Depends(check_rate_limit)])
async def list_dashboards(username: str = Depends(verify_token)):
    """List available analytics dashboards"""
    return await route_request("analytics", "/dashboards")


# WebSocket support for real-time updates
from fastapi import WebSocket, WebSocketDisconnect
from typing import Set


class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except:
                # Connection closed, remove it
                self.active_connections.discard(connection)


manager = ConnectionManager()


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket)
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()

            # Parse and handle message
            try:
                message = json.loads(data)
                if message.get("type") == "subscribe":
                    # Subscribe to specific events
                    await websocket.send_text(
                        json.dumps(
                            {"type": "subscribed", "topic": message.get("topic")}
                        )
                    )
                elif message.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except json.JSONDecodeError:
                await websocket.send_text(
                    json.dumps({"type": "error", "message": "Invalid JSON"})
                )

    except WebSocketDisconnect:
        manager.disconnect(websocket)


# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Custom HTTP exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "status_code": exc.status_code,
            "timestamp": datetime.now().isoformat(),
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """General exception handler"""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "status_code": 500,
            "timestamp": datetime.now().isoformat(),
        },
    )


# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("API Gateway starting up...")

    # Check microservices health
    for service_name in MICROSERVICES:
        service = await discover_service(service_name)
        logger.info(f"Service {service_name}: {service['status']}")

    logger.info("API Gateway ready")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("API Gateway shutting down...")

    # Close Redis connection
    if redis_client:
        redis_client.close()

    logger.info("API Gateway stopped")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
