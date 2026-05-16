Downloaded
https://developer.android.com/studio#command-line-tools-only

Extracted onto C: so that I get path
C:\android-sdk\cmdline-tools\latest

inside latest is everything. It didnt create latest by default I created that and put everything inside

Added object with variable name
ANDROID_SDK_ROOT
and variable value
C:\android-sdk

to both user and system variables


Added these to path
C:\android-sdk\cmdline-tools\latest\bin
C:\android-sdk\platform-tools
C:\android-sdk\emulator


Downloaded JAVA https://adoptium.net/temurin/releases?version=21&os=any&arch=any
version 21

Set system variable
JAVA_HOME
C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot

Added this to path
%JAVA_HOME%\bin

Ran this in terminal
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%
set SKIP_JDK_VERSION_CHECK=true
sdkmanager.bat "platform-tools" "emulator"


sdkmanager "system-images;android-30;google_apis;x86_64"

# install play store
sdkmanager "system-images;android-34;google_apis_playstore;x86_64"

# booting emulator
avdmanager create avd -n test -k "system-images;android-34;google_apis_playstore;x86_64"
(select no for custom hardware profile


emulator -avd test


Note that I manually installed wear it and first time launch it myself




# Launching via script
python "C:\Users\ethan\Documents\R\GitHub Projects\wearitreadr\python\screenshots.py"

# Show pointer location
adb shell settings put system pointer_location 1

x 261 y 396
x 28 y 53
128 594
275 432
x 28 y 53
x 28 y 53
160 586
235 373
screen shot
next
125 600
screenshot
250 373
screenshot
160 600
screenshot
160 600
250 373
screenshota
screenshot
