import os
import logging
import ssl
import tempfile
from aioapns import APNs, NotificationRequest, PushType
from app.core.config import settings

logger = logging.getLogger(__name__)

class notificationClient:
    def __init__(self):
        self.client = None
        self._key_path = None

    def _materialize_key_file(self) -> str:
        if not settings.APNS_AUTH_KEY.strip():
            raise RuntimeError(
                "APNS_AUTH_KEY is not configured. Set it to the contents of the Apple .p8 key."
            )

        # Restore real newlines if the env var was stored with literal "\n" escapes.
        key_pem = settings.APNS_AUTH_KEY.replace("\\n", "\n")
        with tempfile.NamedTemporaryFile(suffix=".p8", delete=False) as tf:
            tf.write(key_pem.encode())
            return tf.name

    def _initialize_client(self):
        try:
            if not self._key_path or not os.path.exists(self._key_path):
                self._key_path = self._materialize_key_file()
            key_path = self._key_path

            # SSL context configuration
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE

            # Initialize APNs client
            self.client = APNs(
                key=key_path,
                key_id=settings.APNS_AUTH_KEY_ID,
                team_id=settings.APNS_TEAM_ID,
                topic=settings.APNS_BUNDLE_ID,
                use_sandbox=settings.APNS_USE_SANDBOX,
                ssl_context=ssl_context
            )

            logger.info("Successfully initialized APNs client")
        except Exception as e:
            logger.error(f"Failed to initialize APNs client: {str(e)}", exc_info=True)
            raise

    async def send_notification(
        self,
        device_token: str,
        title: str,
        body: str,
        data: dict = None,
        sound: str = "default",
        badge: int = None,
        category: str = None
    ) -> bool:
        """
        Send push notification
        
        Args:
            device_token (str): Device token
            title (str): Notification title
            body (str): Notification body
            data (dict, optional): Additional data
            sound (str, optional): Notification sound
            badge (int, optional): Badge count
            category (str, optional): Notification category identifier
            
        Returns:
            bool: True on successful send, False on failure
        """
        try:
            if not self.client:
                self._initialize_client()

            logger.info(f"Sending notification to device token: {device_token}")
            logger.info(f"Notification content - title: {title}, body: {body}")

            # Create notification request
            aps_payload = {
                "alert": {
                    "title": title,
                    "body": body
                },
                "sound": sound,
                "badge": badge,
            }
            
            # Add category to aps if provided
            if category:
                aps_payload["category"] = category
            
            request = NotificationRequest(
                device_token=device_token,
                message={
                    "aps": aps_payload,
                    **(data or {})
                },
                push_type=PushType.ALERT
            )

            # Send notification
            logger.info("Sending notification request...")
            response = await self.client.send_notification(request)
            
            if response.is_successful:
                logger.info(f"Successfully sent notification to {device_token}")
                return True
            else:
                logger.error(f"Failed to send notification: {response.description}")
                return False

        except Exception as e:
            logger.error(f"Error sending push notification: {str(e)}", exc_info=True)
            return False

    async def send_silent_notification(
        self,
        device_token: str,
        data: dict = None,
        category: str = None,
        max_retries: int = 3
    ) -> bool:
        """
        Send silent push notification with retry logic
        
        Args:
            device_token (str): Device token
            data (dict, optional): Additional data
            category (str, optional): Notification category identifier
            max_retries (int): Maximum number of retry attempts
            
        Returns:
            bool: True on successful send, False on failure
        """
        for attempt in range(max_retries + 1):
            try:
                if not self.client or attempt > 0:
                    logger.info(f"[APNS_RETRY] Initializing APNs client (attempt {attempt + 1}/{max_retries + 1}) for device {device_token}")
                    self._initialize_client()

                logger.info(f"[APNS_RETRY] Sending silent notification to device token: {device_token} (attempt {attempt + 1}/{max_retries + 1})")

                # Create silent notification request
                aps_payload = {
                    "content-available": 1
                }
                
                # Add category to aps if provided
                if category:
                    aps_payload["category"] = category
                
                request = NotificationRequest(
                    device_token=device_token,
                    message={
                        "aps": aps_payload,
                        **(data or {})
                    },
                    push_type=PushType.BACKGROUND,
                    priority=5
                )

                # Send notification
                logger.info(f"[APNS_RETRY] Sending silent notification request (attempt {attempt + 1})...")
                response = await self.client.send_notification(request)
                
                if response.is_successful:
                    logger.info(f"[APNS_RETRY] ✅ Successfully sent silent notification to {device_token} on attempt {attempt + 1}")
                    return True
                else:
                    logger.error(f"[APNS_RETRY] ❌ Failed to send silent notification (attempt {attempt + 1}): {response.description}")
                    if attempt == max_retries:
                        logger.error(f"[APNS_RETRY] 🚫 All {max_retries + 1} attempts failed for device {device_token}")
                        return False

            except Exception as e:
                logger.error(f"[APNS_RETRY] ❌ Error sending silent push notification (attempt {attempt + 1}/{max_retries + 1}): {str(e)}")
                if attempt == max_retries:
                    logger.error(f"[APNS_RETRY] 🚫 All {max_retries + 1} attempts failed for device {device_token}")
                    return False
                else:
                    logger.info(f"[APNS_RETRY] 🔄 Retrying in next attempt...")
                    # Reset client for retry
                    self.client = None
        
        return False
