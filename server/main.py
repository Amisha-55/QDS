"""
QDS Network Gateway — Main Application Server

A thin, high-performance FastAPI + WebSocket gateway providing routing and
session management for Flutter clients (X = Sender, Y = Receiver) while
delegating all cryptographic operations to the existing research core (src/).
"""

import os
import sys
import logging
from typing import Any, Dict, Optional

# Ensure research modules are on the path
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from server.websocket_manager import WebSocketManager
from server.protocol import (
    TYPE_REGISTER,
    TYPE_MESSAGE,
    TYPE_PACKET,
    VALID_ROLES,
    ERR_INVALID_JSON,
    ERR_MISSING_FIELD,
    ERR_INVALID_FIELD,
    ERR_UNKNOWN_TYPE,
    ERR_NOT_REGISTERED,
    ERR_RECEIVER_OFFLINE,
    ERR_PROCESSING_FAILED,
    create_error_message,
    create_registered_message,
    create_ack_message,
    now_utc_iso,
)
from server.handlers import process_message, process_raw_packet, ensure_user_keys

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("qds_gateway")

app = FastAPI(
    title="QDS Network Gateway",
    description="Thin WebSocket & REST routing gateway for Quantum Digital Signature security layer",
    version="1.0.0",
)

# Allow cross-origin requests for mobile, emulator, and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

manager = WebSocketManager()


# ------------------------------------------------------------
# REST Endpoints
# ------------------------------------------------------------

@app.get("/", tags=["Metadata"])
async def root() -> Dict[str, Any]:
    """Gateway health and active session overview."""
    return {
        "service": "QDS Network Gateway",
        "status": "online",
        "version": "1.0.0",
        "timestamp": now_utc_iso(),
        "active_sessions": manager.get_active_sessions(),
    }


@app.get("/health", tags=["Health"])
async def health_check() -> Dict[str, str]:
    """Simple probe endpoint."""
    return {"status": "healthy"}


@app.get("/sessions", tags=["Sessions"])
async def list_sessions() -> Dict[str, Any]:
    """Return currently registered sender and receiver sessions."""
    return {
        "count": len(manager.get_active_sessions()),
        "sessions": manager.get_active_sessions(),
    }


class VerifyRequest(BaseModel):
    sender_id: str
    receiver_id: str
    packet: Dict[str, Any]
    threshold: Optional[float] = 0.95


@app.post("/security/verify", tags=["Security"])
async def verify_packet_endpoint(req: VerifyRequest) -> Dict[str, Any]:
    """
    REST endpoint to verify a pre-constructed or intercepted packet
    using the existing research security pipeline.
    """
    try:
        envelope = process_raw_packet(
            sender_id=req.sender_id,
            receiver_id=req.receiver_id,
            packet=req.packet,
            threshold=req.threshold or 0.95,
        )
        return envelope
    except Exception as exc:
        logger.error("REST verification failed: %s", exc)
        return create_error_message(ERR_PROCESSING_FAILED, str(exc))


