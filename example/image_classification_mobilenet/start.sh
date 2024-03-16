#!/bin/bash
# Start the Flutter app
cd lib
flutter run &
# Start the Python backend
cd ../backend
python main.py
