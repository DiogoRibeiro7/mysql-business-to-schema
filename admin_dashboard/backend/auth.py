"""Authentication and authorization module.

Provides helpers for token-based auth and role/permission checks.
"""

from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any
import secrets
import logging
from .models import User, UserRole

logger = logging.getLogger(__name__)

# Configuration
SECRET_KEY = secrets.token_urlsafe(32)  # In production, use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security
security = HTTPBearer()
security_dep = Depends(security)


class AuthManager:
    """Manages authentication and authorization."""

    def __init__(self):
        """Initialize the in-memory auth store."""
        self.users_db: Dict[str, Dict[str, Any]] = {
            # Default admin user (change in production!)
            "admin": {
                "username": "admin",
                "email": "admin@example.com",
                "hashed_password": self.hash_password("admin123"),
                "role": UserRole.ADMIN,
                "permissions": ["*"],
                "is_active": True,
            },
            "developer": {
                "username": "developer",
                "email": "dev@example.com",
                "hashed_password": self.hash_password("dev123"),
                "role": UserRole.DEVELOPER,
                "permissions": ["read", "write", "execute"],
                "is_active": True,
            },
            "analyst": {
                "username": "analyst",
                "email": "analyst@example.com",
                "hashed_password": self.hash_password("analyst123"),
                "role": UserRole.ANALYST,
                "permissions": ["read", "execute"],
                "is_active": True,
            },
            "viewer": {
                "username": "viewer",
                "email": "viewer@example.com",
                "hashed_password": self.hash_password("viewer123"),
                "role": UserRole.VIEWER,
                "permissions": ["read"],
                "is_active": True,
            },
        }
        self.active_tokens: Dict[str, Dict[str, Any]] = {}

    def hash_password(self, password: str) -> str:
        """Hash a password."""
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash."""
        return pwd_context.verify(plain_password, hashed_password)

    def create_access_token(self, data: Dict[str, Any]) -> str:
        """Create a JWT access token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})

        token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

        # Store active token
        self.active_tokens[token] = {
            "username": data.get("sub"),
            "created_at": datetime.utcnow(),
            "expires_at": expire,
        }

        return token

    def decode_token(self, token: str) -> Dict[str, Any]:
        """Decode and validate a JWT token."""
        try:
            # Check if token is in active tokens
            if token not in self.active_tokens:
                raise jwt.InvalidTokenError("Token not found or has been revoked")

            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return payload
        except jwt.ExpiredSignatureError:
            # Remove expired token
            if token in self.active_tokens:
                del self.active_tokens[token]
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired"
            )
        except jwt.InvalidTokenError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {str(e)}",
            )

    async def login(self, username: str, password: str) -> Optional[str]:
        """Authenticate user and return token."""
        user = self.users_db.get(username)

        if not user:
            logger.warning(f"Login failed: User {username} not found")
            return None

        if not self.verify_password(password, user["hashed_password"]):
            logger.warning(f"Login failed: Invalid password for user {username}")
            return None

        if not user.get("is_active", True):
            logger.warning(f"Login failed: User {username} is inactive")
            return None

        # Create token
        access_token = self.create_access_token(
            data={
                "sub": username,
                "role": (
                    user["role"].value
                    if isinstance(user["role"], UserRole)
                    else user["role"]
                ),
                "permissions": user["permissions"],
            }
        )

        # Update last login
        user["last_login"] = datetime.utcnow()

        logger.info(f"User {username} logged in successfully")
        return access_token

    async def logout(self, username: str, token: Optional[str] = None):
        """Logout user and invalidate token."""
        # Remove token from active tokens
        if token and token in self.active_tokens:
            del self.active_tokens[token]

        # Clean up expired tokens
        current_time = datetime.utcnow()
        expired_tokens = [
            t
            for t, info in self.active_tokens.items()
            if info["expires_at"] < current_time
        ]
        for token in expired_tokens:
            del self.active_tokens[token]

        logger.info(f"User {username} logged out")

    async def get_user(self, username: str) -> Optional[User]:
        """Get user by username."""
        user_data = self.users_db.get(username)

        if not user_data:
            return None

        return User(
            username=user_data["username"],
            email=user_data["email"],
            role=user_data["role"],
            permissions=user_data["permissions"],
            created_at=user_data.get("created_at"),
            last_login=user_data.get("last_login"),
        )

    async def list_users(self) -> List[Dict[str, Any]]:
        """List all users."""
        users = []
        for username, user_data in self.users_db.items():
            users.append(
                {
                    "username": username,
                    "email": user_data["email"],
                    "role": (
                        user_data["role"].value
                        if isinstance(user_data["role"], UserRole)
                        else user_data["role"]
                    ),
                    "permissions": user_data["permissions"],
                    "is_active": user_data.get("is_active", True),
                    "last_login": user_data.get("last_login"),
                }
            )
        return users

    async def create_user(
        self, username: str, email: str, password: str, role: UserRole = UserRole.VIEWER
    ) -> Dict[str, Any]:
        """Create a new user."""
        if username in self.users_db:
            raise ValueError(f"User {username} already exists")

        # Define permissions based on role
        permissions_map = {
            UserRole.ADMIN: ["*"],
            UserRole.DEVELOPER: ["read", "write", "execute"],
            UserRole.ANALYST: ["read", "execute"],
            UserRole.VIEWER: ["read"],
        }

        user_data = {
            "username": username,
            "email": email,
            "hashed_password": self.hash_password(password),
            "role": role,
            "permissions": permissions_map.get(role, ["read"]),
            "is_active": True,
            "created_at": datetime.utcnow(),
        }

        self.users_db[username] = user_data

        logger.info(f"User {username} created with role {role}")

        return {"username": username, "email": email, "role": role.value}

    async def update_user(
        self,
        username: str,
        email: Optional[str] = None,
        role: Optional[UserRole] = None,
        permissions: Optional[List[str]] = None,
        is_active: Optional[bool] = None,
    ) -> bool:
        """Update user information."""
        if username not in self.users_db:
            return False

        user_data = self.users_db[username]

        if email:
            user_data["email"] = email
        if role:
            user_data["role"] = role
        if permissions is not None:
            user_data["permissions"] = permissions
        if is_active is not None:
            user_data["is_active"] = is_active

        logger.info(f"User {username} updated")
        return True

    async def delete_user(self, username: str) -> bool:
        """Delete a user."""
        if username not in self.users_db:
            return False

        # Don't allow deleting admin user
        if username == "admin":
            raise ValueError("Cannot delete admin user")

        del self.users_db[username]
        logger.info(f"User {username} deleted")
        return True

    async def change_password(
        self, username: str, old_password: str, new_password: str
    ) -> bool:
        """Change user password."""
        user_data = self.users_db.get(username)

        if not user_data:
            return False

        if not self.verify_password(old_password, user_data["hashed_password"]):
            return False

        user_data["hashed_password"] = self.hash_password(new_password)
        logger.info(f"Password changed for user {username}")
        return True

    def has_permission(self, user: User, permission: str) -> bool:
        """Check if user has a specific permission."""
        if "*" in user.permissions:
            return True
        return permission in user.permissions

    def check_role(self, user: User, required_roles: List[UserRole]) -> bool:
        """Check if user has one of the required roles."""
        return user.role in required_roles


# Singleton instance
auth_manager = AuthManager()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = security_dep,
) -> User:
    """Get current user from JWT token."""
    token = credentials.credentials

    try:
        payload = auth_manager.decode_token(token)
        username = payload.get("sub")

        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )

        user = await auth_manager.get_user(username)

        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found"
            )

        return user

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )


current_user_dep = Depends(get_current_user)


def require_roles(roles: List[UserRole]):
    """Dependency to require specific roles."""
    def role_checker(current_user: User = current_user_dep):
        """Handle role checker."""
        if not auth_manager.check_role(current_user, roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires one of roles: {[r.value for r in roles]}",
            )
        return current_user

    return role_checker


def require_permissions(permissions: List[str]):
    """Dependency to require specific permissions."""
    def permission_checker(current_user: User = current_user_dep):
        """Handle permission checker."""
        for permission in permissions:
            if not auth_manager.has_permission(current_user, permission):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Missing permission: {permission}",
                )
        return current_user

    return permission_checker
