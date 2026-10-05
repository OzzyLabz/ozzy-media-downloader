# Third-party components / Сторонние компоненты

## English

Free or noncommercial distribution still follows the applicable license terms. Deno's MIT license permits use and redistribution with its copyright and permission notice retained; incorporated components retain their own terms. GPL-covered FFmpeg binaries require the applicable notices and access to corresponding source.

This file describes the current local universal `.app`. Links to licenses help with review; distributing a binary release also requires the applicable full notices and compliance with each component's terms. The app's original code and documentation are covered by [Noncommercial Use License 1.0](LICENSE), Copyright (c) 2026 OzzyLabz. That license does not change third-party terms.

| Component | Version and purpose | License and source |
| --- | --- | --- |
| `yt-dlp_macos` | 2026.08.19; analysis and downloads | The `yt-dlp` project uses the [Unlicense](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/LICENSE). Its packaged executable contains other components; see the [version-specific third-party notices](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/THIRD_PARTY_LICENSES.txt). |
| `yt-dlp-ejs` | Included in the official `yt-dlp_macos`; YouTube extraction support | See the [yt-dlp EJS documentation](https://github.com/yt-dlp/yt-dlp/wiki/EJS) and the executable's third-party notices. |
| `ffmpeg`, `ffprobe` | 9.0.2, Martin Riedl binaries for `x86_64` and `arm64`; media processing | [FFmpeg license](https://ffmpeg.org/doxygen/trunk/md_LICENSE.html), [distribution guidance](https://ffmpeg.org/legal.html), [supplier's release page](https://ffmpeg.martin-riedl.de/). Source status is explained below. |
| `deno` | 2.9.7; JavaScript runtime for `yt-dlp` | [MIT license at the v2.9.7 tag](https://github.com/denoland/deno/blob/v2.9.7/LICENSE.md); [Deno v2.9.7 release](https://github.com/denoland/deno/releases/tag/v2.9.7). |
| Bellota Bold | Interface font | SIL Open Font License 1.1. The full license and copyright notice are already in [`Resources/Fonts/OFL.txt`](Resources/Fonts/OFL.txt) and bundled with the `.app`. [Font project](https://github.com/kemie/Bellota-Font). |

### Bundled notices and sources

Deno component notices are collected in `release-docs/THIRD_PARTY_LICENSES.txt`. The index distinguishes collected upstream notices from published license declarations and standard license texts.

Both architecture variants of FFmpeg/ffprobe came from Martin Riedl's 9.0.2 releases; the downloaded archives matched the supplier's SHA-256 checksums. `ffmpeg -version` reports `--enable-gpl`, `--enable-version3`, and `--enable-openssl`, and OpenSSL 3.6.4 was found in the binary. OpenSSL 3 uses Apache License 2.0, and [FFmpeg accounts for its compatibility with GPLv3](https://ffmpeg.org/pipermail/ffmpeg-cvslog/2021-September/128908.html). Those flags alone do **not** require replacement of the working binaries.

The supplier's `develop` branch contains [the FFmpeg 9.0.2 revision](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466), dated before the two binary releases. Both release-specific library inventories are preserved in `release-docs/`. [SOURCE_REFERENCES.md](release-docs/SOURCE_REFERENCES.md) provides version-specific source links and supplier build scripts.

[release-docs/THIRD_PARTY_LICENSES.txt](release-docs/THIRD_PARTY_LICENSES.txt) preserves the full official yt-dlp 2026.08.19 packaged-executable notice file and collects identified FFmpeg/library, Deno, V8, TypeScript and Bellota texts. It includes TypeScript 6.0.3 ThirdPartyNoticeText.txt, notices for 378 Rust package versions identified in the actual Deno executable, identified native/V8 component notices, and libz-sys 1.1.20 with its pinned zlib-ng license. Dependencies found only in the general lock file are excluded. A separate supplier manifest or correspondence is not a license requirement. Distribute the external `release-docs/` directory together with the app; the `.app` itself was not changed. The app's own license is provided in [LICENSE](LICENSE) and [release-docs/LICENSE](release-docs/LICENSE). General notification letters to tool authors are not required by the cited licenses.

## Русский

Бесплатное или некоммерческое распространение требует выполнения применимых условий лицензий. MIT Deno разрешает использование и распространение с сохранением уведомления об авторских правах и текста разрешения; вложенные компоненты сохраняют свои условия. Для GPL-бинарников FFmpeg нужны применимые уведомления и доступ к соответствующим исходникам.

Этот файл описывает компоненты текущей локальной универсальной `.app`. Ссылки на лицензии помогают провести проверку; перед публикацией бинарного релиза нужно приложить необходимые полные тексты уведомлений и выполнить условия распространения каждого компонента. Оригинальный код приложения и документация охватываются [Лицензией некоммерческого использования 1.0](LICENSE), Copyright (c) 2026 OzzyLabz. Она не изменяет условий сторонних компонентов.

| Компонент | Версия и использование | Лицензия и источник |
| --- | --- | --- |
| `yt-dlp_macos` | 2026.08.19; анализ и загрузка | Сам `yt-dlp` распространяется на условиях [Unlicense](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/LICENSE). Готовый исполняемый файл включает сторонние компоненты: [полный перечень и тексты лицензий для версии 2026.08.19](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/THIRD_PARTY_LICENSES.txt). |
| `yt-dlp-ejs` | В составе официального `yt-dlp_macos`; поддержка извлечения данных YouTube | Состав и требования описаны в [документации yt-dlp EJS](https://github.com/yt-dlp/yt-dlp/wiki/EJS); его уведомления входят в перечень сторонних компонентов сборки `yt-dlp`. |
| `ffmpeg`, `ffprobe` | 9.0.2, бинарники Martin Riedl для `x86_64` и `arm64`; обработка медиа | [Лицензия FFmpeg](https://ffmpeg.org/doxygen/trunk/md_LICENSE.html), [разъяснение по распространению](https://ffmpeg.org/legal.html), [страница конкретных выпусков поставщика](https://ffmpeg.martin-riedl.de/). Статус исходников приведён ниже. |
| `deno` | 2.9.7; JavaScript runtime для `yt-dlp` | [MIT, файл LICENSE.md версии 2.9.7](https://github.com/denoland/deno/blob/v2.9.7/LICENSE.md); бинарники из [релиза Deno v2.9.7](https://github.com/denoland/deno/releases/tag/v2.9.7). |
| Bellota Bold | Шрифт интерфейса | SIL Open Font License 1.1. Полный текст и уведомление автора уже лежат в [`Resources/Fonts/OFL.txt`](Resources/Fonts/OFL.txt) и вложены в `.app`. [Проект шрифта](https://github.com/kemie/Bellota-Font). |

### Уведомления и исходники

Уведомления компонентов Deno собраны в `release-docs/THIRD_PARTY_LICENSES.txt`. В указателе различаются собранные исходные уведомления, опубликованные декларации лицензий и стандартные тексты лицензий.

Обе архитектурные версии FFmpeg/ffprobe взяты из выпусков 9.0.2 Martin Riedl; SHA-256 исходных архивов совпали с контрольными суммами поставщика. Вывод `ffmpeg -version` содержит `--enable-gpl`, `--enable-version3` и `--enable-openssl`, а в бинарнике обнаружен OpenSSL 3.6.4. OpenSSL 3 распространяется по Apache License 2.0; [FFmpeg учитывает совместимость OpenSSL 3 с GPLv3](https://ffmpeg.org/pipermail/ffmpeg-cvslog/2021-September/128908.html). Эти флаги **сами по себе не являются причиной заменять рабочие бинарники**.

В `develop` найдена [ревизия скриптов FFmpeg 9.0.2](https://git.martin-riedl.de/ffmpeg/build-script/src/commit/6a611e19870e197bc37c6e4c7fccddebd3715466), опубликованная раньше обоих бинарных выпусков. Данные версий библиотек конкретных выпусков сохранены в `release-docs/`. В [SOURCE_REFERENCES.md](release-docs/SOURCE_REFERENCES.md) приведены ссылки на исходники конкретных версий и скрипты сборки поставщика.

В [release-docs/THIRD_PARTY_LICENSES.txt](release-docs/THIRD_PARTY_LICENSES.txt) сохранён полный официальный файл уведомлений упакованного yt-dlp 2026.08.19 и собраны установленные тексты FFmpeg/библиотек, Deno, V8, TypeScript и Bellota. Включены ThirdPartyNoticeText.txt TypeScript 6.0.3, уведомления 378 версий Rust-пакетов, обнаруженных в самом бинарнике Deno, найденных native/V8-компонентов и libz-sys 1.1.20 с лицензией закреплённой zlib-ng. Зависимости, найденные только в общем lock-файле, исключены. Отдельный манифест поставщика или переписка с ним не являются требованиями лицензий. Передавайте внешнюю папку `release-docs/` вместе с приложением; сама `.app` не менялась. Лицензия собственного кода находится в [LICENSE](LICENSE) и [release-docs/LICENSE](release-docs/LICENSE). Общие письма авторам об использовании инструментов не требуются по указанным лицензиям.
