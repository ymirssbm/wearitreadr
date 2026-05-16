import subprocess
import time
import uiautomator2 as u2

AVD_NAME = "test"
PACKAGE = "edu.psu.hhd.hdfs.jpm165.genericsurveyapp2"

d = None


def run(cmd):
    subprocess.run(cmd, shell=True)


def wait():
    time.sleep(2)


def start_emulator():
    subprocess.Popen(
        f"emulator -avd {AVD_NAME} -no-snapshot-load",
        shell=True
    )


def wait_for_boot():
    run("adb wait-for-device")

    while True:
        out = subprocess.check_output(
            "adb shell getprop sys.boot_completed",
            shell=True
        ).decode().strip()

        if out == "1":
            break

        time.sleep(1)


def wait_for_device():
    while True:
        out = subprocess.check_output("adb devices", shell=True).decode()
        if "emulator" in out and "device" in out:
            break
        time.sleep(1)


def init_uiautomator():
    global d
    d = u2.connect()


def launch_app():
    run(f"adb shell monkey -p {PACKAGE} -c android.intent.category.LAUNCHER 1")
    wait()


def handle_permissions():
    time.sleep(3)

    if d(text="OK").exists:
        d(text="OK").click()

    if d(textContains="Allow").exists:
        d(textContains="Allow").click()

    if d(className="android.widget.Switch").exists:
        d(className="android.widget.Switch").click()


def click_start_survey():
    time.sleep(3)

    print("Selecting correct Start Survey button by layout position...")

    buttons = d.xpath("//*[@clickable='true']").all()

    candidates = []

    for b in buttons:
        info = b.info
        bnds = info.get("bounds", {})

        if not bnds:
            continue

        left = bnds.get("left", 0)
        right = bnds.get("right", 0)
        top = bnds.get("top", 0)
        bottom = bnds.get("bottom", 0)

        center_x = (left + right) / 2
        center_y = (top + bottom) / 2

        # filter bottom region (your button is bottom center-right area)
        if center_y > 1400:
            candidates.append((center_x, center_y, b))

    # choose the most center-horizontal candidate (NOT left-most)
    screen_center_x = 540

    best = None
    best_score = 10**9

    for x, y, node in candidates:
        score = abs(x - screen_center_x)

        if score < best_score:
            best_score = score
            best = node

    if best:
        best.click()
        print("Clicked correct Start Survey button")
        return

    # fallback
    d.click(650, 1750)


def main():
    start_emulator()
    wait_for_boot()
    wait_for_device()

    init_uiautomator()

    launch_app()
    handle_permissions()

    click_start_survey()


if __name__ == "__main__":
    main()
