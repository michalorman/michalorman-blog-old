---
layout: post
title: Problemy ze słuchawkami w HTC Hero
description: Problemy z wykryciem słuchawek po podłączeniu do telefonu HTC Hero. Problemem okazuje się być znany błąd tkwiący w systemie Android.
keywords: HTC Hero Android Google
---
Chciałem sobie przetestować działanie słuchawek w moim HTC Hero. Zasadniczo rzadko
kiedy z nich korzystam, ale akurat mi się nawinęły pod rękę jeszcze nierozpakowane. 
Wrzuciłem sobie nieco muzyki na telefon podłączam słuchawki a tu mała niespodzianka.
Dźwięk zamiast przes słuchawki wydobywa się z głośnika telefonu. Na nic zdało się
odłączanie i ponowne podłączanie słuchawek (ani nawet kręcenie nimi). Pomyślałem, że
to niemożliwe aby gdzieś była ukryta opcja przełączania dźwięku.

Systuacja zaczęła się robić dość poważna i trzeba było zasięgnąć rady u kochanego
wujka. Natrafiłem na [ten wątek](http://androidforums.com/htc-hero/7102-htc-hero-headphone-jack-problem.html).
Jak się okazuje, nie tylko ja mam ten problem. Co ciekawe, niektórzy piszą, że im
działały słuchawki a potem ni stąd ni zowąt przestały (włącznie z diodą stanu telefonu
i trackballem!).

Okazuję się, że jest to [znany błąd](http://code.google.com/p/android/issues/detail?id=2534) w systemie Android 1.5.
Moim rozwiązaniem było wyłączenie telefonu i włączenie go z podłączonymi słuchawkami.
Telefon je wykrył i teraz wykrywa za każdym razem jak je wkładam. Nie wiem tylko
jak długo ten stan rzeczy będzie zachowany i czy za jakiś czas znów przestanie wykrywać
włożenie słuchawek.

Wychodzi na to, że trzeba poczekać na update firmware'u. Póki co
oficjalnie dostępna jest wersja z Androidem 1.5, ale nieoficjalnie można ściągnąć z 2.0.
Dla tych co nie chcą wymieniać firmware'u na nieoficjalny pozostaje [ten widget](http://code.google.com/p/toggleheadset/),
który powstał jako swoisty workaround na opisany wyżej problem.