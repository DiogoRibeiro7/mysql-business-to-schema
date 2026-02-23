"""
WebSocket client for real-time updates
"""

import json
import logging
import threading
from typing import Callable, Dict, Any, Optional
import websocket

logger = logging.getLogger(__name__)


class WebSocketClient:
    """
    WebSocket client for real-time updates from MySQL Business-to-Schema API.
    """

    def __init__(
        self,
        host: str,
        token: Optional[str] = None,
        auto_reconnect: bool = True,
        reconnect_interval: int = 5
    ):
        """
        Initialize WebSocket client.

        Args:
            host: WebSocket server URL
            token: Authentication token
            auto_reconnect: Enable auto-reconnection
            reconnect_interval: Seconds between reconnection attempts
        """
        self.host = host
        self.token = token
        self.auto_reconnect = auto_reconnect
        self.reconnect_interval = reconnect_interval

        self.ws = None
        self.connected = False
        self.running = False
        self.thread = None

        # Event handlers
        self.handlers: Dict[str, list] = {}

    def connect(self):
        """Connect to WebSocket server."""
        if self.connected:
            logger.warning("Already connected to WebSocket")
            return

        # Build WebSocket URL with authentication
        url = self.host
        if self.token:
            url += f"?token={self.token}"

        self.ws = websocket.WebSocketApp(
            url,
            on_open=self._on_open,
            on_message=self._on_message,
            on_error=self._on_error,
            on_close=self._on_close
        )

        # Run WebSocket in a separate thread
        self.running = True
        self.thread = threading.Thread(target=self._run_forever)
        self.thread.daemon = True
        self.thread.start()

        logger.info(f"Connecting to WebSocket: {self.host}")

    def disconnect(self):
        """Disconnect from WebSocket server."""
        self.running = False
        self.auto_reconnect = False

        if self.ws:
            self.ws.close()

        if self.thread:
            self.thread.join(timeout=5)

        self.connected = False
        logger.info("Disconnected from WebSocket")

    def close(self):
        """Alias for disconnect."""
        self.disconnect()

    def on(self, event: str, handler: Callable[[Dict], None]):
        """
        Register event handler.

        Args:
            event: Event name
            handler: Callback function

        Example:
            >>> def on_metrics(data):
            ...     print(f"CPU: {data['cpu']}%")
            >>> client.on("metrics:update", on_metrics)
        """
        if event not in self.handlers:
            self.handlers[event] = []
        self.handlers[event].append(handler)

    def off(self, event: str, handler: Optional[Callable] = None):
        """
        Remove event handler.

        Args:
            event: Event name
            handler: Specific handler to remove (all if None)
        """
        if event not in self.handlers:
            return

        if handler:
            self.handlers[event] = [
                h for h in self.handlers[event] if h != handler
            ]
        else:
            del self.handlers[event]

    def emit(self, event: str, data: Optional[Dict] = None):
        """
        Send event to server.

        Args:
            event: Event name
            data: Event data

        Example:
            >>> client.emit("subscribe", {"channels": ["metrics", "alerts"]})
        """
        if not self.connected:
            logger.warning("Cannot emit: not connected to WebSocket")
            return

        message = {
            "event": event,
            "data": data or {}
        }

        try:
            self.ws.send(json.dumps(message))
        except Exception as e:
            logger.error(f"Failed to send WebSocket message: {e}")

    def subscribe(self, channels: list):
        """
        Subscribe to specific channels.

        Args:
            channels: List of channel names

        Example:
            >>> client.subscribe(["metrics", "alerts", "migrations"])
        """
        self.emit("subscribe", {"channels": channels})

    def unsubscribe(self, channels: list):
        """
        Unsubscribe from channels.

        Args:
            channels: List of channel names
        """
        self.emit("unsubscribe", {"channels": channels})

    def _on_open(self, ws):
        """Handle WebSocket connection open."""
        self.connected = True
        logger.info("WebSocket connected")

        # Trigger connected event
        self._trigger_event("connected", {})

    def _on_message(self, ws, message):
        """Handle incoming WebSocket message."""
        try:
            data = json.loads(message)
            event = data.get("event", "message")
            payload = data.get("data", {})

            # Trigger event handlers
            self._trigger_event(event, payload)

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse WebSocket message: {e}")
        except Exception as e:
            logger.error(f"Error handling WebSocket message: {e}")

    def _on_error(self, ws, error):
        """Handle WebSocket error."""
        logger.error(f"WebSocket error: {error}")
        self._trigger_event("error", {"error": str(error)})

    def _on_close(self, ws, close_status_code, close_msg):
        """Handle WebSocket connection close."""
        self.connected = False
        logger.info(f"WebSocket closed: {close_status_code} - {close_msg}")

        self._trigger_event("disconnected", {
            "code": close_status_code,
            "reason": close_msg
        })

        # Auto-reconnect if enabled
        if self.auto_reconnect and self.running:
            logger.info(f"Reconnecting in {self.reconnect_interval} seconds...")
            threading.Timer(self.reconnect_interval, self.connect).start()

    def _trigger_event(self, event: str, data: Dict[str, Any]):
        """Trigger event handlers."""
        # Call specific event handlers
        if event in self.handlers:
            for handler in self.handlers[event]:
                try:
                    handler(data)
                except Exception as e:
                    logger.error(f"Error in event handler for {event}: {e}")

        # Call wildcard handlers
        if "*" in self.handlers:
            for handler in self.handlers["*"]:
                try:
                    handler({"event": event, "data": data})
                except Exception as e:
                    logger.error(f"Error in wildcard handler: {e}")

    def _run_forever(self):
        """Run WebSocket connection loop."""
        while self.running:
            try:
                self.ws.run_forever()
            except Exception as e:
                logger.error(f"WebSocket run_forever error: {e}")

            if self.running and self.auto_reconnect:
                threading.Event().wait(self.reconnect_interval)