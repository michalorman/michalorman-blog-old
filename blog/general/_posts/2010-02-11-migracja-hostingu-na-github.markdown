---
layout: post
title: Migracja hostingu na github.
description: Migracja hostingu bloga z OVH na GitHub
keywords: hosting ovh github
---
Jeżeli czytasz tego bloga to znaczy, że migracja hostingu z OVH na GitHub przebiegła
pomyślnie :). GitHub to platforma pozwalająca na trzymanie i zarządzanie kodem
wersjonowanym z użyciem narzędzia Git. Platforma ta cały czas nie przestaje mnie
zaskakiwać. Co ciekawe, każdy kto posiada tam konto ma do dyspozycji hosting
niejako gratis. Każdy ma możliwość hostingu swojej strony głównej (tj. blog czy portfolio),
oraz strony projektów. Po szczegóły odsyłam (do dokumentacji)[http://pages.github.com/].

Aby stworzyć stronę hostowaną na GitHub należy poczynić 2 kroki. Pierwszy krok
to utworzenie repozytorium o nazwie: ``username.github.com`` gdzie ``username`` to
twoja nazwa użytkownika GitHub. Drugi krok to stworzenie pliku ``index.html``
i wrzucenie (push) do repozytorium. Powinniśmy otrzymać maila z informacją, że strona
została poprawnie stworzona i jeżeli był to nasz pierwszy ``push`` to musimy odczekać
około 10 minut. Od tej chwili mamy hostowaną witrynę, którą aktualizujemy wraz z każdym
aktualizowaniem kodu (w gałęzi master).

Co jeszcze ciekawsze, GitHub automatycznie przepuszcza wszystkie strony przez
Jekyll-a (o ile nie zdefiniujemy pliku .nojekyll). Nie trzeba samemu tworzyć i
commitować katalogu ``_site`` GitHub zrobi to za nas i będziemy mieli aktualnie
zbudowaną stronę wraz z każdym wrzuceniem zmian do repozytorium.

Pozostaje pytanie, dlaczego postanowiłem zmienić hosting z OVH na GitHub? Powodów jest
wiele. GitHub działa znaaaacznie szybciej (nawet w najtańszym pakiecie). Rozumiem, że
w najtańszej usłudze OVH byłem na szarym końcu QoS-a, ale szybkość działania to
była lekka przesada (zwłaszcza, że strony były statyczne!). GitHub w porównaniu
z moją usługą OVH to jak Ferrari przy maluchu. Kolejny powód to notoryczne zrywanie
połączenia podczas przerzucania danych przez FTP - niezależnie od tego jakiego
klienta używałem. O ile problemy z wydajnością można było zrozumieć, o tyle
zrywanie połączenia to był po prostu skandal (i dlatego OVH nie dostanie ode mnie
więcej ani złotówki). Nie dało się jednorazowo przerzucić większej partii danych
(a przy jekyll musiałem aktualizować całą witrynę). Gdy używałem WordPress'a
problem ten nie był tak dokuczliwy, ale przy Jekyll już strasznie wnerwiał. Także
podziękowałem panom z OVH i specjalnie nie będę za nimi tęsknił. Teraz publikacja
bloga sprowadza się do wykonania jednego polecenia:

    git push origin master
  
Działą szybko i bezproblemowo. Trzeba przyznać, że panowie od GitHub odwalili
kawał naprawdę niezłej roboty.