# ------------------------------------------------------------
# WebSocket Route
# ------------------------------------------------------------

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """
    Primary WebSocket endpoint for Flutter X (Sender) and Flutter Y (Receiver).
    Supports:
      - 'register': establish session identity (user_id and role)
      - 'message': send plaintext message (processed via full QDS pipeline)
      - 'packet': send raw/attack packet (verified via QDS pipeline)
    """
    await manager.connect(websocket)

    try:
        while True:
            try:
                data = await websocket.receive_json()
            except Exception:
                logger.warning("Received invalid or non-JSON frame from client.")
                await websocket.send_json(
                    create_error_message(ERR_INVALID_JSON, "Payload must be a valid JSON object.")
                )
                continue

            if not isinstance(data, dict):
                await websocket.send_json(
                    create_error_message(ERR_INVALID_JSON, "Root message must be a JSON object.")
                )
                continue

            msg_type = data.get("type")
            if not msg_type:
                await websocket.send_json(
                    create_error_message(ERR_MISSING_FIELD, "Missing 'type' field in payload.")
                )
                continue

            # --------------------------------------------------------
            # 1. Registration (X or Y)
            # --------------------------------------------------------
            if msg_type == TYPE_REGISTER:
                user_id = data.get("user_id")
                role = data.get("role")

                if not user_id or not isinstance(user_id, str):
                    await websocket.send_json(
                        create_error_message(ERR_MISSING_FIELD, "Valid string 'user_id' is required for registration.")
                    )
                    continue

                if not role or role not in VALID_ROLES:
                    await websocket.send_json(
                        create_error_message(
                            ERR_INVALID_FIELD,
                            f"Valid role ({', '.join(VALID_ROLES)}) is required for registration.",
                        )
                    )
                    continue

                # Pre-generate / verify keys for the participant
                ensure_user_keys(user_id)

                await manager.register(websocket, user_id=user_id, role=role)
                await websocket.send_json(create_registered_message(user_id=user_id, role=role))
                continue

            # --------------------------------------------------------
            # 2. Standard Message (Flutter X -> QDS Core -> Flutter Y)
            # --------------------------------------------------------
            elif msg_type == TYPE_MESSAGE:
                sender_id = data.get("sender_id") or manager.get_user_id(websocket)
                receiver_id = data.get("receiver_id")
                message_text = data.get("message")

                if not sender_id:
                    await websocket.send_json(
                        create_error_message(ERR_NOT_REGISTERED, "Sender is not registered.")
                    )
                    continue

                if not receiver_id:
                    await websocket.send_json(
                        create_error_message(ERR_MISSING_FIELD, "Missing required 'receiver_id'.")
                    )
                    continue

                if not isinstance(message_text, str) or not message_text.strip():
                    await websocket.send_json(
                        create_error_message(ERR_MISSING_FIELD, "Field 'message' cannot be empty.")
                    )
                    continue

                # Execute existing research security pipeline
                try:
                    envelope = process_message(
                        sender_id=sender_id,
                        receiver_id=receiver_id,
                        message=message_text,
                    )
                except Exception as exc:
                    logger.error("Security pipeline processing error: %s", exc, exc_info=True)
                    await websocket.send_json(
                        create_error_message(
                            ERR_PROCESSING_FAILED,
                            f"Cryptographic processing error: {exc}",
                        )
                    )
                    continue

                # Route envelope to receiver Y if connected
                receiver_delivered = await manager.send_json(receiver_id, envelope)

                # Send acknowledgment to sender X
                ack_status = "delivered" if receiver_delivered else "receiver_offline"
                ack_details = {
                    "receiver_connected": receiver_delivered,
                    "final_decision": envelope["security"]["final_decision"],
                    "likely_attack_type": envelope["security"]["likely_attack_type"],
                    "verification_accuracy": envelope["security"]["verification_accuracy"],
                    "security": envelope["security"],
                }

                if not receiver_delivered:
                    logger.warning("Receiver '%s' is offline; message held in acknowledgment.", receiver_id)

                await websocket.send_json(
                    create_ack_message(
                        message_id=envelope["message_id"],
                        status=ack_status,
                        details=ack_details,
                    )
                )
                continue

            # --------------------------------------------------------
            # 3. Raw Packet (e.g., Attack console or pre-signed packets)
            # --------------------------------------------------------
            elif msg_type == TYPE_PACKET:
                sender_id = data.get("sender_id") or manager.get_user_id(websocket) or "UNKNOWN"
                receiver_id = data.get("receiver_id")
                raw_packet = data.get("packet")

                if not receiver_id:
                    await websocket.send_json(
                        create_error_message(ERR_MISSING_FIELD, "Missing required 'receiver_id'.")
                    )
                    continue

                if not isinstance(raw_packet, dict):
                    await websocket.send_json(
                        create_error_message(ERR_INVALID_FIELD, "Field 'packet' must be a dictionary.")
                    )
                    continue

                # Verify raw packet via existing research pipeline
                try:
                    envelope = process_raw_packet(
                        sender_id=sender_id,
                        receiver_id=receiver_id,
                        packet=raw_packet,
                    )
                except Exception as exc:
                    logger.error("Raw packet verification error: %s", exc, exc_info=True)
                    await websocket.send_json(
                        create_error_message(
                            ERR_PROCESSING_FAILED,
                            f"Packet verification error: {exc}",
                        )
                    )
                    continue

                # Route to receiver Y
                receiver_delivered = await manager.send_json(receiver_id, envelope)

                # Acknowledge to sender
                await websocket.send_json(
                    create_ack_message(
                        message_id=envelope["message_id"],
                        status="delivered" if receiver_delivered else "receiver_offline",
                        details={
                            "receiver_connected": receiver_delivered,
                            "final_decision": envelope["security"]["final_decision"],
                            "likely_attack_type": envelope["security"]["likely_attack_type"],
                            "verification_accuracy": envelope["security"]["verification_accuracy"],
                            "security": envelope["security"],
                        },
                    )
                )
                continue

            # --------------------------------------------------------
            # Unknown message type
            # --------------------------------------------------------
            else:
                logger.warning("Unknown message type received: '%s'", msg_type)
                await websocket.send_json(
                    create_error_message(ERR_UNKNOWN_TYPE, f"Unknown message type '{msg_type}'.")
                )

    except WebSocketDisconnect:
        disconnected_user = await manager.disconnect(websocket)
        logger.info("WebSocket disconnect handled cleanly for user '%s'", disconnected_user)
    except Exception as exc:
        logger.error("Unexpected WebSocket handler error: %s", exc, exc_info=True)
        await manager.disconnect(websocket)


# ------------------------------------------------------------
# Runner
# ------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    # Listen on all local interfaces so physical devices on same Wi-Fi can connect
    uvicorn.run(app, host="0.0.0.0", port=8000)
