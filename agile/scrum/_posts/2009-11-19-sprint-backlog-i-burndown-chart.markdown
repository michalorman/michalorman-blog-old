---
layout: post
title: Sprint backlog i burndown chart
tags: [scrum, sprint backlog, burndown chart]
description: Porównanie sposobów realizacji sprint backlog z metodyki scrum, oraz sposoby tworzenia burndown chart.
keywords: scrum sprint backlog burndown chart
---
Wcześniej pisałem o tym jak <a href="http://michalorman.pl/blog/2009/11/jak-stawalem-sie-bardziej-zwinny/">postanowiłem usprawnić metodykę</a> wytwarzania oprogramowania w prowadzonym przeze mnie projekcie. Ostatnio brałem udział w szkoleniu z <a href="http://pl.wikipedia.org/wiki/Scrum">metodyki Scrum</a> i co ciekawe, było to bodaj trzeci lub czwarty sposób realizacji Scruma. Podczas prezentacji było wiele dyskusji na temat różnych podejść do realizowania tych samych rzeczy (planowania product backloga, szacowania nakładu pracy itd.). Jedna z ciekawszych i bardziej kontrowersyjnych dyskusji dotyczyła aktualizacji <a href="http://en.wikipedia.org/wiki/Scrum_(development)#Sprint_backlog">sprint backloga</a> a co za tym idzie tworzenia <a href="http://en.wikipedia.org/wiki/Burn_down_chart">burndown chart</a>.

Metodyka przedstawiona na szkoleniu znacznie różniła się od tej, którą ja stosowałem i którą uważałem za ogólnie przyjętą (swoją drogą przeszukując google znajduję tylko przykłady robione w wersji używanej przeze mnie). Ta implementacja nie przekonała mnie jednak i pozostanę przy swojej, a mam ku temu szereg powodów, ale najpierw przedstawię na czym polegają obie metody.

### Metoda szkoleniowa

Tak pozwoliłem sobie nazwać metodę przedstawioną na wspomnianym szkoleniu. Mianowicie polegała ona na tym, że członkowie zespołu w kolejnych dniach pracy nad konkretnym zadaniem wpisywali ilość czasu spędzoną nad implementacją zadania. Sytuacja zatem wyglądała mniej więcej tak (o ile dobrze zrozumiałem ;)) zakładając, że mamy piątek:

<table>
    <tbody>
        <tr>
            <th>
                Zadanie
            </th>
            <th>
                Oszacowanie
            </th>
            <th>
                Pon
            </th>
            <th>
                Wt
            </th>
            <th>
                Śr
            </th>
            <th>
                Czw
            </th>
            <th>
                Pt
            </th>
        </tr>
        <tr>
            <td>
                Interfejs użytkownika
            </td>
            <td>
                10
            </td>
            <td>
            </td>
            <td>
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
            <td>
            </td>
        </tr>
        <tr>
            <td>
                Implementacja serwisu
            </td>
            <td>
                20
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
        </tr>
        <tr>
            <td>
                Implementacja DAO
            </td>
            <td>
                15
            </td>
            <td>
            </td>
            <td>
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
            <td>
                5
            </td>
        </tr>
    </tbody>
</table>

Powyższa tabela przedstawia ilość godzin spędzonych nad konkretnym zadaniem konkretnego dnia (przy założeniu 5-godzinnego dnia efektywnego - liczba ta wzięta jest arbitralnie dla ułatwienia obliczeń). Niestety jak dla mnie nie jest tutaj jasna sytuacja w projekcie , nie wiem nawet jak z tej tabelki wyznaczyć wykres burndown chart. Czy od całkowitej ilości zadań odejmuję sumę godzin spędzoną każdego dnia? Poza tym widzę tutaj kilka potencjalnych problemów:

