yt-dlp image for scheduled channel archiving

```
registry.apps.nickv.me/nijave/yt-dlp:<YYYYMMDD>-<sha>
registry.apps.nickv.me/nijave/yt-dlp:latest
```

Built by Woodpecker (`.woodpecker.yaml`) on every push to `main` that touches
the image. The dated tag is the commit date (UTC) and short SHA of the built
commit. yt-dlp, deno, and bgutil-ytdlp-pot-provider are pinned in the
`Dockerfile` and bumped by Renovate.

The image runs `download.py`, which runs every `.yt-dlp` script under
`MEDIA_ROOT` (default `/media`). Each script runs in its own directory.

```
docker run -d \
    --restart unless-stopped \
    --user 1002:1001 \
    -v /path/to/media:/media \
    --name yt-dlp \
    registry.apps.nickv.me/nijave/yt-dlp
```

environment variables
```
MEDIA_ROOT       media tree to scan for .yt-dlp scripts (default /media)
CHECK_FREQUENCY  seconds between passes (default 7200)
RUN_ONCE         1 = run one pass and exit (for a k8s CronJob)
LOG_LEVEL        default INFO
```

`/etc/yt-dlp.conf` sets the defaults for every job. It points the PO Token
plugin at `http://bgutil-provider:4416`, so run a
[bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider)
server with that name. Its major version must match the plugin in the
`Dockerfile` (2.x).
