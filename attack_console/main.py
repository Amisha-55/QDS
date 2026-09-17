"""
QDS Attack Console — Interactive & Automated CLI Tool

A command-line tool for triggering and demonstrating quantum-inspired digital signature attacks
against the running QDS Gateway using the existing research implementations under `src/`.

Usage:
  python -m attack_console
  python -m attack_console --target ws://127.0.0.1:8000/ws --attack replay
  python -m attack_console --host <LAPTOP_IP> --port 8000 --attack all
"""

import os
import sys
import argparse
from typing import Any, Dict, Optional, Tuple

# Ensure src/ and root are in sys.path
ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_PATH = os.path.join(ROOT_PATH, "src")
for p in [ROOT_PATH, SRC_PATH]:
    if p not in sys.path:
        sys.path.insert(0, p)

from server.handlers import ensure_user_keys
from replay_attack import build_replay_packet
from attack_console.client import GatewayClient
from attack_console.attacks.forgery import prepare_forgery_packet
from attack_console.attacks.impersonation import prepare_impersonation_packet
from attack_console.attacks.replay import prepare_replay_packet
from attack_console.attacks.channel_manipulation import prepare_channel_manipulated_packet

DEFAULT_TARGET = os.getenv("QDS_GATEWAY_WS", "ws://127.0.0.1:8000/ws")
DEFAULT_MESSAGE = "QDS-Quantum-Signature-Payload"
DEFAULT_SENDER = "X"
DEFAULT_RECEIVER = "Y"


def display_banner(target_url: str) -> None:
    """Display the attack console header banner."""
    print("=====================================")
    print("         QDS ATTACK CONSOLE          ")
    print("=====================================")
    print(f"Target: {target_url}\n")


def display_attack_result(attack_name: str, response: Dict[str, Any]) -> None:
    """
    Format and display the real cryptographic result returned by the gateway.
    Displays only verified fields from the existing research pipeline.
    """
    details = response.get("details", {})
    security = details.get("security", {})

    final_decision = security.get("final_decision") or details.get("final_decision", "UNKNOWN")
    detected_type = security.get("likely_attack_type") or details.get("likely_attack_type", "UNKNOWN")
    classical_valid = security.get("classical_signature_valid", "N/A")
    qds_valid = security.get("qds_valid", "N/A")
    replay_detected = security.get("replay_detected", False)
    accuracy = security.get("verification_accuracy", 0.0)
    error_rate = security.get("error_rate", 0.0)
    shots = security.get("total_shots", 0)

    print("\n=====================================")
    print("          ATTACK RESULT              ")
    print("=====================================")
    print(f"Attack:                    {attack_name}")
    print(f"Final Decision:            {final_decision}")
    print(f"Detected Type:             {detected_type}")
    print(f"Classical Signature Valid: {classical_valid}")
    print(f"QDS Verification Valid:    {qds_valid}")
    print(f"Replay Detected:           {replay_detected}")
    print(f"Verification Accuracy:     {accuracy:.4f}")
    print(f"Error Rate:                {error_rate:.4f}")
    if shots > 0:
        print(f"Quantum Shots Measured:    {shots}")
    print("=====================================\n")


def get_legitimate_baseline(
    sender_id: str,
    message: str,
) -> Tuple[Dict[str, Any], Any]:
    """Generate a legitimate signed packet using existing research functions."""
    private_key, _ = ensure_user_keys(sender_id)
    packet = build_replay_packet(
        message=message,
        private_key=private_key,
        signer_id=sender_id,
    )
    return packet, private_key


def execute_forgery_attack(
    client: GatewayClient,
    sender_id: str = DEFAULT_SENDER,
    receiver_id: str = DEFAULT_RECEIVER,
    message: str = DEFAULT_MESSAGE,
) -> Dict[str, Any]:
    """Execute Forgery Attack: Modifies message payload without re-signing."""
    print("Connected to QDS Gateway")
    print("Attack selected: Forgery Attack")
    print("Preparing legitimate baseline packet...")
    legit_packet, _ = get_legitimate_baseline(sender_id, message)

    print("Tampering with message payload (simulate_forgery)...")
    forged_packet = prepare_forgery_packet(legit_packet, forged_message=f"FORGED-{message}")

    print("Packet prepared. Dispatching forged packet to gateway...")
    response = client.dispatch_packet(
        sender_id=sender_id,
        receiver_id=receiver_id,
        packet=forged_packet,
    )
    print("Gateway response received.")
    display_attack_result("Forgery", response)
    return response


def execute_impersonation_attack(
    client: GatewayClient,
    claimed_sender_id: str = DEFAULT_SENDER,
    receiver_id: str = DEFAULT_RECEIVER,
    message: str = DEFAULT_MESSAGE,
) -> Dict[str, Any]:
    """Execute Impersonation Attack: Rogue keypair claiming legitimate identity."""
    print("Connected to QDS Gateway")
    print("Attack selected: Impersonation Attack")
    print(f"Generating rogue keypair claiming identity '{claimed_sender_id}' (simulate_impersonation)...")
    impersonated_packet = prepare_impersonation_packet(
        message=message,
        claimed_signer_id=claimed_sender_id,
    )

    print("Packet prepared. Dispatching impersonated packet to gateway...")
    response = client.dispatch_packet(
        sender_id=claimed_sender_id,
        receiver_id=receiver_id,
        packet=impersonated_packet,
    )
    print("Gateway response received.")
    display_attack_result("Impersonation", response)
    return response


