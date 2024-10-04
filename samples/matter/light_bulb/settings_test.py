#!/usr/bin/env python3
 
import argparse
import subprocess
from serial import Serial
import time
import random
 
parser = argparse.ArgumentParser()
parser.add_argument('-p', "--port", type=str, required=True)
parser.add_argument("-i", "--iterations", type=int, default=500)
parser.add_argument("--single_chunk", type=int, default=200)
parser.add_argument('-f', "--factoryreset", type=bool, default=False)
parser.add_argument('-s', "--freespace", type=bool, default=False)
args = parser.parse_args()
 
def main():
    print("Start testing...\n")
    with Serial(args.port, 115200, timeout=0.15) as device:
        # Reset device until crash
        for i in range(0, args.iterations):
            print(f"\n Writting. {i}")
            device.readlines()
            random_key = ""
            for x in range(6):
                random_key += str(random.randrange(9))
            random_string = ""
            for i in range(args.single_chunk):
                random_string += str(random.randrange(9))
            time.sleep(0.15)
            device.write(f"settings write mt/{random_key} {random_string}\n".encode("utf-8"))
            time.sleep(0.15)
            for line in device.readlines():
                print(line[:-1].decode("utf-8"))
            time.sleep(0.15)

        if (args.freespace):
            device.write(f"matter_settings free\n".encode("utf-8"))
            time.sleep(3)
            for line in device.readlines():
                print(line[:-1].decode("utf-8"))

        if (args.factoryreset):
            print(f"\n Performing Factory Reset.")
            device.write(f"matter device factoryreset\n".encode("utf-8"))
            time.sleep(6)

        print(f"\n Content of the settings.")
        device.write(f"settings list\n".encode("utf-8"))
        time.sleep(0.15)
        for line in device.readlines():
            print(line[:-1].decode("utf-8", errors="ignore"))
 
if __name__ == '__main__':
    main()