* Zadanie implementacji serwisu zajęło w sumie 25 godzin a było planowane na 20 godzin, jednak o obsuwie dowiedzieliśmy się dopiero w piątek, a przecież mogliśmy o tym wiedzieć już we wtorek! Do tego burndown chart nie powie nam jaka jest skala problemu! Nie wiemy ile czasu jeszcze potrzeba na to zadanie i do kiedy będzie tak naprawdę realizowane.
* Zadanie implementacja DAO zajęło jak dotąd 15 godzin z 15 planowanych, ale czy zadanie to mamy uważać za gotowe? Skąd wiemy, czy potrzeba nad tym zadaniem popracować czy nie? Tak naprawdę dowiemy się o tym we wtorek, jak osoba odpowiedzialna za to zadanie zaktualizuje wpis za poniedziałek!

Tak więc poza problemami czysto obliczeniowymi (jak to przedstawić na wykresie?) mamy problemy czysto projektowe (ile właściwie pozostało nam pracy?). Dodatkowo wśród zadań w sprint backlogu miały znajdować się zadania nie dotyczące samej realizacji zadań (a np. doczytywaniu API czy specyfikacji), tak aby na podstawie tego backloga można było określić nad czym spędzaliśmy czas.

Moim zadaniem tak realizowany sprint backlog i burndown chart posiada 2 zasadnicze wady:

1. Sprint backlog i burndown chart nie służą raportowaniu.
2. Sprint backlog i burndown chart nie mają pokazywać ile zostało zrobione ale <strong>ile zostało do zrobienia</strong>.

W takim podejściu, nie dość, że mamy skomplikowaną metodykę to jeszcze nie wiemy gdzie tak naprawdę jesteśmy. Być może ja źle zrozumiałem całą ideę, a być może są jeszcze jakieś czynniki wpływające na diagram, a których nie wymieniono, jednak mimo wszystko uważam takie rozwiązanie za niepotrzebną komplikację. Być może wynikającą z tego, że prelegent używał do tego celu dokumentu excelowego (a właściwie odpowiednika z google doc). Do takiego dokumentu łatwo dodać kolejną automagiczną formułkę, przecież reszta robi się automatycznie, jednak można w ten sposób zatracić proste rozwiązania, a przecież Scrum wręcz nalega, aby robić rzeczy prosto, dlatego ja od dziwnych narzędzi wolę ścianę, kartki i pisaki.

Oto w jaki sposób ja realizuję sprint backlog.

### Metoda tradycyjna

Pozwoliłem ją sobie nazwać tradycyjną, gdyż we wszystkich źródłach jakie widziałem tak właśnie się ją realizuje (opisane np. <a href="http://www.mountaingoatsoftware.com/sprint-backlog">tu</a>, czy w <a href="http://www.infoq.com/minibooks/scrum-xp-from-the-trenches">tej</a> książce). Do rzeczy, oto jak wygląda backlog (zakładamy jak poprzednio, że mamy piątek):

<table>
    <tbody>
        <tr>
            <th>
                Zadanie
            </th>
            <th>
                Oszacowanie
            </th>
            <th>
                Pon
            </th>
            <th>
                Wt
            </th>
            <th>
                Śr
            </th>
            <th>
                Czw
            </th>
            <th>
                Pt
            </th>
        </tr>
        <tr>
            <td>
                Interfejs użytkownika
            </td>
            <td>
                10
            </td>
            <td>
                10
            </td>
            <td>
                10
            </td>
            <td>
                5
            </td>
            <td>
                0
            </td>
            <td>
                0
            </td>
        </tr>
        <tr>
            <td>
                Implementacja serwisu
            </td>
            <td>
                20
            </td>
            <td>
                15
            </td>
            <td>
                25
            </td>
            <td>
                20
            </td>
            <td>
                15
            </td>
            <td>
                10
            </td>
        </tr>
        <tr>
            <td>
                Implementacja DAO
            </td>
            <td>
                15
            </td>
            <td>
                15
            </td>
            <td>
                15
            </td>
            <td>
                10
            </td>
            <td>
                5
            </td>
            <td>
                0
            </td>
        </tr>
    </tbody>
