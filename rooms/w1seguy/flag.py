import sys

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <encoded>")
        sys.exit(1)

    encoded = sys.argv[1]
    key = sys.argv[2]

    decoded = bytes.fromhex(encoded).decode('utf-8')
 
    # The only thing we know is that flag starts with THM{ and ends with }. Since the size of the key is five, and the encoded flag is 40 word, it's enough to get the key

    flag = 'THM{' + 35 * '?' + '}' 
    xored = ""

    for i in range(0,len(decoded)):
        xored += chr(ord(decoded[i]) ^ ord(key[i%len(key)]))

    print(xored)

    return xored


if __name__ == "__main__":
    main()


