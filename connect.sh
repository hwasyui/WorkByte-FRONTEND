#!/bin/bash
# Script buat konek ke HP/Emulator dari dalem container
adb disconnect
adb connect host.docker.internal:5555
adb devices

# run docker 
go to container (docker exec -it <container_id> bash)
flutter pub get 
flutter run 
