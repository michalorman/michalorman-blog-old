---
layout: post
title: Konfiguracja serwera aplikacyjnego JBoss w systemie Linux
description: Instalacja aplikacyjnego JBoss AS w systemie Linux (OpenSUSE). Instalacja serwera oraz skryptów startowych, a także konfigurowanie systemu.
keywords: konfiguracja jbossas JBoss Application Server serwer aplikacyjny ubuntu debian open suse
navbar_pos: 1
---
Wpis ten pierwotnie powstał jako artykuł na moim prywatnym wiki, ponieważ jednak
zrezygnowałem (przynajmniej na razie) z prowadzenia wiki postanowiłem odświeżyć go
na blogu. Informacje te często mi są potrzebne a mają tendencję do
ulatywania z głowy, stąd muszę je mieć gdzieś zapisane, a blog wydaje się
do tego celu miejscem idealnym :).

## Wymagania

Opis ten dotyczyć będzie konfiguracji serwera aplikacyjnego JBoss w wersji [6.0.0.M2](http://www.jboss.org/jbossas/downloads.html)
(najbardziej aktualna w momencie pisania posta). Instalacja przeprowadzona zostanie
na systemie [OpenSUSE](http://www.opensuse.org/), podejrzewam, że proces instalacji
dla Debiana albo Ubuntu nie będzie się różnił zbytnio (akurat mam zainstalowanego
susła, ale na serwerach wykorzystuję raczej Debiana).

Oto pełna specyfikacja:

* JBoss AS 6.0.0.M2
* OpenSUSE 11.2
* JDK 1.6.0 (w wersji Sun-Oraclowskiej a nie OpenJDK)

Dodatkowo będą potrzebne następujące narzędzia (zakładam, że procedury instalacji
tych narzędzi nie trzeba omawiać):

* wget
* unzip

To chyba tyle, możemy brać się do roboty.

## Pobranie i instalacja serwera

Zaczynamy od pobrania serwera:

<pre>wget http://downloads.sourceforge.net/project/jboss/JBoss/JBoss-6.0.0.M2/jboss-6.0.0.M2.zip?use_mirror=ovh</pre>

Sam serwer zajmuje około 150MB zatem czas w jakim będzie się ściągał wykorzystamy
na kolejne zadania.

Uruchamianie serwera z uprawnieniami super <span class="striked">użyszkodnika</span> użytkownika
(tzw. root-a) nie jest dobrym pomysłem. W sytuacji gdyby jakiś zły użytkownik przejął
kontrolę nad serwerem miałby pełne uprawnienia w naszym systemie. Zwykle do takich
celów jak uruchamianie serwera tworzy się osobne konto użytkownika i nadaje mu się
uprawnienia do uruchamiania serwera. Zatem podążając za dobrą praktyką należy utworzyć
użytkownika **jboss**:

<pre>
mkdir /home/jboss
useradd -s /bin/bash -d /home/jboss jboss
chown jboss:users /home/jboss/
</pre>

W przypadku systemu OpenSUSE nowo utworzony użytkownik został przypisany do
grupy **users**, jednak w przypadku systemów Debian i Ubuntu zostałby przypisany
do grupy **jboss** (w takim przypadku w komendzie `chown` użylibyśmy `jboss:jboss`
zamiast `jboss:users`).

Rozpakowujemy ściągnięty serwer:

<pre>unzip jboss-6.0.0.M2.zip</pre>

Rozpakowany system musimy przenieść w miejsce bardziej dostępne. Tradycyjne miejsce
instalacji aplikacji w systemach Linux to `/usr/local` jednak często serwer instaluje
się w `/opt`. Zasadniczo nie ma wielkiej różnicy gdzie zostanie on zainstalowany,
ja skorzystam z opcji `/opt` dlatego, że jest krótsza ;). Zatem przenosimy
nasz serwer:

<pre>
mv jboss-6.0.0.20100216-M2 /opt/
cd /opt/
ln -s jboss-6.0.0.20100216-M2/ jboss
</pre>

Link symboliczny (utworzony za pomocą komendy `ln`) pozwoli nam łatwo i szybko
zmieniać wersje instalacyjne serwera bez modyfikacji skryptów. Przydaje to się
jak bawimy się różnymi wersjami serwera.

Teraz potrzebujemy zmienić właściciela tego serwera (aby nasz użytkownik
**jboss** miał odpowiednie uprawnienia):

<pre>chown -R jboss:users jboss jboss-6.0.0.20100216-M2/</pre>

W tym momencie sytuacja powinna wyglądać tak:

<pre>
ls -l
lrwxrwxrwx 1 jboss users   24 02-23 00:00 jboss -> jboss-6.0.0.20100216-M2/
drwxrwxr-x 8 jboss users 4096 02-15 17:42 jboss-6.0.0.20100216-M2
</pre>

System mamy zainstalowany, możemy przejść do konfiguracji skryptów uruchamiających.

## Konfiguracja skryptów uruchamiających

Tradycyjnie serwer aplikacyjny JBoss przychodzi nam ze zbiorem gotowych skryptów
służących do uruchamiania serwera dla różnych systemów. Co ciekawe jest wśród nich
skrypt dla systemu Suse co mnie bardzo ucieszyło. Niestety brakuje skryptu dla systemu 
Debian (a na nim mi nawet by bardziej zależało). W którymś z przyszłych postów będę 
musiał opisać stworzenie takiego skryptu, ale na razie skorzystam z gotowca.

Zatem kopiujemy nasz skrypt w odpowiednie miejsce, czyli katalog `/etc/init.d` w
którym znajdują się skrypty uruchamiane podczas startu systemu.

<pre>cp /opt/jboss/bin/jboss_init_suse.sh /etc/init.d/jboss</pre>

Skrypt w surowej formie nadaje się tylko jako szablon. Trzeba go edytować.

Ścieżka do instalacji JBossa w tym skrypcie jest prawidłowa więc pozostaje nam
jedynie skonfigurować ścieżkę do javy (JDK):

{% highlight bash %}
JAVAPTH=${JAVAPTH:-"/usr/lib/jvm/java-1.6.0-sun"}
{% endhighlight %}

Możemy też opcjonalnie ustawić zmienną `$JBOSS_CONSOLE` na plik w którym będą logowane
komunikaty, które normalnie zostałyby wyświetlone w konsoli (jeżeli tego nie zrobimy
to będą rzucane do `/dev/null`). Dzięki temu będziemy mogli podglądać co się aktualnie
dzieje na serwerze np. za pomocą komendy `tail -f`.

Zmienną tą możemy skonfigurować tak:

{% highlight bash %}
JBOSS_CONF=${JBOSS_CONF:-"default"}

JBOSS_CONSOLE=${JBOSS_CONSOLE:-"$JBOSS_HOME/server/$JBOSS_CONF/log/console.log"}
{% endhighlight %}

Tutaj należy się jedna uwaga. Trzeba ręcznie stworzyć katalog `log` w odpowiednim
katalogu serwera (odpowiadającego konfiguracji). Katalog ten jest tworzony automatycznie
przez serwer, jednak skrypt będzie chciał utworzyć plik `console.log` za pomocą
polecenia `touch`) i dostaniemy błąd o nieistniejącym katalogu (serwer wystartuje
mimo to). Przy drugim uruchomieniu serwera powinno już być wszystko w porządku. Oczywiście
należy przy tym nie zapomnieć o zmianie właściciela utworzonego katalogu.

