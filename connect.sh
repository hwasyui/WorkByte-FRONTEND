#!/bin/bash
# Script buat konek ke HP/Emulator dari dalem container
adb disconnect
adb connect host.docker.internal:5555
adb devices