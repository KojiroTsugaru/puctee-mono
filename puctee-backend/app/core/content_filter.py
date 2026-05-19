"""
Content filtering utility for detecting and filtering inappropriate content.
Uses better-profanity library for profanity detection.
"""
from better_profanity import profanity
from typing import Tuple

# Initialize profanity filter
profanity.load_censor_words()

# Additional custom words to filter (can be extended)
CUSTOM_OFFENSIVE_WORDS = [
    # Add any app-specific offensive terms here
]

# Load custom words if any
if CUSTOM_OFFENSIVE_WORDS:
    profanity.add_censor_words(CUSTOM_OFFENSIVE_WORDS)


def contains_profanity(text: str) -> bool:
    """
    Check if text contains profanity or offensive content.
    
    Args:
        text: The text to check
        
    Returns:
        True if profanity is detected, False otherwise
    """
    if not text:
        return False
    
    return profanity.contains_profanity(text)


def censor_profanity(text: str, censor_char: str = "*") -> str:
    """
    Censor profanity in text by replacing with censor characters.
    
    Args:
        text: The text to censor
        censor_char: Character to use for censoring (default: *)
        
    Returns:
        Censored text
    """
    if not text:
        return text
    
    return profanity.censor(text, censor_char)


def validate_content(text: str, allow_profanity: bool = False) -> Tuple[bool, str]:
    """
    Validate user-generated content for appropriateness.
    
    Args:
        text: The text to validate
        allow_profanity: Whether to allow profanity (default: False)
        
    Returns:
        Tuple of (is_valid, error_message)
        - is_valid: True if content is appropriate, False otherwise
        - error_message: Description of why content was rejected (empty if valid)
    """
    if not text:
        return True, ""
    
    # Check for profanity
    if not allow_profanity and contains_profanity(text):
        return False, "Content contains inappropriate language"
    
    # Additional checks can be added here:
    # - Spam detection
    # - Hate speech detection
    # - URL spam detection
    # etc.
    
    return True, ""


def filter_user_input(
    text: str,
    max_length: int = 1000,
    allow_profanity: bool = False
) -> Tuple[bool, str, str]:
    """
    Comprehensive filter for user input with validation and sanitization.
    
    Args:
        text: The text to filter
        max_length: Maximum allowed length
        allow_profanity: Whether to allow profanity
        
    Returns:
        Tuple of (is_valid, filtered_text, error_message)
    """
    if not text:
        return True, "", ""
    
    # Strip whitespace
    text = text.strip()
    
    # Check length
    if len(text) > max_length:
        return False, text, f"Content exceeds maximum length of {max_length} characters"
    
    # Validate content
    is_valid, error_msg = validate_content(text, allow_profanity)
    
    if not is_valid:
        return False, text, error_msg
    
    return True, text, ""