Dodatkowo utworzyłem zmienną `$JBOSS_CONF` w której ustawiam konfigurację w jakiej
ma być uruchomiony serwer. Co ciekawe konfiguracja `default` jest na sztywno wprowadzona
w tym skrypcie do wywołania, zatem musimy zmodyfikować jeszcze ustawianie
zmiennej `$JBOSSSH` jak poniżej:

{% highlight bash %}
JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSS_CONF"}
{% endhighlight %}

Po wprowadzeniu wszystkich zmian plik powinien wyglądać mniej więcej tak:

{% highlight bash %}
JBOSS_HOME=${JBOSS_HOME:-"/opt/jboss"}

JAVAPTH=${JAVAPTH:-"/usr/lib/jvm/java-1.6.0-sun"}

JBOSSCP=${JBOSSCP:-"$JBOSS_HOME/bin/shutdown.jar:$JBOSS_HOME/client/jnet.jar"}

JBOSS_CONF=${JBOSS_CONF:-"default"}

JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSS_CONF"}

JBOSS_CONSOLE=${JBOSS_CONSOLE:-"$JBOSS_HOME/server/$JBOSS_CONF/log/console.log"}

# reszta nie zmieniona...
{% endhighlight %}

Skrypt jest gotowy, teraz trzeba skonfigurować system, aby uruchamiał skrypt w
czasie startu. Oczywiście należy upewnić się, że skrypt ma nadane uprawnienia
uruchamialności.

