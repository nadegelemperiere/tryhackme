def reverse_transformation(output_str):
    correct_input = ""
    for char in output_str:
        original_char = (ord(char) ^ 0xd) - 4
        correct_input += chr(original_char)
    return correct_input

output_str = "AhhF1ag1571GHFDS"
original_input = reverse_transformation(output_str)
print(original_input)