</table>

Powyższa tabelka tworzona jest w taki sposób, że każdego dnia osoba, która realizowała dane zadanie wpisuje ile <strong>jeszcze</strong> czasu zajmie jej realizacja zadania. Nie patrzy na to ile było planowane, ile już je realizowała, ale<strong> ile czasu jeszcze zostało do jego zakończenia</strong>. To jest podstawowa różnica w porównaniu z poprzednią metodą. Ilość pracy potrzebnej do wykonania w konkretnym dniu to suma wszystkich cyfr dla danego dnia. W tym przypadku wiemy, że:

* Realizacja zadania implementacji serwisu zajmie nam jeszcze około 10 godzin (w poprzednim wiedzieliśmy, że się obsuwa, nie wiedzieliśmy tylko o ile), ba wiemy o obsuwie już od wtorku i mogliśmy poczynić odpowiednie kroki (np. usunąć jakąś funkcjonalność ze sprintu).
* Wiemy, że realizacja zadania implementacji DAO jest zakończona (w poprzednim nie wiedzieliśmy, czy będzie coś jeszcze w poniedziałek robione czy nie).

W tej wersji dokładnie wiemy ile jeszcze nam zostało pracy do zrobienia (no dobrze, może nie tak dokładnie bo to tylko szacunki, ale ponieważ to są szacunki zadań, a nie funkcjonalności są obarczone niewielkim błędem). Diagram burndown rysuje się prosto nawet ręcznie (wystarczy zaznaczyć kropkę w miejscu odpowiadającej sumie cyfr w danej kolumnie, nie trzeba żadnych dodatkowych operacji).

Metoda ta realizuje podstawowy cel sprint backlogu i burndown charta, czyli pokazuje ile pracy nam jeszcze zostało, a nie ile pracy wykonaliśmy. Do tego wcześniej zauważamy problemy, nie musimy czekać do momentu, aż ilość godzin przekroczy tę zaplanowaną, aby dowiedzieć się z diagramu o obsuwie. Każda wartość jest tak jakby ponownym oszacowaniem nakładu pracy (niektóre implementacje nakazują oszacowanie od nowa wszystkich zadań, inne oszacowania tylko tych nad którymi się pracowało a resztę przepisanie - ja preferuję tę drugą opcję) i może uwzględniać zmienne warunki w projekcie. A powodów do zmian może być wiele:

* Błędne oszacowanie nakładu pracy w czasie planowania sprintu.
* Dodatkowe, niespodziewane wymagania.
* Rzeczy do zrobienia o których wcześniej nie pomyśleliśmy.

To jest Agile, musimy umieć się dostosować do zmiennych warunków. Na podstawie szybkich informacji zwrotnych możemy podejmować decyzje (np. przerwanie sprintu, wyrzucenie jakiegoś zadania albo kontynuowanie w takim stanie jak jest). Metoda ta w moim przekonaniu daje nam szybciej informacje zwrotne i lepiej pokazuje jaka jest sytuacja w projekcie.

### Podsumowanie

Nie jestem fanatykiem i nie narzucam nikomu w jaki sposób ma realizować Scrum, ba uważam, że sztywne trzymanie się reguł i zasad jest złe! Scrum wręcz nakazuje nam adoptowanie procesu! Uważam, że metoda używana przeze mnie jest po prostu lepsza. Daje szybciej informację zwrotną, skupia się na ilości pracy do zrealizowania a nie już zrealizowanej a do tego jest prosta (łatwo można nanosić zmiany na diagram ręcznie, nie potrzebuję do tego arkusza kalkulacyjnego). Nikomu jednak nie będę tej metody narzucał, każdy zespół powinien sam ustalić jak realizować poszczególne etapy Scruma, jednak nie powinno się zapominać o tym do czego poszczególne elementy mają służyć, a w przypadku metody przedstawionej na szkoleniu w moim odczuciu zapomniano.