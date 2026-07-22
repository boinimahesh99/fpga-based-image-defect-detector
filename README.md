# fpga-image-defect-detector
# FPGA Real-Time Defect Detection & Vision Pipeline

## Overview
This project implements a hardware-accelerated computer vision pipeline on an FPGA, designed to simulate a real-time quality control system for a manufacturing assembly line. 

Instead of relying on slower, software-based image processing (like OpenCV on a CPU), this system utilizes **spatial parallelism** and a **custom pipelined datapath** to process visual data at 25 MHz with sub-millisecond latency. It compares a live "test" image against a perfect "golden reference" image, filters out signal noise, and instantly highlights manufacturing defects on a live VGA display.

## System Architecture & Key Features
* **Synchronized 3-Stage Pipeline:** Implemented delay registers to perfectly synchronize VGA control signals (`h_sync`, `v_sync`, `video_active`) with the 2-cycle Block RAM latency and 1-cycle DSP filter latency, preventing visual timing artifacts.
* **Hardware Math (No Dividers):** Built a 1D spatial noise filter (Gaussian approximation) using purely shift registers and bit-slicing (`sum[9:2]`) to save silicon area and maximize clock speed.
* **Dual-Memory Image Handling:** 
  * **Reference Image:** Stored in Single-Port ROM (`.coe` initialized).
  * **Test Image:** Ingested live from a PC via a custom 115200 Baud UART receiver and stored in Simple Dual-Port RAM without interrupting the active video feed.
* **Live Telemetry & Robotics IO:** Utilizes a combinational Double-Dabble (Shift-and-Add-3) algorithm for binary-to-BCD conversion to drive a multiplexed 7-segment display. Triggers physical PMOD pins to simulate rejecting a defective board on a robotic assembly line.

##  Hardware Requirements
* **FPGA Board:** Digilent Nexys 4 DDR / Nexys A7 (Artix-7)
* **Display:** Standard VGA Monitor (640x480 @ 60Hz) & VGA Cable
* **Interfacing:** Micro-USB cable (for Programming & UART data transmission)

## Repository Structure
To keep this repository clean and lightweight, Vivado generated files (`.runs`, `.cache`, `.sim`) are git-ignored. Only pure source code is tracked.

```text
fpga-defect-detector/
├── src/
│   ├── hdl/              # Verilog source modules (Top, VGA, UART, DSP, BCD)
│   ├── constraints/      # Xilinx XDC pin-mapping file for the Nexys board
│   └── script/          # Python utility to send test images over UART
├── ip/                   # .coe file containing the golden reference image
├── docs/                 # Output images and board photos
└── README.md             # Project documentation
