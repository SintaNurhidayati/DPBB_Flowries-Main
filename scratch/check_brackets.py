import sys

def check_brackets(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    stack = []
    
    for i, line in enumerate(lines):
        # Ignore line comments entirely for bracket matching
        if '//' in line:
            line = line[:line.index('//')]
            
        in_string = False
        string_char = ''
        
        j = 0
        while j < len(line):
            char = line[j]
            
            if char in "'\"":
                if not in_string:
                    in_string = True
                    string_char = char
                elif string_char == char:
                    # Very simple string parsing, won't handle escapes perfectly
                    in_string = False
            
            if not in_string:
                if char in '([{':
                    stack.append((char, i+1, j+1))
                    print(f"Pushed {char} at {i+1}:{j+1}. Stack size: {len(stack)}")
                elif char in ')]}':
                    if not stack:
                        print(f"Error: unmatched closing {char} at line {i+1}, col {j+1}")
                        return
                    last_open, line_num, col_num = stack.pop()
                    print(f"Popped {char} at {i+1}:{j+1}. Matched with {last_open} at {line_num}:{col_num}. Stack size: {len(stack)}")
                    if (last_open == '(' and char != ')') or \
                       (last_open == '[' and char != ']') or \
                       (last_open == '{' and char != '}'):
                        print(f"Error: unmatched closing {char} at line {i+1}, col {j+1}. Expected closing for {last_open} from line {line_num}, col {col_num}")
                        return
            j += 1
            
    if stack:
        print(f"Unmatched opening brackets remaining:")
        for char, line_num, col_num in stack:
            print(f"  {char} at line {line_num}, col {col_num}")
    else:
        print("All brackets balanced!")

check_brackets(sys.argv[1])
