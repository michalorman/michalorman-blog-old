---
layout: post
title: Procedury składowane w realizacji logiki biznesowej aplikacji
description: Wykorzystanie procedur składowanych do realizacji logiki biznesowej nie ma żadnego uzasadnienia. Oczywiście w niektórych aplikacjach i przy niektórych problemach ma to sens, jednak w ogólności to bardzo zły pomysł.
keywords: architektura aplikacja logika biznesowa stored procedure procedura składowana
navbar_pos: 1
---
Ostatnio postawiono mnie przed ciekawym problemem. Mianowicie chodziło o analizę architektury aplikacji w której logika
biznesowa znajduje się w bazie danych w postaci [procedur składowanych](http://en.wikipedia.org/wiki/Stored_procedure)) (ang. stored procedures)
i porównanie jej z architekturą, w której logika biznesowa znajduje się (niemal) w całości po stronie kodu aplikacji.
Początkowo wykorzystanie procedur składowanych może wydawać się dobrym pomysłem, aczkolwiek jest to prosty sposób,
aby stworzyć aplikację która będzie okrutnie ciężka w rozbudowie i utrzymaniu (a te dwie czynności są ważniejsze
niż samo kodowanie!).

## Mity architektury opartej o procedury składowane

Zacznijmy od tego czym jest procedura składowana. W uproszczeniu jest to funkcja w którą upakowano zbiór instrukcji
języka SQL. Do takiej procedury możemy przekazywać parametry, możemy ją wywoływać a sama procedura zwróci nam wynik
(wyniki) swojego działania. Co odróżnia taką procedurę od zwyczajnej metody? Ano to, że jest ona zaimplementowana
w samej bazie danych, co teoretycznie ma zredukować ilość zapytań kierowanych do bazy i zwiększać tym samym wydajność
całego systemu. Procedury składowane są wykorzystywane do implementowania polityki bezpieczeństwa aplikacji, poprzez
nadawanie uprawnień dla klienta do wykonania konkretnej procedury.

### Procedury składowane poprawiają wydajność

W dzisiejszych czasach wciąż żyją ludzie, którzy uważają, że ilość wykorzystywanej pamięci operacyjnej w systemie to problem
(przez co optymalizują swoje super linuksy tak aby na nich nic nie działało, ale przynajmniej system wykorzystywał 10MB z
4GB zainstalowanej pamięci). Podobnież żyją ludzie, którzy dalej myślą, że serwery wyposażone są w 350MHz procesory
i dyski twarde napędzane za pomocą korby (nie mylić z [CORBĄ](http://pl.wikipedia.org/wiki/CORBA) ;). Sprawa wydajności
jest wielce kontrowersyjna ponieważ nie jest tak łatwo stwierdzić, że problem ten w ogóle wystąpi (aczkolwiek
jest sporo przesłanek, pozwalających nam się zorientować czy i gdzie się wąskie gardło może pojawić).

Pierwsza zasada optymalizacji głosi:

> Nie rób tego!

Zaś druga, ta tylko dla ekspertów mówi:

> Nie rób tego teraz.

Oczywiście nie chodzi nam tutaj o kompletne ignorowanie problemu wydajności i radosne kodowanie jak nam się podoba, ponieważ
pewną higienę kodowania trzeba zachować. Jednakże tak jak do lekarza nie idziemy nie posiadając konkretnych objawów choroby, tak
z wydajnością aplikacji nie ma co walczyć jeżeli nie mamy konkretnych, a najlepiej mierzalnych i odtwarzalnych, dowodów na to,
że problem ten występuje.

Zatem pytanie, czy procedury składowane rzeczywiście poprawiają wydajność systemu? Prawidłowa odpowiedź będzie brzmiała: i tak
i nie. Jeżeli problem z wydajnością systemu nie występuje, to co mają procedury poprawić? Jeżeli występuje, to procedury
składowane są **jednym z rozwiązań** jakie możemy zastosować. Jednakże możemy również przypatrzeć się zapytaniom, jakie
nasza aplikacja generuje do bazy danych i je zoptymalizować. Możemy zastanowić się czy nie da się jakiś danych odpowiednio
wrzucić do pamięci podręcznej (ang. cache). Możemy pobawić się w klastrowanie
naszej aplikacji, w końcu możemy zrobić najprostszą modyfikację systemu, czyli zakupić serwer z lepszym prockiem.
Procedura składowana jest raczej ostatecznym rozwiązaniem, no chyba, że nasza aplikacja faktycznie wymaga bardzo szybkiej
odpowiedzi (z czym raczej niewielu nas się spotka).

Ludzie mają tendencję do wyolbrzymiania problemu wydajności, nawet w przypadku aplikacji biznesowej, która będzie
użytkowana przez góra 50 użytkowników. W takiej sytuacji problem wydajności po prostu nie istnieje (pomijając sytuację, w której
programista po prostu zchrzanił swoją robotę, ale czynnik ludzki może zawieść zarówno w przypadku konwencjonalnego kodu
jak i procedur składowanych). Bardzo często jeszcze słyszy się pieniaczy wołających jak to Groovy jest złym językiem
bo jest 30x wolniejszy od Javy, która sama też do demonów szybkości nie należy. Nie dociera do nich fakt, że w przypadku
aplikacji webowych (a do takich głównie się tych języków używa), nie ma to większego znaczenia, ponieważ czas generowania
samego dokumentu HTML to jest i tak maksymalnie [30% obsługi żądania](http://yuiblog.com/blog/2006/11/28/performance-research-part-1/).
Oznacza to, że 70% czasu obsługi żądania możemy poprawić wykorzystując proste praktyki [optymalizacji strony](http://developer.yahoo.com/performance/rules.html).
Jak tu zatem mówić o poprawianiu wydajności poprzez jakikolwiek mechanizm po stronie aplikacji?

Na zakończenie należy jeszcze wspomnieć, że technologie wykorzystywane w aplikacjach do tworzenia dynamicznych zapytań
SQL jak i same bazy danych robią wiele, aby zwiększyć wydajność samych zapytań. Dane często są cache'owane (i to na
wielu poziomach), zapytania są prekompilowane itd. itp. Generalnie wiele już zostało zrobione aby poprawić wydajność naszych
aplikacji także nie ma co demonizować problemu wydajności, dopóty nie stanie się on faktycznym problemem.

### Procedury składowane poprawiają bezpieczeństwo

W kontekście poprawiania bezpieczeństwa przez procedury składowane na myśli mam dwa zagadnienia:

* Zabezpieczanie danych przed dostępem nieuprawnionych użytkowników
* Ochronę bazy danych przed atakami typu SQL injection

#### Zabezpieczanie danych

Bazy danych udostępniają nam mechanizm określania uprawnień do wykonania konkretnej procedury dla konkretnego użytkownika.
Problem polega na tym, że mechanizm ten jest zbyt mało elastyczny i generalnie sprawia więcej problemów niż jest z niego
pożytku.

Każda aplikacja posiada wiele typów użytkowników, zapewne przynajmniej dwóch administratorów i regularnych użytkowników.
Problem w tym, że wszystkie te typy użytkowników poprzez aplikację łączą się z bazą z uprawnieniami jednego użytkownika,
takiego dla jakiego łączy się nasza aplikacje. Zatem wszyscy użytkownicy systemu z punktu widzenia bazy danych posiadają
takie same uprawnienia, czyli suma sumarum i tak musimy w kodzie naszej aplikacji ograniczać który użytkownik którą procedurę
może wywołać.

Poza tym problem bezpieczeństwa systemu wykracza poza pozwolenie na wykonanie konkretnych procedur w bazie. To także ograniczanie
dostępu do konkretnych widoków, zasobów wykonywania operacji czy utrzymywanie bezpiecznego połączenia. Może być tak, że
chcemy konkretnym typom użytkowników zabronić dostępu do konkretnych kolumn a nie całych tabel.

Sam mechanizm bazy danych jest tutaj niewystarczający. W przypadku konwencjonalnego kodu aplikacji mamy do dyspozycji
szereg frameworków, które pozwalają nam w łatwy i deklaratywny sposób zarządzań uprawnieniami użytkowników z wykorzystaniem
schematu opartego na rolach. Rozwiązania te są dużo bardziej elastyczne i łatwe do zaimplementowania, a sam schemat
został już z powodzeniem zastosowany w bardzo wielu aplikacjach. Z wykorzystaniem tych frameworków możemy zaimplementować
dużo skuteczniejszą politykę bezpieczeństwa, oczywiście o ile nie zawiedzie
[czynnik ludzki](http://www.computerweekly.com/Articles/2007/04/04/222892/The-human-factor-is-key-to-good-security.htm).

#### Wstrzykiwanie SQL

Ataki typu SQL injection to zmora wśród wszelkich aplikacji korzystających z baz danych. Atak tego typu zajmuje pierwsze
miejsce wśród [dziesięciu najczęstszych dziur bezpieczeństwa](http://owasptop10.googlecode.com/files/OWASP%20Top%2010%20-%202010.pdf) według
[OWASP](http://www.owasp.org/index.php/Main_Page). Czciciele procedur składowanych bardzo często argumentują wykorzystanie
ich właśnie przez zabezpieczenie przed tego typu atakami. Nie jest to jednak do końca prawda.

Po pierwsze, w procedurach składowanych możemy skleić dynamicznie instrukcję SQL. Możemy także przekazywać parametry
do tych procedur. Teraz każdy programista powinien zakodować sobie poniższe równanie:

> Parametry funkcji + Dynamiczny SQL = SQL injection

Oczywiście jest w tym równaniu sporo przesady, jednak danie możliwości modyfikacji zapytania SQL poprzez dynamiczne
dołączanie do niego parametrów, na które ma wpływ użytkownik systemu prowadzi do możliwości takiego ataku. Zatem same
procedury przed niczym nas nie bronią, jedynie odpowiednie ich wykorzystywanie powoduje, że taki atak jest niemożliwy.

Dokładnie ta sama zasada obowiązuje w przypadku konwencjonalnego kodu. Przekazywanie wcześniej nieobrobionych parametrów
bezpośrednio od użytkownika do zapytania SQL to zło w czystej postaci. Niezależnie jaki mechanizm wykorzystamy
zasada ta działa tak samo. Dotego w przypadku języków takich jak Java mamy szereg mechanizmów, które pozwalają nam
tworzyć dynamiczne zapytania w bezpieczny sposób nawet jak częścią tych zapytań są parametry wprowadzane
bezpośrednio od użytkownika. Oczywiście zawsze może znaleźć się jakiś nierozważny programista, który w zły sposób
skorzysta z możwliości frameworka, jednak czynnik ludzki może mieć negatywny wpływ za równo przy logice umieszczonej
w kodzie jak i procedurach składowanych. Żaden język sam się nie broni przed złym jego wykorzystywaniem.

## Co tracimy wykorzystując procedury składowane

Wykorzystując procedury składowane zyskujemy niewiele. Pozorny zysk wydajności a także iluzoryczne poczucie bezpieczeństwa.
Nie są to bynajmniej rzeczy, które przekonują za wykorzystaniem ich do implementacji logiki biznesowej. Jeżeli nic nie
zyskujemy to zobaczmy w takim razie co tracimy.

### Możliwość wykorzystania sprawdzonych wzorców projektowych

Samo napisanie aplikacji to jedno. Jednak dużo ważniejsza jest łatwość wprowadzania zmian oraz utrzymywania takiej aplikacji.
Przeciętny czas życia aplikacji internetowej to 2 do 5 lat w przypadku CRM to 10-15. W tym czasie musimy wprowadzać zmiany
w systemie, naprawiać błędy itd. Czasem też klienci chcą zmienić wygląd aplikacji a także technologie w nim wykorzystywane.
Wykorzystanie procedur składowanych skutecznie nam te manewry utrudni.

Wykorzystując procedury składowane nie będziemy mogli korzystać z dobrodziejstw i osiągnięć inżynierii oprogramowania z ostatnich
40 lat. W czasie tym opracowano wiele sprawdzonych wzorców i technik pozwalających nam na tworzenie aplikacji, które są
łatwe w utrzymaniu i pielęgnacji. Z wykorzystaniem procedur składowanych ciężko nam będzie zastosować te wzorce, a same procedury
w ogóle się im nie poddają. Będziemy musieli pożegnać się z [SOLID](http://en.wikipedia.org/wiki/Solid_%28object-oriented_design%29),
nie wykorzystamy wzorców projektowych (np. [MVC](/blog/2010/03/model-widok-kontroler/)). Generalnie kodowanie będzie uporczywe a modyfikowanie jeszcze
bardziej bolesne.

Dodatkowo dochodzi brak możliwości wykorzystania sensownego IDE, które ułatwi nam proces refaktoryzacji kodu, chociażby
poprzez wskazanie, gdzie wykorzystujemy konkretny obiekt.

Koszt utrzymania aplikacji opartej w znacznym stopniu o procedury składowane będzie bardzo wysoki. Drobna zmiana w procedurze
pociągnie za sobą spore modyfikacje w kodzie spowodowane nieodpowiednim podziałem warstw i odpowiedzialności. Do tego
kod nie będzie zrozumiały dla ewentualnych nowych programistów (gdzie wykorzystanie powszechnie znanych wzorców i konwencji ułatwia
ten proces). Brzydki i niezrozumiały kod pociągnie za sobą frustracje programistów co również nie wpłynie korzystnie
na jakość aplikacji.

### Możliwość wykorzystania sprawdzonych i przetestowanych frameworków

Wiele typowych problemów zostało już dawno rozwiązanych. Rozwiązania te dostępne są w sieci i czekają tylko aby
z nich skorzystać. Po co wyłamywać otwarte drzwi? Jeżeli skorzystamy z procedur
składowanych większość tych rozwiązań nie będziemy mogli zastosować, albo ich zastosowanie będzie wymagało znaczących
i męczących udziwnień czy łat. Pisząc od nowa pewne rzeczy nie mamy pewności, że działają one prawidłowo. W
przypadku gotowych rozwiązań są one używane przez bardzo wielu programistów przez co wiemy, że działają dobrze (a
jeżeli nie to gdzieś w sieci na pewno znajdziemy gotowe rozwiązanie problemu). Dla procedur składowanych takie
frameworki w ogóle nie istnieją co zmusza nas do ciągłego wynajdywania koła.

### Możliwość łatwego i szybkiego testowania aplikacji

Testowanie to integralna część developmentu (a przynajmniej być nią powinna). Mamy do wyboru wiele rodzajów testów
i frameworków je wspierających, od jednostkowych przez integracyjne, funkcjonalne, wydajnościowe. Mamy wiele narzędzi
służących do mockowania i stubowania obiektów. W końcu mamy narzędzia do tworzenia specyfikacji obiektów dla tych
którzy bawią się w [behavioral driven development](http://en.wikipedia.org/wiki/Behavior_Driven_Development). W przypadku
gdy nasza aplikacja będzie opierała się w znacznym stopniu o procedury składowane, części z tych narzędzi nie
będziemy mogli wykorzystać. Do tego testy będą musiały opierać się o dane znajdujące w bazie danych co może skutecznie
wydłużyć czas ich uruchamiania. Nie będziemy mogli też uruchamiać testów na szybszej, działającej w pamięci RAM
bazie, ponieważ będzie to wymagało stworzenia drugiego kompletu procedur składowanych (o ile taka baza w ogóle
będzie je wspierać). Także stosując procedury składowane należy zapomnieć o testach uruchamianych w izolacji, będziemy
potrzebować pełnej integracji ponieważ testowany kod będzie znajdował się w bazie danych.

### Możliwości refaktoringu jakie dają IDE

Niemal każdy język programowania posiada swoje wspaniałe IDE, które pozwala nam w łatwy sposób nawigować po kodzie
i go refaktorować. Wszystko aby programowało się nam przyjemniej i łatwiej. Nie jest mi obecnie znane tego typu
narzędzie służące do pisania procedur wbudowanych. Także żegnaj podpowiadaniu składni, wyszukiwaniu użycia danego
obiektu czy metody. Będziemy musieli męczyć się na własną rękę, najlepiej jeszcze w trybie 80x25.

Generalnie dobre IDE pozwala nam lepiej i wydajniej programować. Szkoda rezygnować z możliwości tych narzędzi
w imię wątpliwych zalet jakie dają nam procedury składowane.

## Podsumowanie

Nie chcę mówić, że procedury składowane to zło i powinno się ich zakazać. To upychanie logiki biznesowej do procedur
składowanych jest złe. Oczywiście jest wiele przypadków, gdy użycie takiej procedury jest lepszym rozwiązaniem
niż manipulowanie danymi w aplikacji (zwłaszcza kiedy chodzi o bardzo dużą kolekcję danych). Problem w tym, że takie
przypadki będą raczej rzadkie, a upychanie logiki do bazy danych, tylko w imię wątpliwych korzyści jest złe.
Procedura składowana powinna być użyta tam gdzie faktycznie jest taka potrzeba inaczej niepotrzebnie tylko
utrudniamy sobie pracę i narażamy sie na kłopoty w przyszłości.

Nie zawsze użycie procedury składowanej powoduje skok wydajnościowy aplikacji. Nie zawsze z resztą brak wydajności
jest problemem. Dlatego zamiast bawić się w jasnowidztwo i przewidywać potencjalne wąskie gardła lepiej obserwować
i testować działanie naszej aplikacji. Jeżeli faktycznie stwierdzimy, że mamy problem z wydajnością w konkretnym
miejscu możemy zabrać się do jego rozwiązywania, nawet przy użyciu procedur składowanych. Jeżeli byśmy napisali
aplikację od razu z użyciem procedur nie wiedzielibyśmy czy i jakiego rzędu skok wydajnościowy nastąpił.

Kwestie bezpieczeństwa to żaden argument za stosowaniem procedur składowanych. Generalnie spora ilość frameworków
pozwala nam w lepszy, łatwiejszy i bardziej elastyczny sposób implementować politykę bezpieczeństwa w naszej aplikacji.
Możliwości jakie daje nam sama baza danych są zbyt małe, aby zaspokoiły potrzeby nawet małej aplikacji.

Decydując się na implementację naszej aplikacji poprzez upchanie logiki do bazy danych musimy spodziewać się sporych
problemów z jej utrzymywaniem. Wprowadzanie zmian oraz poprawianie błędów może okazać się bardzo kosztowne, chociażby
ze względu na niemożliwość wykorzystania sprawdzonych i powszechnie znanych wzorców czy frameworków. Decydując się
na wykorzystanie procedur składowanych niejako sami skazujemy się w wielu miejscach na ponowne odkrywanie koła,
mimo iż te leżą obok i czekają aby je wykorzystać.

Generalnie ja uważam, że rola bazy danych powinna sprowadzać się jedynie do składowania danych. Wszelka logika,
nawet ta bezpośrednio związana z ograniczeniami w kolekcjach danych powinna być realizowana po stronie aplikacji.
Dzięki temu nasza aplikacja jest łatwiejsza w implementacji i późniejszym utrzymaniu. To aplikacja powinna
zapewniać poprawność danych, a baza powinna jedynie dane te przechowywać. Póki co nie widzę żadnego logicznego
uzasadnienia implementacji całej logiki biznesowej w postaci procedur składowanych. Część, która rzeczywiście
tego wymaga owszem, ale nie cała logika.