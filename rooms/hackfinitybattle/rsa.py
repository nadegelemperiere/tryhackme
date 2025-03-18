import sys

def hex_to_bytes(hex_string):
    """Convert a hex string to bytes"""
    return bytes.fromhex(hex_string)

def string_to_bytes(string):
    """Convert a string to bytes"""
    return string.encode()

def xor_decrypt(encoded_bytes, key_bytes):
    """Perform XOR decryption using the extracted key"""
    key_length = len(key_bytes)
    decoded_bytes = bytes(encoded_bytes[i] ^ key_bytes[i % key_length] for i in range(len(encoded_bytes)))
    return decoded_bytes

def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <p> <q> <e>")
        sys.exit(1)

    p = sys.argv[1]
    q = sys.argv[2]
    e = sys.argv[3]

    key = pow(int(e), -1, (int(p) - 1) * (int(q) - 1))
    print(f"--> RSA private key is: {key}")

if __name__ == "__main__":
    main()
