import json
import os

SESSION_DIR_ENV = "FLET_APP_STORAGE_DATA"
SESSION_FILENAME = "customer_session.json"

def _session_path():
    d = os.environ.get(SESSION_DIR_ENV, ".")
    return os.path.join(d, SESSION_FILENAME)


def save_session(state):
    path = _session_path()
    data = {
        "role": state.get("role"),
        "username": state.get("username"),
        "customer_mobile": state.get("customer_mobile"),
        "customer_id": state.get("customer_id"),
        "customer_shop_name": state.get("customer_shop_name"),
    }
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)


def load_session():
    path = _session_path()
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def clear_session():
    path = _session_path()
    try:
        if os.path.exists(path):
            os.remove(path)
    except Exception:
        pass
