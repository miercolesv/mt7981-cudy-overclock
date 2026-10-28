# Automated builds

Workflow: `.github/workflows/build-release.yml`, logic in `ci/build-release.sh` (runs the
same way locally).

## When it runs

* **Daily** (05:17 UTC). OpenWrt has no release webhook, so the workflow polls
  https://downloads.openwrt.org/releases/ via `ci/latest-release.sh`. It picks the newest
  stable release ≥ 25.12.0 whose mediatek/filogic directory is fully published (the SDK is
  listed in `sha256sums`). If an `oc-<version>` release already exists, it does nothing.
* **Manually**: Actions → *Build OC release* → *Run workflow*. Optional inputs: version,
  clocks, and `force` to rebuild and replace an existing release.

GitHub disables scheduled workflows in public repos after 60 days without repository
activity. If that happens, re-enable it from the Actions tab.

## What it does

1. Downloads the release's `sha256sums` and SDK and verifies the SDK checksum. Clones
   `openwrt` at tag `v<version>`.
2. Finds every Cudy device using an `mt7981-bl2 cudy-*` preloader in
   `target/linux/mediatek/image/filogic.mk`, grouped by variant. New Cudy devices or
   variants are picked up automatically.
3. For each variant:
   * checks that all devices in the group have the same official preloader, and verifies
     it against `sha256sums`;
   * builds the **stock** preloader and requires it to be **byte-identical** to the official
     one. If it isn't, the run fails and nothing is published;
   * builds each overclocked clock, checking each differs from stock and is the same size.
4. Builds the runtime module, but only if the SDK kernel hash matches the release's kmods
   directory. If the module fails (e.g. a kernel API change), the preloaders are still
   published and the release notes say so.
5. Writes `SHA256SUMS` and release notes. The notes list devices, the official stock hash,
   and whether the stock preloader changed since the previous `oc-*` release.
6. Publishes release `oc-<version>` and uploads build logs as workflow artifacts.

## When it fails

You get GitHub's failed-workflow email. Typical causes:

| Error | Likely cause | Fix |
|---|---|---|
| `stock ... is NOT identical` | OpenWrt changed the build, or the release isn't reproducible | investigate; don't publish by hand |
| `patch no longer applies?` | OpenWrt updated TF-A and `pll.c` changed | update `bl2/gen-patch.sh` for the new code |
| `could not select CONFIG_PACKAGE_...` | TF-A package Makefile restructured | update `bl2/build-bl2.sh` |
| module warning only | kernel API change | update the module source; preloaders were still published |

## Run locally

```sh
WORK=$PWD/work sh ci/build-release.sh 25.12.6 dist/
```

Needs the host packages listed in [building.md](building.md). The first run downloads the
SDK (~300 MB) and builds host tools; later runs reuse `WORK`.
