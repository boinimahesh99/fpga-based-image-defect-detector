import serial
import time
from PIL import Image

COM_PORT = 'COM14' 
BAUD_RATE = 115200
IMAGE_PATH = 'test_img.jpg' 

def send_image_to_fpga(image_path, com_port, baud_rate):
    print(f"Opening image: {image_path}...")
    img = Image.open(image_path).convert('L')
    img = img.resize((128, 128))
    pixels = list(img.getdata())

    print(f"Connecting to FPGA on {com_port} at {baud_rate} baud...")
    try:
        with serial.Serial(com_port, baud_rate, timeout=1) as ser:
            print("\n*** FLIP SWITCH 0 (J15) UP ON THE FPGA NOW! ***")
            time.sleep(4) 
            
            print("Transmitting 16,384 bytes...")
            byte_data = bytearray(pixels)
            ser.write(byte_data)
            
            print("Transmission Complete! FLIP SWITCH 0 DOWN to see results.")
            
    except Exception as e:
        print(f"Error: {e}\nCheck your COM port in Device Manager!")


send_image_to_fpga(IMAGE_PATH, COM_PORT, BAUD_RATE)