Instalacja takiego skryptu sprowadza się do stworzenia linków symbolicznych w katalogach
`/etc/init.d/rcX.d` uruchamianych podczas inicjalizowania tzw. runlevel. Oczywiście
nie robi się tego ręcznie. W OpenSUSE służy do tego komenda `insserv` (w Debianie
użylibyśmy wywołania `update-rc.d jboss defaults`). Uruchamiamy komendę:

<pre>
insserv jboss
insserv: Script jboss is broken: incomplete LSB comment.
insserv: missing `Required-Start:' entry: please add even if empty.
insserv: missing `Required-Stop:'  entry: please add even if empty.
</pre>

Komenda informuje nas, że skrypt jest nieprawidłowy. Komenda ta wczytuje pewne
(meta)informacje ze specjalnego bloku z komentarzem. Jak widać brakuje w nim
pewnych sekcji, zatem wypada je dodać:

<pre>
## BEGIN INIT INFO
# Provides: jboss
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Required-Start:
# Required-Stop:
# Description: Start the JBoss application server.
## END INIT INFO
</pre>

Ponieważ nie wiem jakie sensowne wartości nadać tym atrybutom, zgodnie z sugestią
komendy `insserv` dodałem je puste. teraz wygląda na to, że działa:

<pre>
insserv jboss
</pre>

Nasz serwer jest gotowy do pierwszego uruchomienia.

## Pierwsze uruchomienie serwera

Serwer uruchamiamy poleceniem:

<pre>/etc/init.d/jboss start</pre>

Możemy śledzić logi na konsoli:

<pre>tail -f /opt/jboss/server/default/log/console.log</pre>

Po uruchomieniu włączamy przeglądarkę, w pasku adresu wpisujemy `http://localhost:8080/`
i oczekujemy pojawienia się tejże strony:

<a href="/images/strona_powitalna_jboss.png" rel="colorbox" title="Strona powitalna serwera JBoss"><img src="/images/strona_powitalna_jboss.png" alt="Strona powitalna serwera JBoss" /></a>

Zasadniczo można by powiedzieć, że instalacja jest w tym momencie zakończona w końcu
mamy działający serwer. Jednakże jest to wrażenie pozorne. Gdyby to był serwer produkcyjny
i próbowalibyśmy dostać się z innego hosta niż `localhost` to by się nam to nie udało.
Dzieje się tak dlatego, że serwer JBoss w domyślnej konfiguracji nasłuchuje na porcie
8080 ale tylko połączeń przychodzących z lokalnego hosta. Komenda `netstat` nam to
wykaże:

<pre>
netstat -nplut | grep 8080
tcp        0      0 127.0.0.1:8080          0.0.0.0:*               LISTEN      7105/java
</pre>

Aby zmienić to zachowanie musimy zmodyfikować nasz skrypt uruchamiający dodając
parametr `-b` do wywołania komendy serwera:

{% highlight bash %}
JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSS_CONF -b 0.0.0.0"}
{% endhighlight %}

Parametr `-b 0.0.0.0` uruchomi serwer w trybie nasłuchującym połączeń z
dowolnego hosta. Szybki restart serwera:

<pre>/etc/init.d/jboss restart</pre>

I sprawdzamy jeszcze raz `netstat`:

