# FIXON Program Partnerski

Statyczna strona programu partnerskiego FIXON przygotowana do publikacji na GitHub Pages.

## Wejscia na strone

- `index.html` - glowna strona programu partnerskiego.
- `landing-pl.html` - krotki landing reklamowy po polsku.
- `landing-en.html` - krotki landing reklamowy po angielsku.
- `landing-de.html` - krotki landing reklamowy po niemiecku.
- `FIXON_partner_program_en.html` - skrot programu po angielsku.
- `FIXON_partnerprogramm_de.html` - skrot programu po niemiecku.
- `dokumenty/` - wersje podgladowe dokumentow, PDF i DOCX.
- `dokumenty/en/` oraz `dokumenty/de/` - robocze wersje jezykowe z notami lokalizacyjnymi.

## Publikacja na GitHub Pages

1. Utworz nowe repozytorium na GitHubie.
2. Wgraj/pushnij zawartosc tego folderu do repozytorium.
3. W ustawieniach repozytorium wejdz w **Settings -> Pages**.
4. Jako zrodlo wybierz **GitHub Actions**.
5. Po pierwszym pushu workflow `Deploy static site to Pages` opublikuje strone.

## Lokalny podglad

Strona jest statyczna, wiec mozesz otworzyc `index.html` bez budowania projektu.

Dla podgladu przez lokalny serwer:

```bash
node tools/static-server.mjs . 8098
```

Potem otworz:

```text
http://127.0.0.1:8098/
```

## Uwagi prawne

Wersje EN/DE dokumentow sa roboczymi wersjami do lokalizacji i nie sa finalna porada prawna. Przed wyslaniem do partnera lub podpisaniem nalezy zatwierdzic wybrana wersje jurysdykcyjna z lokalnym prawnikiem.