def execute_replay_attack(
    client: GatewayClient,
    sender_id: str = DEFAULT_SENDER,
    receiver_id: str = DEFAULT_RECEIVER,
    message: str = DEFAULT_MESSAGE,
) -> Dict[str, Any]:
    """
    Execute Replay Attack:
    1. Sends legitimate packet (first send -> accepted).
    2. Sends identical copy with identical signature_id (second send -> caught).
    """
    print("Connected to QDS Gateway")
    print("Attack selected: Replay Attack")
    print("Step 1: Generating and dispatching legitimate original packet...")
    legit_packet, _ = get_legitimate_baseline(sender_id, message)

    resp_orig = client.dispatch_packet(
        sender_id=sender_id,
        receiver_id=receiver_id,
        packet=legit_packet,
    )
    print("Step 1 Response (Original):", resp_orig.get("details", {}).get("final_decision", "ACCEPTED"))

    print("Step 2: Replaying identical packet with repeated signature_id (simulate_replay)...")
    replayed_packet = prepare_replay_packet(legit_packet)

    print("Dispatching replayed packet to gateway...")
    response = client.dispatch_packet(
        sender_id=sender_id,
        receiver_id=receiver_id,
        packet=replayed_packet,
    )
    print("Gateway response received.")
    display_attack_result("Replay", response)
    return response


def execute_channel_manipulation_attack(
    client: GatewayClient,
    sender_id: str = DEFAULT_SENDER,
    receiver_id: str = DEFAULT_RECEIVER,
    message: str = DEFAULT_MESSAGE,
    attack_type: str = "bit_flip",
) -> Dict[str, Any]:
    """Execute Channel Manipulation Attack: Pauli bit-flip across quantum teleportation elements."""
    print("Connected to QDS Gateway")
    print(f"Attack selected: Channel Manipulation ({attack_type})")
    print("Preparing legitimate baseline packet...")
    legit_packet, private_key = get_legitimate_baseline(sender_id, message)

    print(f"Simulating Pauli {attack_type} across quantum states (channel_manipulation.run_experiment)...")
    manipulated_packet = prepare_channel_manipulated_packet(
        legitimate_packet=legit_packet,
        private_key=private_key,
        attack_type=attack_type,
    )

    print("Packet prepared. Dispatching channel-manipulated packet to gateway...")
    response = client.dispatch_packet(
        sender_id=sender_id,
        receiver_id=receiver_id,
        packet=manipulated_packet,
    )
    print("Gateway response received.")
    display_attack_result(f"Channel Manipulation ({attack_type})", response)
    return response


def run_interactive_menu(client: GatewayClient) -> None:
    """Interactive console menu loop."""
    while True:
        display_banner(client.ws_url)
        print("1. Forgery Attack")
        print("2. Impersonation Attack")
        print("3. Replay Attack")
        print("4. Channel Manipulation")
        print("5. Exit")

        try:
            choice = input("\nSelect attack (1-5): ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nExiting attack console.")
            break

        if choice == "1":
            execute_forgery_attack(client)
        elif choice == "2":
            execute_impersonation_attack(client)
        elif choice == "3":
            execute_replay_attack(client)
        elif choice == "4":
            execute_channel_manipulation_attack(client)
        elif choice == "5":
            print("Exiting attack console.")
            break
        else:
            print("Invalid selection. Please enter 1-5.")

        input("\nPress Enter to continue...")
        print("\n" * 2)


def main() -> None:
    """CLI entrypoint with argument parser."""
    parser = argparse.ArgumentParser(
        description="QDS Attack Console — CLI interface for demonstrating attacks against the QDS Gateway."
    )
    parser.add_argument(
        "--target",
        type=str,
        default=None,
        help="Target WebSocket URL (e.g., ws://127.0.0.1:8000/ws or ws://192.168.1.100:8000/ws)",
    )
    parser.add_argument(
        "--host",
        type=str,
        default="127.0.0.1",
        help="Gateway host address (used if --target is not set)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Gateway port (used if --target is not set)",
    )
    parser.add_argument(
        "--attack",
        type=str,
        choices=["forgery", "impersonation", "replay", "channel", "all"],
        help="Specific attack to run non-interactively",
    )
    parser.add_argument(
        "--message",
        type=str,
        default=DEFAULT_MESSAGE,
        help="Custom test message content",
    )
    parser.add_argument(
        "--sender",
        type=str,
        default=DEFAULT_SENDER,
        help="Sender identifier (default: X)",
    )
    parser.add_argument(
        "--receiver",
        type=str,
        default=DEFAULT_RECEIVER,
        help="Receiver identifier (default: Y)",
    )

    args = parser.parse_args()

    # Determine target WebSocket URL
    target_url = args.target or os.getenv("QDS_GATEWAY_WS") or f"ws://{args.host}:{args.port}/ws"
    client = GatewayClient(ws_url=target_url)

    if args.attack:
        display_banner(target_url)
        if args.attack == "forgery" or args.attack == "all":
            execute_forgery_attack(client, args.sender, args.receiver, args.message)
        if args.attack == "impersonation" or args.attack == "all":
            execute_impersonation_attack(client, args.sender, args.receiver, args.message)
        if args.attack == "replay" or args.attack == "all":
            execute_replay_attack(client, args.sender, args.receiver, args.message)
        if args.attack == "channel" or args.attack == "all":
            execute_channel_manipulation_attack(client, args.sender, args.receiver, args.message)
    else:
        run_interactive_menu(client)


if __name__ == "__main__":
    main()
