---
layout: post
title: Enkapsulacja a modyfikowanie stanu obiektów
description: W jaki sposób obiekty powinny zmieniać swój stan i jak poprawnie powinno się zachowywać enkapsulację.
keywords: enkapsulacja obiekt stan modyfikacja
navbar_pos: 1
---
Enkapsulacja to jeden z fundamentalnych terminów programowania obiektowego. Jest
to jednocześnie najmniej chyba rozumiany i najrzadziej stosowany paradygmat. Często
już pierwszy rzut oka na kod źródłowy mówi nam, że autor kodu niespecjalnie
przejmował się ukrywaniem stanu obiektu przed światem zewnętrznym. Poprawnie
stosowana enkapsulacja to jeden z najważniejszych czynników sprawiających, że
wszelkie późniejsze modyfikacje kodu będą po prostu łatwiejsze.

Zobaczmy, co o enkapsulacji mówi nam [Wikipedia](http://pl.wikipedia.org/wiki/Hermetyzacja):

> Polega ono na ukrywaniu pewnych danych składowych lub metod obiektów danej klasy tak, aby były one
> (i ich modyfikacja) dostępne tylko metodom wewnętrznym danej klasy lub funkcjom z nią zaprzyjaźnionym.
>
> Z pełną hermetyzacją mamy do czynienia wtedy, gdy dostęp do wszystkich pól w klasie jest możliwy tylko i
> wyłącznie poprzez metody, lub inaczej mówiąc gdy wszystkie pola w klasie znajdują się w sekcji prywatnej (lub chronionej).

Powyższy opis jest nieco mylący i nie do końca moim zdaniem poprawnie określa enkapsulację.
Opis spłaszczony jest do interpretowania
enkapsulacji w stylu SCJP, czyli deklarowania prywatnych pól oraz publicznych metod
do ich modyfikacji najlepiej zgodnie z konwencją [JavaBeans](http://pl.wikipedia.org/wiki/JavaBeans).
Takie podejście niestety niewiele ma wspólnego z poprawną enkapsulacją. Rzućmy okiem
na poniższą klasę:

{% highlight java %}
public class Foo {
  private int state;

  public void setState(int newState) { state = newState; }
  public int getState() { return state; }
}
{% endhighlight %}

Jaki sens w tym przypadku ma deklarowanie pola prywatnym skoro zaraz tworzymy
publiczne gettery i settery? Czy nie jest to tylko trochę trudniejsza droga do
zadeklarowania pola publicznym?

Wbrew pozorom taka deklaracja ma sens ale nie do końca taki jak się to programistom
wydaje. Takie deklaracje tłumaczy się tym, że nasza klasa `Foo` może wykonać dodatkowe
czynności podczas ustawiania pola `state` na przykład wykonać pewne walidacje podczas
wywołania metody `setState()`, co ma uchronić tę klasę przed posiadaniem stanu
niedozwolonego. Jednak nie to jest tutaj istotne! Istotne jest to, że modyfikacji
stanu obiektu dokonuje sam obiekt. W przypadku gdyby pole było publiczne stan obiektu
mógłby się zmieniać bez jego wiedzy.

Dokonajmy jednak małej zmiany w tej klasie, mianowicie zmieńmy typ pola `state`:

{% highlight java %}
public class Foo {
  private State state;

  public void setState(State newState) { state = newState; }
  public State getState() { return state; }
}
{% endhighlight %}

Pole to zamiast prymitywem jest teraz referencją do klasy `State`. Sytuacja jest
analogiczna jak wyżej, ale czy teraz możemy zagwarantować, że stan obiektu nie będzie
się zmieniał bez jego wiedzy? Niestety nie i to z wielu powodów. Po pierwsze obiekt
wskazywany przez parametr `newState` (w metodzie `setState()`) może posiadać więcej
referencji, przez co może być modyfikowany z zewnątrz. Podobnie w sytuacji, gdy
pobieramy stan metodą `getState()` mamy dostęp do samego obiektu i możemy go dowolnie
modyfikować. Także na nic zdadzą nam się wszelkie walidacje w metodach bo nie
gwarantują one, że stan obiektu nie zmieni się na niedozwolony. Np:

{% highlight java %}
public class HackFoo {
  public static void main(String[] args) {
    State s1 = new State();
    Foo f1 = new Foo();
    f1.setState(s1); // ewentualna walidacja przejdzie
    s1.makeInvalid(); // zmieniamy stan obiektu f1 !!

    State s2 = new State();
    Foo f2 = new Foo();
    f2.setState(s2);
    f2.getState().makeInvalid(); // zmieniamy stan obiektu f2 !!
  }
}
{% endhighlight %}

Tak więc enkapsulacja nie służy nam do tego, aby wykonywać jakieś dodatkowe
czynności podczas wywoływania metod. Prawidłowa enkapsulacja **gwarantuje nam,
że jedynym obiektem odpowiedzialnym za zmianę stanu jest sam obiekt** i nie ma
możliwości modyfikacji jego stanu z zewnątrz. Stan obiektu jest hermetycznie
odizolowany i wszelkie modyfikacje następują tylko w wyniku wysłania odpowiedniego
komunikatu do tego obiektu. To jest właśnie enkapsulacja.

Co ciekawe w API Javy w kilku miejscach mamy do czynienia z tzw. *"backed"* kolekcjami,
czyli kolekcjami w których zmiana w jednej jest automatycznie widoczna w innej. Pomijając
bardzo wątpliwą przydatność takiej funkcjonalności musimy uważać, gdyż enkapsulacja
została tutaj niejako celowo złamana i stan naszych obiektów może się zmieniać
w niekontrolowany przez nas sposób.

## Poprawna enkapsulacja

Jak zatem w poprawny sposób stosować enkapsulację? Przede wszystkim należy izolować
stan obiektu. Wszelkie referencje przekazywane w parametrach metod, albo zwracane
jako wynik działania metody to potencjalne miejsca, które mogą powodować, że stan
naszego obiektu będzie niedozwolony.

Zasadniczo ujawnianie stanu obiektu w sposób pozwalający na jego modyfikację to
bardzo zła praktyka programowa. Niestety często jesteśmy do tego zmuszani, przez
super profesjonalne i "enterprajsowe" frameworki (np. JSF). Dlaczego jest to
taka zła praktyka? Ponieważ ujawnianie w taki sposób stanu obiektu w prostej linii
prowadzi do zwiększania zależności pomiędzy obiektami czego nie chcemy (my chcemy
mieć luźne powiązania tzw. [loose coupling](http://en.wikipedia.org/wiki/Loose_coupling)).

W przypadku, kiedy nie możemy uniknąć ujawniania wewnętrznego stanu obiektu zastosujmy się do
reguł **[prawa Demeter](http://pl.wikipedia.org/wiki/Prawo_Demeter)**.

### Prawo Demeter czyli Reguła Ograniczania Interakcji

Prawo to w odniesieniu do programowania obiektowego narzuca pewne zasady, których
przestrzeganie rozluźnia powiązania pomiędzy obiektami. W uproszczeniu prawo to
zabrania, żeby obiekt ``A`` otrzymał dostęp do obiektu ``C`` poprzez obiekt
``B``.

Prawo Demeter zwane jest także **regułą ograniczania interakcji**. Reguła ta,
mówi:

> Rozmawiaj tylko z najbliższymi przyjaciółmi.

Aby zrozumieć lepiej tę regułę rzućmy okiem na przykład:

{% highlight java %}
public void addItemToCart(Item item) {
  cart.getItems().add(item);
}
{% endhighlight %}

Pytanie: *z iloma klasami jest powiązana klasa implementująca tę metodę?*.
Zastanówmy się nad tym. Niewątpliwie jedną klas jest klasa ``Cart``, ponieważ metoda
odwołuje się do zmiennej ``cart``. Kolejną klasą jest klasa ``Item`` gdyż jest
ona przekazywana do metody jako parametr ``item``. Ale czy to na pewno wszystkie
zależności? Otóż okazuje się, że nie! Klasa ta niejawnie jest powiązana z klasą
zwracaną przez wywołanie metody ``getItems()`` na rzecz obiektu ``cart``. Mimo, iż
jawnie takiej zależności nie deklarowaliśmy jesteśmy na nią skazani. Teraz,
gdybyśmy zmienili implementację klasy ``Cart`` tak, że zamiast metody ``add()`` należałoby
wywołać metodę ``put()`` musielibyśmy zmieniać to we wszystkich miejscach gdzie
w ten sposób dodawaliśmy coś do koszyka. Nasza klasa jest zależna od wewnętrznej
implementacji klasy ``Cart``!

Jak zatem prawidłowo dana sytuacja powinna być zaimplementowana? Oto przykładowe rozwiązanie:

{% highlight java %}
public void addItemToCart(Item item) {
  cart.addItem(item);
}
{% endhighlight %}

Poprzez **delegację**!
Nie interesuje mnie wewnętrzna implementacja klasy ``Cart``. Nie jest dla mnie ważne,
czy wewnętrznie do kolekcjonowania produktów używa listy, zbioru czy innej kolekcji (a
może nawet mapy). Ja po prostu chcę dodać obiekt do koszyka. Z drugiej strony, chcę
mieć możliwość zmiany implementacji koszyka bez potrzeby refaktoryzacji połowy
kodu (i jeszcze powiązanych testów).

Reguła ograniczania interakcji mówi, że wolno wywoływać tylko takie metody, które należą do:

* samego obiektu,
* obiektów przekazywanych jako argumenty metody,
* dowolnego obiektu, który tworzy dana metoda, oraz
* dowolnego składnika danego obiektu (obiektów agregowanych)

To oznacza, że nie możemy wywoływać metod na rzecz obiektów zwracanych nam jako
rezultat wywołania metody.

Stosując się do tej reguły ograniczamy listę obiektów (klas) jakie "zna" nasza
klasa, stąd powiązania pomiędzy poszczególnymi obiektami są luźniejsze. Krótko mówiąc,
nigdy nie powinniśmy dopuszczać do sytuacji, w której komunikujemy się z obiektem,
poprzez referencję którą otrzymujemy z innego obiektu. Taka komunikacja powinna
odbywać się przez delegację. 

W ten sposób doszliśmy do kolejnej reguły, którą
jest **reguła otwarte-zamknięte**.

### Reguła Otwarte-Zamknięte

[Reguła ta](http://en.wikipedia.org/wiki/Open/closed_principle) mówi, że obiekty powinny być **otwarte na rozszerzanie i zamknięte na
modyfikację**. Reguła ta nie zabrania nam modyfikowania klasy. Klasę możemy dowolnie
rozszerzać i modyfikować, jednakże modyfikacja klasy nie powinna pociągać za sobą
potrzeby modyfikacji kodu w innym miejscu.

We wcześniejszym przykładzie mieliśmy źle zaimplementowaną klasę, która nie była
zamknięta na modyfikację. Zmiana implementacji kolekcji przechowującej produkty
dodane do koszyka pociągała za sobą zmianę w implementacji klas korzystających
z takiego koszyka. Druga wersja tej metody poprawiała już ten błąd.

Zasadniczo jest jedna modyfikacja, która zawsze pociągnie za sobą potrzebę modyfikacji
kodu w innym miejscu. Jest to zmiana sygnatury metody czyli nazwy albo listy parametrów.
Dlatego kiedy dokonujemy takiej modyfikacji (zwłaszcza metody publicznej) powinniśmy 
być świadomi potencjalnych konsekwencji.

## Podsumowanie

Poprawna enkapsulacja gwarantuje nam, że nie zmienimy stanu obiektu bez jego wiedzy.
Dodatkowo kod będzie łatwiejszy w utrzymaniu i modyfikacji (taki skutek uboczny,
który dostajemy niejako gratis). Istnieje wiele zasad i reguł, których stosowanie
pozwala nam odpowiednio izolować stan obiektu i ograniczać powiązania pomiędzy
klasami. Warto poznać i stosować te reguły (a jest ich zdecydowanie więcej, niż
tylko te dwie, które przytoczyłem). Pamiętajmy, że dobry kod to nie tylko działający
kod, to także taki kod, który nie sprawia problemów podczas jego utrzymywania
i wprowadzania zmian.