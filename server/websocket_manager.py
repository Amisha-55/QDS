"""
WebSocket Connection & Session Manager

Tracks active client connections by user_id and role (X=sender, Y=receiver),
and provides thread-safe async message dispatching.
"""

import logging
from typing import Any, Dict, Optional
from fastapi import WebSocket

logger = logging.getLogger("qds_gateway.websocket_manager")


class WebSocketManager:
    """Manages active WebSockets and their participant identities."""

    def __init__(self) -> None:
        # Map user_id -> WebSocket
        self._connections: Dict[str, WebSocket] = {}
        # Map user_id -> role string ("sender", "receiver", etc.)
        self._roles: Dict[str, str] = {}
        # Reverse map WebSocket -> user_id
        self._socket_to_user: Dict[WebSocket, str] = {}

    async def connect(self, websocket: WebSocket) -> None:
        """Accept an incoming WebSocket connection."""
        await websocket.accept()
        logger.info("Unregistered WebSocket client connected.")

    async def register(self, websocket: WebSocket, user_id: str, role: str) -> None:
        """
        Register or re-register a client with an identity and role.
        Closes any previously stale connection for the same user_id cleanly.
        """
        if user_id in self._connections:
            old_socket = self._connections[user_id]
            if old_socket != websocket:
                logger.warning("Replacing existing active connection for user %s", user_id)
                self._socket_to_user.pop(old_socket, None)
                try:
                    await old_socket.close(code=1000, reason="Re-registered on new socket")
                except Exception:
                    pass

        self._connections[user_id] = websocket
        self._roles[user_id] = role
        self._socket_to_user[websocket] = user_id
        logger.info("Registered user_id='%s' with role='%s'", user_id, role)

    async def disconnect(self, websocket: WebSocket) -> Optional[str]:
        """Clean up state when a client disconnects."""
        user_id = self._socket_to_user.pop(websocket, None)
        if user_id:
            self._connections.pop(user_id, None)
            self._roles.pop(user_id, None)
            logger.info("Client '%s' disconnected and removed from registry.", user_id)
        else:
            logger.info("Unregistered client disconnected.")
        return user_id

    def get_user_id(self, websocket: WebSocket) -> Optional[str]:
        """Look up user_id for an active socket."""
        return self._socket_to_user.get(websocket)

    def get_role(self, user_id: str) -> Optional[str]:
        """Look up registered role for a user_id."""
        return self._roles.get(user_id)

    def is_connected(self, user_id: str) -> bool:
        """Check if a specific user_id is currently connected."""
        return user_id in self._connections

    def get_socket(self, user_id: str) -> Optional[WebSocket]:
        """Get the active WebSocket for a user_id."""
        return self._connections.get(user_id)

    def get_active_sessions(self) -> Dict[str, Dict[str, str]]:
        """Return a snapshot of active connected sessions."""
        return {
            uid: {"role": self._roles.get(uid, "unknown")}
            for uid in self._connections
        }

    async def send_json(self, user_id: str, data: Dict[str, Any]) -> bool:
        """Send JSON payload to a specific user_id."""
        websocket = self._connections.get(user_id)
        if not websocket:
            logger.warning("Attempted to send to offline user '%s'", user_id)
            return False

        try:
            await websocket.send_json(data)
            return True
        except Exception as exc:
            logger.error("Failed to send message to user '%s': %s", user_id, exc)
            await self.disconnect(websocket)
            return False

    async def broadcast_to_role(self, role: str, data: Dict[str, Any]) -> int:
        """Broadcast JSON payload to all users registered with the given role."""
        sent_count = 0
        target_users = [uid for uid, r in self._roles.items() if r == role]
        for uid in target_users:
            if await self.send_json(uid, data):
                sent_count += 1
        return sent_count