<pre>
netstat -nplut | grep 8080
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      9402/java
</pre>

Działa! Serwer nasłuchuje na połączenie z dowolnego hosta. Jednakże nasłuchuje na
domyślnym porcie 8080 a jak wiadomo protokół [HTTP](http://pl.wikipedia.org/wiki/Hypertext_Transfer_Protocol)
wykorzystuje port 80.

Zasadniczo są dwa rozwiązania tego problemu. Pierwszy to skonfigurowanie serwera,
aby nasłuchiwał na porcie 80. Jednakże port 80-ty jest portem specjalnym. Z powodów
bezpieczeństwa portów poniżej 1024-tego mogą nasłuchiwać demony z uprawnieniami
root-a. Więc, aby nasłuchiwać na tym porcie musielibyśmy uruchamiać nasz serwer
w trybie super użytkownika, a tego przecież nie chcemy! Zatem potrzebne jest
inne rozwiązanie.

Inne rozwiązanie jest zasadniczo bardzo proste. Należy skonfigurować w systemie
przekierowanie połączeń przychodzących z portu 80 na port 8080. Posłuży nam do tego
nic innego jak `iptables`:

<pre>
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
iptables -t nat -A PREROUTING -p udp -m udp --dport 80 -j REDIRECT --to-ports 8080
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 8443
iptables -t nat -A PREROUTING -p udp -m udp --dport 443 -j REDIRECT --to-ports 8443
</pre>

Warto zauważyć, że oprócz portu 80 przekierowałem także port 443 służący do nawiązywania
połączeń [HTTPS](http://pl.wikipedia.org/wiki/HTTPS).

Powyższa konfiguracja działa w Debianie, jednak w OpenSUSE wymaga wyłączenia domyślnego
firewalla (i restartu systemu). W każdym razie podobno rozwiązanie tego problemu znajduje się
[tutaj](http://forums.opensuse.org/network-internet/423301-port-mapping-using-susefirewall2-mapping-port-80-8080-a.html),
ale mi aż tak bardzo na tym nie zależało, aby je sprawdzać.

Problem z powyższą konfiguracją jest taki, że po restarcie systemu trzeba ją na
nowo wprowadzać. Aby ominąć tę przeszkodę musimy najpierw zapisać konfigurację:

<pre>iptables-save > /etc/jboss_firewall.conf</pre>

A następnie stworzyć skrypt ją wczytujący:

{% highlight bash %}
#!/bin/sh
iptables-restore < /etc/jboss_firewall.conf
{% endhighlight %}

Skrypt ten należy umieścić w `/etc/sysconfig/network/if-up.d/` (w przypadku
Debiana w `/etc/network/if-up.d/`). Spowoduje to wczytanie konfiguracji zaraz
po tym jak podniesiony zostanie interfejs. Teraz po restarcie systemu nasze przekierowania
będą przywrócone. (O ile nie zapomnieliśmy skryptowi nadać praw uruchamialności `+x`.)

## Podsumowanie

Niniejszy post przedstawia sposób konfiguracji serwera JBoss w wersji 6.0.0.M2
w systemie OpenSUSE (z wstawkami dla systemu Debian/Ubuntu). Opis ten przedstawia
podstawową konfigurację serwera. Nie poruszałem tutaj kwestii load balancingu czy
klastrowania a także tuningu samego serwera (o tym będzie w przyszłym wpisie).
Przedstawiona tutaj konfiguracja jest konfiguracją wyjściową, pozwalającą nam na
łączenie się z serwerem przez port 80 z dowolnego hosta. Dodatkowe operacje zależą
już od konkretnego zastosowania serwera i maszyny na jakiej go uruchamiamy
(w tym dostępnych zasobów pamięci operacyjnej). Niemniej jednak mam nadzieję, że
komuś ten opis się przyda.

Wkrótce przedstawię plik startowy dla systemu Debian (który nie jest automatycznie
dystrybuowany z serwerem aplikacji) oraz parę dodatkowych zagadnień konfiguracyjnych
(takich jak konfiguracja pamięci czy lokalizacji).