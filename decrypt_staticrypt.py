import hashlib
import re
import sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

PASSWORD = "chat-riant"

with open(r"C:\Users\timbe\AppData\Local\Temp\ofce_page.html", "r", encoding="utf-8") as f:
    html = f.read()

m = re.search(r'"staticryptEncryptedMsgUniqueVariableName":"([a-f0-9]+)"', html)
encrypted_msg = m.group(1)
m = re.search(r'"staticryptSaltUniqueVariableName":"([a-f0-9]+)"', html)
salt = m.group(1)

print("salt:", salt)
print("encrypted_msg length:", len(encrypted_msg))


def pbkdf2(password_bytes, salt_str, iterations, hash_name):
    key = hashlib.pbkdf2_hmac(hash_name, password_bytes, salt_str.encode("utf-8"), iterations, dklen=32)
    return key.hex()


def hash_password(password, salt):
    h1 = pbkdf2(password.encode("utf-8"), salt, 1000, "sha1")
    h2 = pbkdf2(h1.encode("utf-8"), salt, 14000, "sha256")
    h3 = pbkdf2(h2.encode("utf-8"), salt, 585000, "sha256")
    return h3


def sign_message(hashed_password_hex, message_str):
    import hmac
    key = bytes.fromhex(hashed_password_hex)
    return hmac.new(key, message_str.encode("utf-8"), hashlib.sha256).hexdigest()


def decrypt(encrypted_hex, hashed_password_hex):
    iv_hex = encrypted_hex[:32]
    ct_hex = encrypted_hex[32:]
    iv = bytes.fromhex(iv_hex)
    ct = bytes.fromhex(ct_hex)
    key = bytes.fromhex(hashed_password_hex)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    pt = cipher.decrypt(ct)
    return unpad(pt, 16).decode("utf-8")


def decode(signed_msg, hashed_password_hex):
    encrypted_hmac = signed_msg[:64]
    encrypted_msg = signed_msg[64:]
    computed_hmac = sign_message(hashed_password_hex, encrypted_msg)
    if computed_hmac != encrypted_hmac:
        return None
    return decrypt(encrypted_msg, hashed_password_hex)


hashed = hash_password(PASSWORD, salt)
result = decode(encrypted_msg, hashed)
if result is None:
    print("DECRYPTION FAILED - signature mismatch")
    sys.exit(1)

with open(r"C:\Users\timbe\AppData\Local\Temp\ofce_decrypted.html", "w", encoding="utf-8") as f:
    f.write(result)
print("Decrypted, length:", len(result))
