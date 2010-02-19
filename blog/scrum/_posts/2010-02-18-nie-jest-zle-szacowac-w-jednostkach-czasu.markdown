---
layout: post
title: Nie jest źle szacować w jednostkach czasu
description: O tym dlaczego szacowanie relatywne cierpi na te same i inne problemy jak szacowanie w jednostkach czasu
keywords: szacowanie estimation relatywne relative czas time unit man hours weeks scrum
navbar_pos: 1
---
Szacowanie wysiłku jaki będziemy musieli włożyć w implementację funkcjonalności, to
bodaj najcięższe zadanie jakie stawia się developerowi. Wie o tym każdy kto zetknął
się z pytaniem:

> Ile czasu ci to zajmie?

Pytanie to stawiają klienci naszym przełożonym, oni stawiają je kierownikom
projektów a ci pytają developerów.

Jak dotąd powstało wiele metod mających na celu ułatwić to zadanie, aczkolwiek
chyba żadne tak naprawdę tego nie robi. Ostatnio bardzo popularne jest szacowanie
nakładu pracy w tzw. [story points](http://en.wikipedia.org/wiki/Story_points) zamiast tradycyjnych jednostek czasu. W teorii
metoda ta wydaje się być bardzo fajna i wręcz idealna do tego celu. Jednakże jak
ktoś mądry powiedział:

> Teoria nie różni się od praktyki tylko w teorii.

O czym za chwilę się przekonamy.

### Story points w teorii

Szacowanie w tzw. story points różni się znacznie od szacowania w jednostkach czasu.
Szacowanie to polega na relatywnym określaniu wielkości zadania względem innych,
już zrealizowanych zadań. Na przykład podczas szacowania możemy powiedzieć, że
dane zadanie jest dwa razy większe od innego. Kluczem jest tutaj wyznaczenie
zadania jednostkowego względem którego będziemy szacowali (czyli takiego, którego
skala trudności wynosi 1). Co ważne nie musi to być najłatwiejsze zadanie (aczkolwiek
raczej powinno), łatwiejsze można określać w skali mniejszej od jednostkowej
(czyli np. 0,5).

Przyjrzyjmy się paru trywialnym przykładom ilustrującym ten rodzaj szacowania:

<a href="/images/house_plan.gif" title="Plan domu" rel="colorbox"><img src="/images/house_plan.gif" alt="Plan domu" /></a>

Powyższy obrazek przedstawia plan domu. Traktując wielkość pokoju jako zadania możemy
określić mniej więcej wielkości poszczególnych pokoi (np., że kuchnia jest dwa
razy większa od sypialni nr. 1).

Inny przykład, często pojawiający się w materiałach szkoleniowych dotyczących
metodyki Scrum, to mierzenie wielkości psów:

<a href="/images/dog-breeds.jpg" title="Rasy psów" rel="colorbox"><img src="/images/dog-breeds.jpg" alt="Rasy psów" /></a>

Traktując wielkość psa jako zadanie, możemy posortować je relatywnie względem wielkości
(możemy stwierdzić, że owczarek niemiecki jest 4 razy większy od pudla - możemy?).

Powyższe obrazki przedstawiają ideę szacowania relatywnego, jednakże zakładają
one daleko idące uproszczenie (o którym za chwilę). W każdym razie w praktyce wcale
nie jest tak fajnie i bajkowo.

### Story points w praktyce

Wyobraźmy sobie, że zostaliśmy postawieni przed zadaniem. Dostaliśmy do ręki łopatę
i mamy wykopać na działce dół. Znamy wymagania co do dołu, czyli jego wymiary
i głębokość. Teraz nasuwa się pytanie: ile czasu zajmie nam kopanie dołu wiedząc,
że postawienie altanki na tej samej działce zajęło nam 7 dni?

To jest właśnie problem z szacowaniem relatywnym. Porównywanie psów jest proste,
bo wszystko co porównujemy jest psem. Podobnie z porównywaniem pokoi. Jednakże ile razy
jest kuchnia większa od pudla? A gdybyśmy porównywali pod względem sierści, to jak
porównać żółtą gładką ścianę sypialni do bujnej sierści collie? Tak właśnie wygląda
porównywanie w praktyce! Zadania, które mamy do zrealizowania są często tak różne,
że nie można znaleźć wspólnego dla nich mianownika i od tak sobie je porównać. Są
po prostu rzeczy, których się nie powinno porównywać i tyle. Co nie zmienia faktu, że
musimy oszacować nakład pracy, bo klient czeka na naszą odpowiedź.

Szacowanie relatywne generuje podobne problemy co szacowanie w jednostkach czasu.
Po pierwsze musimy wybrać zadanie jednostkowe, a nie zawsze jest tak prosto to
zrobić i nie zawsze wszystko da się porównać do zadania "notyfikacji mailowej
o zarejestrowaniu nowego użytkownika". Poza tym, aby oszacować jakąś wielkość, trzeba mieć już jakąś
bazę, czyli zadania, których wielkość już znamy (innymi słowy, trzeba nauczyć
się szacować). Kłania się tutaj podstawowa fizyka, czyli możemy coś porównywać
do czegoś a nie samo w przestrzeni (tylko skąd wziąć to coś do czego porównywać?).
No i w końcu trzeba te nasze punkty przełożyć na czas, bo klient oczekuje
od nas konkretnej daty, a nie sumy punktów. Ale czy zadanie, które jest dwa razy
większe od innego zajmie nam dwa razy więcej czasu?

### Jak zatem szacować?

Odpowiedź jest prosta - jak nam wygodnie! Szacunki są tylko szacunkami i nie możemy
się w nich zatracić gubiąc tym samym podstawowe zasady [manifestu Agile](http://agilemanifesto.org/)

* **Responding to change over following a plan**

Szacunki mają nam dać pewną orientacyjną datę w jakiej pewna pula zadań będzie
zrealizowana. Monitorując postępy w pracy podejmujemy działania np. ratujące
projekt ze względu na opóźnienia, które zauważymy w trakcie realizacji projektu
(a nie przed jego rozpoczęciem!).

Wracając do zadania z łopatą. Nie oszacujemy czasu w jakim wykopiemy dół na
podstawie czasu jaki zajęło nam zbudowanie altanki. Możemy za to założyć, że zajmie nam
to powiedzmy 4 dni. Gdy po pierwszym dniu kopania zobaczymy ile wykopaliśmy,
możemy ten czas zrewidować (np. do 2 dni). Oczywiście nie uwzględnimy w tym rewidowaniu
faktu, że na drugi dzień będziemy mieli zakwasy i nasza wydajność spadnie, a pojutrze
ma padać, więc cały dzień nie będziemy kopać. To nie są sytuacje, które musimy
koniecznie przewidzieć. To są sytuacje, które musimy wyłapywać i podejmować
odpowiednie kroki wtedy, kiedy się one pojawiają mając na uwadze większy cel jakim
jest realizacja projektu.

Szacowanie w jednostkach czasu nie jest złem i nie powinniśmy z tej metody rezygnować
w imię mody na agile. Nie musimy być w naszych szacunkach bardzo dokładni. Szacowanie
co do godziny może nie mieć sensu, ale co do dnia już tak. Wszystko zależy od skali
projektu.

### Podsumowanie

Ten wpis nie ma na celu podżeganie do porzucenia relatywnej metody szacowania nakładu
pracy. Wpisem tym chciałem jednak zwrócić uwagę na kilka praktycznych aspektów
tego zagadnienia, o których nie dowiemy się z żadnego szkolenia czy książki. Być
może są zespoły, które dobrze radzą sobie z takim szacowaniem, ale mi się jeszcze
ta sztuka nie udała. W każdym razie nie bez większych problemów. Nie widzę sensu zamiany jednej
metody, która ma swoje problemy na inną która może pozbawiona jest tamtych, ale
generuje nowe. Wszystkim tym, którzy tak bardzo wychwalają metody szacowania
relatywnego życzę możliwości wykorzystania tej metody w praktyce. Ciekawe co wtedy
będą o niej mówili :). Być może ktoś zaprosi mnie na swoją sesję szacowania
relatywnego, chętnie zobaczę jak taka sesja wygląda w praktyce, nie w teorii.
