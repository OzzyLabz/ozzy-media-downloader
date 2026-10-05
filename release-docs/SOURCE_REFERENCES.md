# Источники текущей сборки / Sources for the current build

Проверка: 2026-10-05. Scope: the actual distributed tools and font, including their identified embedded components. No build or test tool is included merely because it appears in a dependency lock file.

## 1. Происхождение / Provenance

| Файл / File | Источник / Source |
| --- | --- |
| yt-dlp 2026.08.19 | [Official release](https://github.com/yt-dlp/yt-dlp/releases/tag/2026.08.19), asset `yt-dlp_macos` |
| FFmpeg/ffprobe Intel | [Supplier release directory](https://ffmpeg.martin-riedl.de/download/macos/amd64/1789931006_9.0.2/) — 2026-09-20 21:03 CEST |
| FFmpeg/ffprobe ARM | [Supplier release directory](https://ffmpeg.martin-riedl.de/download/macos/arm64/1789931890_9.0.2/) — 2026-09-20 21:18 CEST |
| Deno 2.9.7 | [Official release](https://github.com/denoland/deno/releases/tag/v2.9.7), `deno-x86_64-apple-darwin.zip`, `deno-aarch64-apple-darwin.zip` |
| Bellota Bold | [Font project](https://github.com/kemie/Bellota-Font); original notice in `../Resources/Fonts/OFL.txt` and the app |

### SHA-256 оригинальных загрузок / Original downloads

```text
yt-dlp_macos                 0f192b7ec147ab6288885d6351d9ab67367640029b4377576ef46dd79cf7b202
ffmpeg.zip amd64             7c6b4125b191cbf773832dc51f424cf2b6bb7da43007d1e066f95909e47cacd4
ffmpeg.zip arm64             c8ed4c4e6978a03c485edbfe4e0a5dc2380f8a30bba5150531b31b094492d924
ffprobe.zip amd64            2322438ed2f6319a691291b247d09c69dcaa3a982460d1f269a7e1af335cfdfd
ffprobe.zip arm64            fcbe839537485eaee7a7a8bc5cbc0f90d53617e80943e8a5b2e31cb851197ea6
deno-x86_64-apple-darwin.zip  95daaff11c116a52ad54785e7914c8e9c9cdcaba793c5ed929c74ca2d8e6259a
deno-aarch64-apple-darwin.zip  5cd46d6268f6f78f5d88bdc7159d20bd44cdaa4b3303474839f87ec6fe7ae25c
```

These were checked against supplier checksums / official GitHub release asset digests. Ad hoc signing and merging architectures change executable hashes.

### SHA-256 вложенных исполняемых файлов / Bundled helper executables

```text
ffmpeg   d4d33bf5b09d7e8c4fa5f095f58be2e8384b7e682a91ad598f5d97e0d7ebeb9d
ffprobe  3b4988f18d39bab42006f340ea83fe8588228c2d312c9a4c89e9812fb5ff097e
yt-dlp   7614c5ae1c448d28e1aba1f06da8b8f6265eeacf1072c410c92e848b082f0bbd
deno     e4c5d85d5c0b568deab0805a4a6be01e759d771235caf18162c5b062d966bf96
```

## 2. FFmpeg/ffprobe 9.0.2

[FFmpeg 9.0.2 source](https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz). The actual executable reports GPL version 3 or later, `--enable-gpl`, `--enable-version3`, `--enable-openssl`, and no `--enable-nonfree`. OpenSSL 3.6.4 is reported by the supplier and identified in the binary. The GPL/OpenSSL flags alone do not prohibit distribution: [FFmpeg's OpenSSL 3 compatibility change](https://ffmpeg.org/pipermail/ffmpeg-cvslog/2021-September/128908.html).

Скрипты поставщика: [ревизия `6a611e19870e197bc37c6e4c7fccddebd3715466`](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466), опубликованная 2026-09-20 18:00:59 CEST. С данными каждого выпуска совпадают 30 записей версий библиотек.

Supplier build scripts: the revision above was published on 2026-09-20 at 18:00:59 CEST. Thirty library-version entries match each release inventory.

[build.sh](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466/build.sh) defaults to `FFMPEG_SNAPSHOT="NO"`. [build-ffmpeg.sh](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466/script/build-ffmpeg.sh) downloads the versioned FFmpeg 9.0.2 release archive, configures, builds and installs it.

По умолчанию скрипт загружает релизный архив FFmpeg 9.0.2, затем выполняет настройку, сборку и установку.

### Версии и исходники / Versions and sources

The table follows the supplier's release inventories and enabled FFmpeg features. Sources are version-specific links, not locally archived source copies.

| Library | Version reported | Source |
| --- | --- | --- |
| aom | 3.15.0 | [Source](https://storage.googleapis.com/aom-releases/libaom-3.15.0.tar.gz) |
| libass | 0.17.5 | [Source](https://github.com/libass/libass/archive/refs/tags/0.17.5.tar.gz) |
| libbluray | 1.5.0 | [Source](https://download.videolan.org/pub/videolan/libbluray/1.5.0/libbluray-1.5.0.tar.xz) |
| dav1d | 1.5.4 | [Source](https://code.videolan.org/videolan/dav1d/-/archive/1.5.4/dav1d-1.5.4.tar.gz) |
| fontconfig | 2.17.1 | [Source](https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/2.17.1/fontconfig-2.17.1.tar.xz) |
| freetype | 2.13.0 | [Source](https://download.savannah.gnu.org/releases/freetype/freetype-2.13.0.tar.gz) |
| fribidi | 1.0.16 | [Source](https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz) |
| harfbuzz | 14.4.0 | [Source](https://github.com/harfbuzz/harfbuzz/archive/refs/tags/14.4.0.tar.gz) |
| libklvanc | 1.6.0 | [Source](https://github.com/stoth68000/libklvanc/archive/refs/tags/vid.obe.1.6.0.tar.gz) |
| lame | 4.0 | [Source](https://unlimited.dl.sourceforge.net/project/lame/lame/4.0/lame-4.0.tar.gz) |
| openh264 | 2.6.0 | [Source](https://github.com/cisco/openh264/archive/refs/tags/v2.6.0.tar.gz) |
| openJPEG | 2.5.4 | [Source](https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.4.tar.gz) |
| openssl | 3.6.4 | [Source](https://github.com/openssl/openssl/releases/download/openssl-3.6.4/openssl-3.6.4.tar.gz) |
| opus | 1.6.1 | [Source](https://downloads.xiph.org/releases/opus/opus-1.6.1.tar.gz) |
| rav1e | 0.8.1 | [Source](https://github.com/xiph/rav1e/archive/refs/tags/v0.8.1.tar.gz) |
| snappy | 1.2.2 | [Source](https://github.com/google/snappy/archive/refs/tags/1.2.2.tar.gz) |
| srt | 1.5.7 | [Source](https://github.com/Haivision/srt/archive/refs/tags/v1.5.7.tar.gz) |
| svt-av1 | 4.2.0 | [Source](https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v4.2.0/SVT-AV1-v4.2.0.tar.gz) |
| libtheora | 1.2.0 | [Source](https://downloads.xiph.org/releases/theora/libtheora-1.2.0.tar.gz) |
| libvmaf | 3.2.0 | [Source](https://github.com/Netflix/vmaf/archive/refs/tags/v3.2.0.tar.gz) |
| libvorbis | 1.3.7 | [Source](https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.gz) |
| vpx | 1.16.0 | [Source](https://github.com/webmproject/libvpx/archive/refs/tags/v1.16.0.tar.gz) |
| vvenc | 1.14.0 | [Source](https://github.com/fraunhoferhhi/vvenc/archive/refs/tags/v1.14.0.tar.gz) |
| libwebp | 1.6.0 | [Source](https://github.com/webmproject/libwebp/archive/refs/tags/v1.6.0.tar.gz) |
| x264 | core 165; source reference selected by build-date history | [Source](https://code.videolan.org/videolan/x264/-/archive/0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee/x264-0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee.tar.gz) |
| x265 | 4.2 | [Source](https://bitbucket.org/multicoreware/x265_git/get/4.2.tar.gz) |
| libxml2 | 2.15.3 | [Source](https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.3.tar.xz) |
| zimg | 3.0.6 | [Source](https://github.com/sekrit-twc/zimg/archive/refs/tags/release-3.0.6.tar.gz) |
| zlib | 1.3.2 | [Source](https://www.zlib.net/fossils/zlib-1.3.2.tar.gz) |
| zvbi | 0.2.35 | [Source](https://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2/download) |

### libogg

The supplier's [version file](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466/version/libogg) specifies 1.3.6. Its [build script](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466/script/build-libogg.sh) downloads and builds the versioned archive. [Source and included notice](https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.6.tar.gz).

Скрипт поставщика указывает libogg 1.3.6 и загружает архив этой версии. В оригинальных ffmpeg/ffprobe обеих архитектур обнаружены изменения проверки выделения памяти и 64-битных сдвигов из [diff 1.3.5 → 1.3.6](https://github.com/xiph/ogg/compare/v1.3.5...v1.3.6.diff) и [bitwise.c версии 1.3.6](https://github.com/xiph/ogg/blob/v1.3.6/src/bitwise.c).

The original ffmpeg/ffprobe binaries for both architectures contain the allocation-failure check and 64-bit shifts introduced by those upstream changes.

### x264

The [supplier script](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466/script/build-x264.sh) downloads an archive of `master`. The source reference in the table is selected from [official VideoLAN history at the build date](https://code.videolan.org/api/v4/projects/videolan%2Fx264/repository/commits?ref_name=master&until=2026-09-20T19%3A00%3A00Z&per_page=3). Its `X264_BUILD 165` matches the bundled encoder's `core 165`.

Скрипт поставщика загружает архив `master`. Ссылка на исходники в таблице выбрана по истории VideoLAN на дату выпуска; `X264_BUILD 165` совпадает с `core 165` вложенного кодировщика.

The ARM originals contain `x264_8_hpel_filter_neon_i8mm` and the `usdot`/`ssra` instructions introduced by [commit b35605ace3ddf7c1a5d67a2eb553f034aef41d55](https://code.videolan.org/videolan/x264/-/commit/b35605ace3ddf7c1a5d67a2eb553f034aef41d55.diff). The [later 0480cb05 diff](https://code.videolan.org/api/v4/projects/videolan%2Fx264/repository/commits/0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee/diff) adds RISC-V support. x264's [version.sh](https://code.videolan.org/videolan/x264/-/raw/0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee/version.sh) obtains revision metadata from Git history when `.git` is present.

В ARM-оригиналах присутствуют функция и инструкции из указанного июньского commit; следующий commit добавляет поддержку RISC-V. Скрипт `version.sh` получает сведения о ревизии из истории Git при наличии `.git`.

### Условия распространения / Distribution requirements

GPLv3 requires providing access to the complete corresponding source under its terms, including required build scripts and sources of incorporated libraries. [GPLv3 section 6](https://www.gnu.org/licenses/gpl-3.0.html#section6) permits equivalent source access from another server in the relevant online-distribution case, with clear directions next to the binary and responsibility for continued availability. A generic project homepage is not a substitute for corresponding source.

The app author did not modify FFmpeg codec sources. This software is based in part on the work of the Independent JPEG Group.

## 3. yt-dlp 2026.08.19

[Source archive](https://github.com/yt-dlp/yt-dlp/archive/refs/tags/2026.08.19.tar.gz), [Unlicense](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/LICENSE), [complete upstream packaged-executable notices](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/THIRD_PARTY_LICENSES.txt). That exact notice file is preserved verbatim between markers in THIRD_PARTY_LICENSES.txt. It covers packaged components and includes a source-contact statement from yt-dlp maintainers. The scope follows the upstream packaged-release notice rather than an invented dependency list. The official macOS executable includes EJS; its Meriyah and Astring notices are preserved.

## 4. Deno 2.9.7

[Source archive](https://github.com/denoland/deno/archive/refs/tags/v2.9.7.tar.gz), [MIT license](https://github.com/denoland/deno/blob/v2.9.7/LICENSE.md). The actual runtime reports V8 `15.0.245.2-rusty` and TypeScript `6.0.3`. Their collected notices are included.

The tagged [Cargo.lock](https://github.com/denoland/deno/blob/v2.9.7/Cargo.lock) identifies Rust binding `v8 150.4.0`. Its [tagged source](https://github.com/denoland/rusty_v8/tree/v150.4.0) pins [V8 source commit ac1e23989121713ca642f6650b34deff7b686896](https://github.com/denoland/v8/tree/ac1e23989121713ca642f6650b34deff7b686896).

### Добавленные уведомления / Added notices

- `dlopen2 0.6.1`: [published project MIT notice](https://github.com/OpenByteDev/dlopen2/blob/c1ca06007390d89e9adf2a4400176eba51ba9c28/LICENSE), including the three published copyright holders. [LICENSE history](https://api.github.com/repos/OpenByteDev/dlopen2/commits?path=LICENSE&per_page=10).
- Only `aead-gcm-stream 0.4.0` and `fqdn 0.5.2` retain the generic MIT-template reference in this index. `fqdn`'s crate identifies [revision a23fef8570522a3b98a79afc45322d6487166cd9](https://github.com/Orange-OpenSource/fqdn/tree/a23fef8570522a3b98a79afc45322d6487166cd9) with `dirty: true`; the inspected revision has no separate root license file. The published crate declares MIT.
- `aead-gcm-stream 0.4.0`: the crate's `.cargo_vcs_info.json` identifies [source revision 2737345ddbccd5b3e1ae41060b136cfc3e0cb610](https://github.com/littledivy/aead-gcm-stream/tree/2737345ddbccd5b3e1ae41060b136cfc3e0cb610). Its Cargo.toml declares MIT. The common file therefore retains the declaration, published author metadata and standard MIT text.
- SQLCipher's notice was removed from the collected crate texts: Deno's resolved `libsqlite3-sys 0.38.1` configuration enables bundled SQLite, not SQLCipher. The Rust binding's MIT notice remains. SQLCipher's mere presence as an alternative source directory in a crate archive is not evidence of inclusion in the app.
- Native Little CMS: `lcms2 6.1.0` is identified in the bundled Deno. Additionally, 31 native C string literals from the vendored library in `lcms2-sys 4.0.5` match the actual helper. Its `vendor/LICENSE` (Marti Maria Saguer, MIT) is included. [Exact source archive](https://static.crates.io/crates/lcms2-sys/lcms2-sys-4.0.5.crate).
- Native libdeflate: the bundled Deno identifies `libdeflater 1.25.2`; its `libdeflate-sys 1.25.2` dependency builds the vendored C library. The archive's `libdeflate/COPYING` notice (Eric Biggers and Google LLC, MIT) is preserved in the common license file. [Exact source archive](https://static.crates.io/crates/libdeflate-sys/libdeflate-sys-1.25.2.crate).
- The complete [TypeScript 6.0.3 ThirdPartyNoticeText.txt](https://github.com/microsoft/TypeScript/blob/v6.0.3/ThirdPartyNoticeText.txt) is included, in addition to its Apache license.
- Embedded registry source paths in the actual universal Deno helper identify **378 distinct Rust package/version pairs**. Every pair matches the tagged Cargo.lock. Their source archives were downloaded in memory and checked against the lock-file SHA-256; their collected license texts, archive URLs and checksums are recorded in the common license file. Identical texts have an index, rather than being copied for every package.
- For packages without a packaged full license text, the collection distinguishes their original Cargo.toml license declaration and author metadata from standard license texts or pinned repository licenses. It does not invent copyright owners or dates.
- Added native notices for AWS-LC (`aws-lc-sys 0.40.0`), libffi (`libffi-sys 4.1.0`) and Zstandard (`zstd-sys 2.0.15+zstd.1.5.7`), plus `libuv-sys-lite 1.48.4`. The last package supplies bindings and libuv header attribution; it does not link a libuv C library. Deno implements the exported compatibility functions.
- Added `libz-sys 1.1.20` MIT and its pinned zlib-ng notice. Deno's default [V8 feature configuration](https://github.com/denoland/deno/blob/v2.9.7/cli/Cargo.toml) enables `__vendored_zlib_ng`. [libz-sys 1.1.20](https://github.com/rust-lang/libz-sys/tree/1.1.20) pins [zlib-ng commit 74253725f884e2424a0dd8ae3f69896d5377f325](https://github.com/zlib-ng/zlib-ng/tree/74253725f884e2424a0dd8ae3f69896d5377f325); the bundled Deno contains `1.3.0.zlib-ng`.
- Added the complete ICU license from rusty_v8's pinned ICU revision `ee5f27adc28bd3f15b2c293f726d14d2e336cbd5`; ICU 77 symbols occur in the binary. The collection also contains the licenses for V8's pinned Abseil, Dragonbox, fast_float, Highway and simdutf sources and identified V8 internal third-party code.
- The tagged Deno source archive was inspected in memory for copyright/license headers in runtime, CLI and extension code. The collection preserves borrowed-code notices, including Node/Joyent, Browserify, Feross Aboukhadijeh, Mathias Bynens, Domenic Denicola and other identified authors. It also preserves Deno's attribution for documentation adapted from MDN and the CC-BY-SA 2.5 text. Windows-specific subprocess files and test fixtures are excluded.

В комплект включены уведомления компонентов, обнаруженных во вложенном Deno. Стандартные тексты лицензий обозначены отдельно от оригинальных уведомлений. Лицензия оригинального кода приложения и документации: [Noncommercial Use License 1.0](LICENSE), Copyright (c) 2026 OzzyLabz. Сторонние лицензии не изменяются.

The collection contains notices for components identified in the bundled Deno. Standard license texts are labelled separately from original notices. The original application code and documentation use [Noncommercial Use License 1.0](LICENSE), Copyright (c) 2026 OzzyLabz. Third-party terms remain unchanged.

## 5. Условия публикации / Publication terms

Сохраняйте применимые тексты лицензий и уведомления авторов. Для GPL-бинарников предоставляйте доступ к соответствующим исходникам и необходимым скриптам сборки на условиях лицензии. Передавайте `THIRD_PARTY_LICENSES.txt`, этот документ и данные версий вместе с приложением.

Retain the applicable license texts and copyright notices. For GPL-covered binaries, provide access to corresponding source and required build scripts under the license. Distribute `THIRD_PARTY_LICENSES.txt`, this document and the version records with the app.
