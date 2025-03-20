def reverse_xor(data, key=0x52):
    return "".join(chr(ord(c) ^ key) for c in data)

# Known constraints
transformed_key = list("?" * 16)  # Placeholder for the key
transformed_key[2] = 'Q'
transformed_key[15] = '4'


original_input = reverse_xor(transformed_key)

print("Correct Key:", original_input)


def recover_username(encrypted_username):
    return "".join(chr(ord(c) - 2) for c in encrypted_username)

target_username = "elb4rt0pwn"
correct_username = recover_username(target_username)

print("Correct Username:", correct_username)