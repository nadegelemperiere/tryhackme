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
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <hex_text> <known_plaintext>")
        sys.exit(1)

    hex_text = sys.argv[1]
    known_plaintext = sys.argv[2]

    # Convert inputs
    encoded_bytes = hex_to_bytes(hex_text)
    known_bytes = string_to_bytes(known_plaintext)

    # Extract key by XOR-ing known plaintext with encoded bytes
    key_bytes = bytes(encoded_bytes[i] ^ known_bytes[i] for i in range(len(known_bytes)))
    
    # Print the extracted key as a string
    key_string = key_bytes.decode(errors='ignore')
    print(f"--> Extracted XOR Key: {key_string}")

    # Decode the full message using the extracted key
    full_decoded = xor_decrypt(encoded_bytes, key_bytes)
    print(f"--> Decoded Full Message: {full_decoded.decode(errors='ignore')}")

if __name__ == "__main__":
    main()
