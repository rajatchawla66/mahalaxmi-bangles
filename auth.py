"""
Hardcoded login. Two roles:
    - admin:  full access
    - labour: View Orders only, no prices, no Rate List, no Create Order

Replace the credentials before shipping.
"""

USERS = {
    "admin":  {"password": "admin123",  "role": "admin"},
    "labour": {"password": "labour123", "role": "labour"},
}


def authenticate(username: str, password: str):
    """Return (role, None) on success, or (None, error_msg) on failure."""
    if not username or not password:
        return None, "Please enter both username and password."
    user = USERS.get(username.strip().lower())
    if user and user["password"] == password:
        return user["role"], None
    return None, "Invalid username or password."
