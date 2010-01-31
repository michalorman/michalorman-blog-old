---
layout: default
title: Michał Orman - Moje projekty
description: Projekty realizaowane przez Michała Ormana
keywords: michał orman blog projekty
---
Tutaj krótko o projektach w których brałem udział. Niestety większość tych projektów nie jest publicznie dostępna, ale kilka jest (i liczę, że ta liczba znacznie się powiększy, bo na razie nie jest imponująca :)).

### Projekty komercyjne

Z projektów komercyjnych zasadniczo tylko jeden jest dostępny publicznie, jest to <a href="http://e-wypozyczanie.pl/">wypożyczalnia online</a>. Jest to projekt realizowany we współpracy z firmami <a href="http://consileon.pl/"><strong>Consileon Polska</strong></a> oraz <strong>JPJ Consulting</strong> mający na celu stworzenie webowej aplikacji dla profesjonalnych wypożyczalni (nie jakiś tam kolejny portal społecznościowy, w którym ludzie wypożyczają sobie różne przedmioty). Projekt ten jest w trakcie realizacji. Jego założeniem ma być pełna obsługa procesu wypożyczania od momentu weryfikacji formalnej klienta, przez sam proces wypożyczenia do momentu zwrotu przedmiotu wypożyczenia. System ma parę ambitnych rozwiązań biznesowych i jeszcze ambitniejsze plany, ale jak mówiłem, to ciągle work in progress. Technologie wykorzystane przy realizacji projektu to JSF, RichFaces, PrimeFaces, Seam z gdzieniegdzie wplecionym AJAX-em. W sumie powinienem się pochwalić, że jestem w tym projekcie tzw. Project Leaderem i głównym architektem, ale moje agilowo-scrumowe podejście każe mi się specjalnie nie wywyższać, gdyż uważam, że każdy członek projektu jest tak samo ważnym ogniwem jeżeli chodzi o prawidłowe zamodelowanie i zaimplementowanie aplikacji.

### Projekty prywatne

Jak dotąd nie upubliczniałem nigdzie projektów prywatnych, ale postanowiłem to zmienić, ze względu na to, że może to być całkiem niezła forma reklamy :). W każdym razie projekty prywatne realizuję zwykle w celach czysto naukowych i zdarza się, że je po prostu zostawiam (bo technologia jest do kitu, albo pojawiła się ciekawsza). Kiedyś głównie skupiałem się na pisaniu prostych gierek (roguelike rulez na zawsze! :P) jednak obecnie sporo wysiłku wkładam w platformę Java EE i z jej najnowszą wersją związane są obecnie realizowane przeze mnie projektu (dostępne na moim profilu <a href="http://github.com/michalorman">github</a>).

#### <a href="http://github.com/michalorman/football-league-manager">Football League Manager</a>

To projekt mający na celu stworzenie aplikacji z interfejsem webowym do zarządzania ligą piłkarską. Sam pogrywam sobie w takiej amatorskiej lidze i jak na informatyka przystało, bez większych sukcesów :P, no ale zawsze mam trochę ruchu (1 mecz + 2 treningi w tygodniu). Tak więc dziedzina nie jest mi obca i postanowiłem stworzyć taką aplikację a w międzyczasie pobawić się najnowszym Seam'em (na razie w wersji 2.2 ale docelowo 3.0), najnowszym JBoss AS-em (5.2-Beta2 aktualnie) oraz WebBeans. Planuję także przy okazji tej aplikacji przerobić JSF 2 oraz najnowsze JPA.

#### <a href="http://github.com/michalorman/webapp-toolkit">Webapp Toolkit</a>

Zbiór klas użytkowych, które powstaną przy okazji pisania poprzedniej aplikacji. Ogólnie nie do końca zgadzam się z modelem promowanym przez Seam, gdzie wartości formularzy są mapowane bezpośrednio na model. W niektórych przypadkach tak się nie da, ponieważ w JSF 1.2 nie da się "walidować" zależnych komponentów i nie ma wstrzykiwania zależności do walidatorów. W związku z tym old schoolowe formy wracają u mnie do łask. Być może nowa specyfikacja, JSF 2.0 to zmieni, ale na pewno powstaną inne klasy, które można by wykorzystać i je postaram się wydzielić i umieścić w tym projekcie. Co z tego wyjdzie zobaczymy, ale celem nie jest stworzenie nie wiadomo jak użytecznej biblioteki, a zwyczajne poznanie nowych technologii.

#### <a href="http://github.com/michalorman/sm-gen">sm-gen</a>

Proste narzędzie do generowania tzw. <a href="http://www.sitemaps.org/">XML sitemap</a>, czyli z polska mapy strony. Stworzenie tego narzędzia ma zasadniczo dwa cele. Pierwszym jest podszkolenie się w języku Ruby (który mnie ostatnio zafascynował). Drugi, bardziej praktyczny, cel to dodanie pewnej funkcjonalności, której nie znalazłem w darmowych, dostępnych narzędziach. Mianowicie chodzi mi o możliwość konfigurowania wartości atrybutów mapy w zależności od tego z jakim URL-em mam do czynienia, tak aby nie musieć tego robić ręcznie. Np. chciałbym aby URL'e zawierające np. */oferty/* automatycznie dostawały priorytet 0.8 a pozostałe 0.5. Do tego dojdzie pewnie jeszcze parę pomysłów w trakcie implementacji narzędzia.