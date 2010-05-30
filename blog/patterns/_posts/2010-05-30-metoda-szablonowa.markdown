---
layout: post
title: Metoda Szablonowa
description: Opis wzorca projektowego Metoda Szablonowa (ang. Template Method).
keywords: design pattern wzorzec projektowy metoda szablonowa template method
navbar_pos: 1
---
Dawno nie pisałem o żadnym wzorcu projektowym. Ostatnio było o [MVC](/blog/2010/03/model-widok-kontroler), a potem
długo, długo nic. Czas zatem nadrobić zaległości. Tym razem będzie o jednym z moich ulubionych wzorców **Metodzie Szablonowej**
(ang. template method).

Bardzo często spotykam się z kodem, w którym aż się prosi o użycie tego wzorca, a mimo wszystko nie jest on
wykorzystywany (np. w API platformy Android). Wzorzec Metoda Szablonowa, jak każdy wzorzec, służy do hermetyzacji
pewnej części naszych obiektów, redukując duplikację kodu i wspierając zasadę [DRY](http://pl.wikipedia.org/wiki/DRY).
W przypadku Metody Szablonowej hermetyzowany jest algorytm.

## Metoda Szablonowa od kuchni

Dobra, co to znaczy, że "hermetyzowany jest algorytm"? Spróbujmy zrozumieć to na przykładzie robienia pizzy. Ta z jednej
strony bardzo smaczna, a z drugiej bardzo kaloryczna potrawa kuchni włoskiej występuje obecnie w wielu odmianach. Odmiany
te różnią się składnikami, grubością ciasta, kształtem itd. Przyjrzyjmy się procesowi tworzenia pizzy (od razu zaznaczam, że
nigdy w życiu żadnej pizzy nie zrobiłem i mam małe pojęcie jak to się robi, a poniższe opisy mają charakter poglądowy i nie
powinny być wykorzystywane jako faktyczne przepisy na zrobienie pizzy - za wszelkie skutki uboczne nie odpowiadam :).

Pizza Margherita:

  1. Przygotuj cienkie ciasto.
  2. Dodaj sos pomidorowy.
  3. Dodaj ser mozzarella.
  4. Dodaj bazylię oraz odrobinę oliwy.
  5. Piecz przez około 15 minut.

Pizza Sycylijska:

  1. Przygotuj grube ciasto.
  2. Dodaj sos pomidorowy.
  3. Dodaj oliwki i kapary.
  4. Dodaj przyprawy.
  5. Piecz przez około 15 minut.

Gdybyśmy chcieli zaimplementować powyższe przepisy w formie kodu, mógłby on wyglądać tak:

{% highlight java %}
public class Margherita {

    public void prepare() {
        prepareThinCake();
        addTomatoSauce();
        addMozarellaCheese();
        addBasilAndOil();
        bake();
    }

    private void bake() {
        System.out.println("Bake for 15 minutes...");
    }

    private void addBasilAndOil() {
        System.out.println("Adding basil and oil...");
    }

    private void addMozarellaCheese() {
        System.out.println("Adding mozarella cheese...");
    }

    private void addTomatoSauce() {
        System.out.println("Adding tomato sauce...");
    }

    private void prepareThinCake() {
        System.out.println("Preparing thin cake...");
    }

}
{% endhighlight %}

Dla pizzy sycylijskiej mielibyśmy coś takiego:

{% highlight java %}
public class Sicilian {

    public void prepare() {
        prepareThickCake();
        addTomatoSauce();
        addOlivesAndCapers();
        addSpices();
        bake();
    }

    private void bake() {
        System.out.println("Bake for 15 minutes...");
    }

    private void addSpices() {
        System.out.println("Adding spices...");
    }

    private void addOlivesAndCapers() {
        System.out.println("Adding olives and capers...");
    }

    private void addTomatoSauce() {
        System.out.println("Adding tomato sauce...");
    }

    private void prepareThickCake() {
        System.out.println("Preparing thick cake...");
    }

}
{% endhighlight %}

Analizując powyższe klasy widzimy, że metody ``bake()`` oraz ``addTomatoSauce()`` są takie same w obu klasach przez
co mamy zduplikowany kod. Ale co więcej metody ``prepare()`` w oby klasach są bardzo podobne. Jeżeli bliżej im się przyjrzeć
możemy zauważyć, że generalnie realizują one ten sam algorytm różnią się jedynie w implementacji. Uogólniając nasz przepis
przygotowania pizzy moglibyśmy zapisać tak:

Pizza:

  1. Przygotuj ciasto.
  2. Dodaj sos.
  3. Dodaj dodatki.
  4. Dodaj przyprawy.
  5. Upiecz.

Przepis ten jest na tyle ogólny, że nadawałby się także do przygotowania pizzy Pepperoni czy każdej innej.

Otrzymaliśmy zatem
szablon algorytmu przygotowania pizzy, a ponieważ algorytmy implementujemy w postaci metod, rozszyfrowaliśmy nazwę naszego
wzorca projektowego Metody Szablonowej.

Teraz jest dobre miejsce na przedstawienie jakiejś bardziej formalnej definicji:

> **Wzorzec Metoda Szablonowa** definiuje szkielet algorytmu w określonej metodzie, przekazując realizację niektórych jego
> kroków do klas podrzędnych. Klasy podrzędne mogą redefiniować pewne kroki algorytmu, ale nie mogą zmieniać jego ogólnej
> struktury.

Co to oznacza w przypadku naszych pizz? Ano, że każda pizza może sama wybierać rodzaj swojego ciasta, dodatków czy przypraw,
ale nie może zmienić kolejności wykonywania kroków (np. upiec ciasto przed dodaniem sosu i dodatków).

Stwórzmy zatem abstrakcyjną klasę, która będzie implementować nasz wzorzec metody szablonowej:

{% highlight java %}
public abstract class Pizza {

    public void prepare() {
        prepareCake();
        addTomatoSauce();
        addAdditions();
        addSpices();
        bake();
    }

    private void bake() {
        System.out.println("Bake for 15 minutes...");
    }

    protected abstract void addSpices();

    protected abstract void addAdditions();

    private void addTomatoSauce() {
        System.out.println("Adding tomato sauce...");
    }

    protected abstract void prepareCake();

}
{% endhighlight %}

Zwróćmy uwagę, że metody ``addSpices()``, ``addAdditions()`` oraz ``prepareCake()`` są abstrakcyjne, co oznacza, że
klasy potomne będą musiały je zaimplementować. Metoda ``prepare()`` jest naszą Metodą Szablonową definiującą algorytm
oraz delegującą pewne jego kroki do klas podrzędnych. Zobaczmy zatem jak teraz wygląda nasza klasa dla pizzy
sycylijskiej:

{% highlight java %}
public class Sicilian extends Pizza {

    @Override
    protected void addSpices() {
        System.out.println("Adding spices...");
    }

    @Override
    protected void addAdditions() {
        System.out.println("Adding olives and capers...");
    }

    @Override
    protected void prepareCake() {
        System.out.println("Preparing thick cake...");
    }

}
{% endhighlight %}

Rozszerzając klasę ``Pizza`` nie musimy definiować algorytmu a jedynie te jego elementy, które są specyficzne dla
konkretnej pizzy (w przypadku mergherity mielibyśmy cienkie ciasto oraz inne dodatki i przyprawy).

## Haczyki na Metodę Szablonową

Jeżeli przyjrzymy się naszej metodzie szablonowej spostrzeżemy, że nie jest ona jeszcze odpowiednio ogólna. Po pierwsze
sos jaki dodajemy jest pomidorowy, co pewnie sprawdza się w większości pizz, jednak czasem zdarza się, że zamiast pomidorowego
jest inny sos (np. biały). Podobnie sytuacja ma się w przypadku długości pieczenia.

Wzorzec Metoda Szablonowa pozwala nam w sposób opcjonalny modyfikować domyślne kroki algorytmu. Metody takie nazywamy haczykami (ang. hook methods).
Metody te nie są metodami abstrakcyjnymi i często też nie posiadają implementacji a ich przeciążanie jest opcjonalne.

Przykładowo, nasza klasa ``Pizza`` mogłaby zostać zmieniona tak:

{% highlight java %}
public abstract class Pizza {

    public void prepare() {
        prepareCake();
        addSauce();
        addAdditions();
        addSpices();
        bake();
    }

    protected void addSauce() {
        addTomatoSauce();
    }

    private void bake() {
        System.out.println("Bake for " + getBakeTime() + " minutes...");
    }

    protected String getBakeTime() {
        return "15";
    }

    protected abstract void addSpices();

    protected abstract void addAdditions();

    private void addTomatoSauce() {
        System.out.println("Adding tomato sauce...");
    }

    protected abstract void prepareCake();

}
{% endhighlight %}

Ta implementacja działa dokładnie tak samo jak poprzednia, jednak dzięki haczykom możemy zmienić jej domyślne zachowanie jeżeli
zajdzie taka potrzeba. Przykładowo przeciążając metodę ``addSauce()`` możemy zmienić domyślny sos pomidorowy na inny, przeładowując
``getBakeTime()`` możemy zmienić domyślną długość pieczenia. Oczywiście w poprzedniej wersji mogliśmy przeciążyć bezpośrednio metody
``addTomatoSauce()`` albo ``bake()`` jednakże nie byłoby to do końca dobrym pomysłem, ponieważ metody te mógłby realizować jakąś logikę
którą musielibyśmy skopiować w naszej klasie potomnej.

Haczyki to rzeczywiste metody zadeklarowane w klasie abstrakcyjnej posiadające albo domyślną implementację, albo pustą. Metody te pozwalają
na podpięcie się w różnych miejscach metody szablonowej zmieniając jej domyślne działanie jednak bez konieczności implementacji jakiejś
metody (klasa podrzędna może po prostu zignorować haczyk w przypadku metody abstrakcyjnej musi dostarczyć implementację). Aby skorzystać
z haczyka trzeba przesłonić go w klasie potomnej:

{% highlight java %}
public class Sicilian extends Pizza {

    @Override
    protected void addSpices() {
        System.out.println("Adding spices...");
    }

    @Override
    protected void addAdditions() {
        System.out.println("Adding olives and capers...");
    }

    @Override
    protected void prepareCake() {
        System.out.println("Preparing thick cake...");
    }

    @Override
    protected String getBakeTime() {
        return "20";
    }

}
{% endhighlight %}

Teraz nasza pizza będzie pieczona przed 20 a nie 15 minut.

## Podsumowanie

Metoda szablonowa to bardzo fajny wzorzec projektowy pozwalający na wyniesienie algorytmy na wyższy poziom abstrakcji. Tworzymy ogólny
algorytm szablonowy, a klasom potomnym zostawiamy implementację poszczególnych jego kroków. Dzięki temu nasz kod nie jest duplikowany,
jest przejrzysty a dodawanie nowych klas realizujących podobny algorytm jest szybsze, ponieważ definiujemy tylko niektóre jego kroki a nie cały algorytm.

Metody szablonowe posiadaj pewne domyślne działanie na które możemy wpływać za pomocą haczyków. Haczyki to są metody z konkretną, domyślną
implementacją, które klasy potomne mogą w razie potrzeby przesłaniać dodając swoją specyficzną logikę.

Metoda szablonowa jest wykorzystywana do sortowania w bibliotece Javy. Jeżeli chcemy posortować kolekcję naszych obiektów obiekty te muszą
implementować interfejs [``Comparable``](http://java.sun.com/j2se/1.4.2/docs/api/java/lang/Comparable.html) i dostarczyć implementację do
metody ``compareTo()``. Metoda szablonowa sama za nas odpowiednio posortuje kolekcję my jedynie musimy dostarczyć mechanizm porównywania
obiektów ze sobą.