"""Tests for AES-256-GCM authenticated encryption and key derivation."""
import pytest
from services.crypto_service import (
    derive_encryption_key,
    generate_verifier_hash,
    check_verifier_password,
    encrypt_temporary_file,
    decrypt_temporary_file,
)


def test_encryption_roundtrip():
    data = b"MaskerV Confidential Document Content 2026"
    password = "SuperSecurePassword987!"
    share_id = "test_share_001"

    enc = encrypt_temporary_file(data, password, share_id)
    assert "ciphertext" in enc
    assert enc["ciphertext"] != data
    assert len(enc["salt_hex"]) == 32  # 16 bytes hex
    assert len(enc["nonce_hex"]) == 24  # 12 bytes hex
    assert enc["verifier_hash"].startswith("$2b$") or enc["verifier_hash"].startswith("$2a$")

    # Correct decryption
    dec = decrypt_temporary_file(
        ciphertext=enc["ciphertext"],
        password=password,
        salt_hex=enc["salt_hex"],
        nonce_hex=enc["nonce_hex"],
        share_id=share_id,
    )
    assert dec == data


def test_wrong_password_fails_decryption():
    data = b"Secret bytes"
    password = "CorrectPassword1"
    share_id = "test_share_002"

    enc = encrypt_temporary_file(data, password, share_id)
    with pytest.raises(ValueError, match="Decryption failed"):
        decrypt_temporary_file(
            ciphertext=enc["ciphertext"],
            password="WrongPassword2",
            salt_hex=enc["salt_hex"],
            nonce_hex=enc["nonce_hex"],
            share_id=share_id,
        )


def test_verifier_password_check():
    password = "MyTempPassword456"
    salt = b"1234567890123456"
    key = derive_encryption_key(password, salt)
    vhash = generate_verifier_hash(key)

    assert check_verifier_password(password, salt, vhash) is True
    assert check_verifier_password("WrongPassword", salt, vhash) is False
    assert check_verifier_password("", salt, vhash) is False


def test_tampered_ciphertext_fails():
    data = b"Original uncorrupted content"
    password = "TestPassword"
    share_id = "test_share_003"

    enc = encrypt_temporary_file(data, password, share_id)
    # Tamper with the last byte of ciphertext (auth tag or payload)
    tampered = bytearray(enc["ciphertext"])
    tampered[-1] ^= 0xFF

    with pytest.raises(ValueError, match="Decryption failed"):
        decrypt_temporary_file(
            ciphertext=bytes(tampered),
            password=password,
            salt_hex=enc["salt_hex"],
            nonce_hex=enc["nonce_hex"],
            share_id=share_id,
        )
