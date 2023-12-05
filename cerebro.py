import sys
import os

from bot import run_bot_terminal

def main():
    n = len(sys.argv)
    resp=""
    for i in range(2,n):
        resp += sys.argv[i] + " "
    print(resp)
    if (n < 3):
        run_bot_terminal("",sys.argv[1])
    else:
        run_bot_terminal(resp,sys.argv[1])
    
if __name__ == "__main__":
    main()