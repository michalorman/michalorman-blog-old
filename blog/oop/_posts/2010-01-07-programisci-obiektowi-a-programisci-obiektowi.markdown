---
layout: post
title: Programiści obiektowi a programiści obiektowi
description: Dlaczego osoby, które używały języka obiektowego nie mogą uważać się za programistów obiektowych, czyli kiedy wiem, że programuję obiektowo.
keywords: Programowanie obiektowe SOLID GRASP wzorce projektowe klasa obiekt instancja egzemplarz
---
Co jakiś czas spotykam się ze stwierdzeniem:

> Programowałem w Javie/C# więc znam się na obiektówce.

Osoby wypowiadające to zdanie nawet nie wiedzą w jakim są błędzie. Co ciekawe takie stwierdzenie jest dość powszechne! Bardzo często kojarzy się programowanie obiektowe z językami obiektowymi a przecież jest to bardziej podejście i tok myślenia niż używanie słowa kluczowego `class`. To, że stworzyłem w życiu dwie klasy na krzyż nie czyni mnie programistą obiektowym. Większość takich programistów nie ma nawet pojęcia o takich terminach jak <b>obiekt</b> czy <b>komunikat</b> a także nie odróżnia <b>klasy</b> od <b>instancji/egzemplarza</b>. I jak tutaj mówić o jakimkolwiek programowaniu obiektowym? 

Nawiasem mówiąc można programować obiektowo nawet w języku C (i nie mówię tutaj o <a href="http://pl.wikipedia.org/wiki/Objective-C">Objective-C</a>) bo to jest kwestia podejścia a nie języka programowania. Oczywiście użycie języka nie posiadającego mechanizmów wspierających to podejście do programowania to swoisty strzał w kolano, gdyż większość rzeczy do upilnowania jest zrzucana na barki programistów (którzy i tak mają już dużo problemów).

Mówiąc o sobie jako programiście obiektowym:

1. Wiem czym jest <b>klasa</b>.
1. Wiem czym jest <b>instancja/egzemplarz</b>.
1. Wiem czym jest <b>komunikat</b>.

Wiedząc powyższe zasadniczo mam zadatki na bycie programistą obiektowym. Jest to bardzo dobry punkt wyjścia, ale w dalszej kolejności:

1. Moje klasy mają tylko <a href="http://en.wikipedia.org/wiki/Single_responsibility_principle">jedną odpowiedzialność</a>.
1. Moje klasy są <a href="http://en.wikipedia.org/wiki/Open/closed_principle">otwarte na rozszerzanie, ale zamknięte na modyfikację</a>.
1. Moje klasy mogę <a href="http://en.wikipedia.org/wiki/Liskov_substitution_principle">zamienić</a> na ich klasy pochodne, bez utraty funkcjonalności.
1. Moje interfejsy są odpowiednio <a href="http://en.wikipedia.org/wiki/Interface_segregation_principle">posegregowane</a> a klasy mają konkretne zastosowania.
1. Moje moduły <a href="http://en.wikipedia.org/wiki/Dependency_inversion_principle">zależą</a> od abstrakcji a nie szczegółów.

Teraz to już jestem niemal programistą obiektowym pełną gębą, ale jeszcze:

1. Moje klasy posiadają <a href="http://en.wikipedia.org/wiki/GRASP_(Object_Oriented_Design)#High_Cohesion">wysoką spójność</a>.
1. Moje klasy posiadają <a href="http://en.wikipedia.org/wiki/GRASP_(Object_Oriented_Design)#Low_Coupling">luźne powiązania</a>.

Oczywiście nie wszystko powyższe od razu. Jesteśmy tylko ludźmi i każdy z nas nie zawsze dobrze projektuje klasy, ale ponieważ znam potęgę <a href="http://pl.wikipedia.org/wiki/Refaktoryzacja">refaktoryzacji</a> oraz <a href="http://en.wikipedia.org/wiki/Design_pattern_(computer_science)">dobre praktyki programowania obiektowego</a> potrafię doprowadzić moje klasy do sensownego wyglądu.

W tym momencie mogę nazwać się programistą obiektowym i osobą, która zna się na programowaniu obiektowym. Czy wspomniałem tutaj o jakimkolwiek języku? Czy wymagam tutaj znajomości Javy lub C# czy jakiegokolwiek innego języka? Nie! Język programowania to tylko narzędzie, jak pędzel w rękach malarza.

### Posłowie

Dla purystów językowych chciałem zaznaczyć, iż nie wiem czy "programista obiektowy" to jakikolwiek termin, ale w moim rozumieniu jest to osoba znająca i stosująca reguły programowania obiektowego i w takim kontekście termin ten został użyty w tym wpisie :).