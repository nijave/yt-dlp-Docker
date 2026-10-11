#!/usr/bin/env python3

import datetime
import logging
import os
import pathlib
import subprocess
import sys
import time

logger = logging.getLogger(__file__ if __name__ == "__main__" else __name__)
logging.basicConfig(
    level=getattr(logging, os.environ.get("LOG_LEVEL", "INFO").upper()),
    format="%(asctime)s [%(levelname)s]: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
)


def run_downloads():
    failures = 0
    for script in pathlib.Path(os.environ.get("MEDIA_ROOT", "/media")).glob(
        "**/.yt-dlp"
    ):
        logger.info("running yt-dlp in %s", script.parent)
        yt_dlp = subprocess.run(
            [
                "/bin/bash",
                str(script),
            ],
            cwd=script.parent,
            stdout=sys.stdout,
            stderr=sys.stderr,
        )
        if (rc := yt_dlp.returncode) != 0:
            logger.error("yt-dlp for %s exited %d", script.parent, rc)
            failures += 1
        else:
            logger.info("download complete for %s", script.parent)
    return failures


if __name__ == "__main__":
    # One-shot mode for schedulers that own the cadence (e.g. a k8s CronJob):
    # run a single pass and exit 0 once it completes. Per-show scripts that error
    # are logged and counted but do NOT fail the run -- yt-dlp returns non-zero
    # whenever any single video in a channel is unavailable/blocked/unprocessable,
    # which is routine for an archiver and must not mark the whole scheduled run
    # failed. Unset (the default) keeps the internal CHECK_FREQUENCY loop used by
    # the standalone Docker deployment.
    if os.environ.get("RUN_ONCE", "").lower() in ("1", "true", "yes"):
        failures = run_downloads()
        if failures:
            logger.warning(
                "%d per-show script(s) reported errors; run completed anyway "
                "(see logs above)",
                failures,
            )
        raise SystemExit(0)

    check_frequency = int(os.environ.get("CHECK_FREQUENCY", 8 * 60 * 60))
    last_start = None
    while True:
        last_start = time.time()
        run_downloads()
        sleep_time = check_frequency - time.time() + last_start
        if sleep_time > 0:
            logger.info(
                "waiting %s before rerunning", datetime.timedelta(seconds=sleep_time)
            )
            time.sleep(sleep_time)
        else:
            logger.info("running %s late", datetime.timedelta(seconds=sleep_time * -1))
