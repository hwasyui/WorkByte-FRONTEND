FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa openjdk-17-jdk wget android-tools-adb \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT /opt/android-sdk
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O /tmp/tools.zip \
    && unzip /tmp/tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm /tmp/tools.zip

ENV FLUTTER_HOME /opt/flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

ENV PATH "$PATH:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
