"""Cryptographic services for MaskerV — Authenticated AES-256-GCM encryption & secure key derivation."""
import os
import hmac
import hashlib
import secrets
import bcrypt
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

PBKDF2_ITERATIONS = 100_000
SALT_SIZE_BYTES = 16
NONCE_SIZE_BYTES = 12
KEY_SIZE_BYTES = 32  # 256 bits


def derive_encryption_key(password: str, salt: bytes) -> bytes:
    """Derive a 256-bit cryptographic key from password and salt using PBKDF2-HMAC-SHA256."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_SIZE_BYTES,
        salt=salt,
        iterations=PBKDF2_ITERATIONS,
    )
    return kdf.derive(password.encode("utf-8"))


def generate_verifier_hash(derived_key: bytes) -> str:
    """Generate a bcrypt hash of an HMAC authentication tag computed from the derived key.
    
    The plaintext password is NEVER stored or logged.
    Only this verification hash is stored in the database.
    """
    token_tag = hmac.new(derived_key, b"maskerv_temp_share_verify", hashlib.sha256).digest()
    salt = bcrypt.gensalt(rounds=10)
    return bcrypt.hashpw(token_tag, salt).decode("utf-8")


def check_verifier_password(password: str, salt: bytes, verifier_hash: str) -> bool:
    """Verify if the provided password matches the stored verifier hash."""
    try:
        derived_key = derive_encryption_key(password, salt)
        token_tag = hmac.new(derived_key, b"maskerv_temp_share_verify", hashlib.sha256).digest()
        if bcrypt.checkpw(token_tag, verifier_hash.encode("utf-8")):
            return True
        # Fallback for shares created prior to rebranding
        legacy_tag = hmac.new(derived_key, b"paperkit_temp_share_verify", hashlib.sha256).digest()
        return bcrypt.checkpw(legacy_tag, verifier_hash.encode("utf-8"))
    except Exception:
        return False


def encrypt_temporary_file(file_bytes: bytes, password: str, share_id: str) -> dict:
    """Encrypt file bytes using AES-256-GCM with a unique salt and nonce.
    
    Returns:
      {
        "ciphertext": bytes,
        "salt_hex": str,
        "nonce_hex": str,
        "verifier_hash": str
      }
    """
    salt = secrets.token_bytes(SALT_SIZE_BYTES)
    nonce = secrets.token_bytes(NONCE_SIZE_BYTES)
    derived_key = derive_encryption_key(password, salt)
    verifier_hash = generate_verifier_hash(derived_key)

    aesgcm = AESGCM(derived_key)
    # Bind share_id as associated data (AAD) to prevent ciphertext transplantation
    ciphertext = aesgcm.encrypt(nonce, file_bytes, share_id.encode("utf-8"))

    return {
        "ciphertext": ciphertext,
        "salt_hex": salt.hex(),
        "nonce_hex": nonce.hex(),
        "verifier_hash": verifier_hash,
    }


def decrypt_temporary_file(
    ciphertext: bytes,
    password: str,
    salt_hex: str,
    nonce_hex: str,
    share_id: str,
) -> bytes:
    """Decrypt file bytes using AES-256-GCM.
    
    Raises ValueError if password is invalid, ciphertext is tampered, or authentication tag fails.
    """
    salt = bytes.fromhex(salt_hex)
    nonce = bytes.fromhex(nonce_hex)
    derived_key = derive_encryption_key(password, salt)

    aesgcm = AESGCM(derived_key)
    try:
        decrypted = aesgcm.decrypt(nonce, ciphertext, share_id.encode("utf-8"))
        return decrypted
    except Exception as e:
        raise ValueError("Decryption failed: invalid credentials or corrupted ciphertext.") from e
