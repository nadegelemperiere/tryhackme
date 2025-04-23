import sys

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <encoded>")
        sys.exit(1)

    encoded = sys.argv[1]

    decoded = bytes.fromhex(encoded).decode('utf-8')
 
    # The only thing we know is that flag starts with THM{ and ends with }. Since the size of the key is five, and the encoded flag is 40 word, it's enough to get the key

    flag = 'THM{' + 35 * '?' + '}' 
    xored = ""

    for i in range(0,len(flag)):
        xored += chr(ord(flag[i]) ^ ord(decoded[i]))

    key = xored[0:4] + xored[-1]

    print(key)

    return key


if __name__ == "__main__":
    main()


