---
layout: post
title: Promowanie błędnych nawyków programistycznych
description: O tym jak to w książkach i bibliotekach promowane są błędne zwyczaje programistyczne i jak starać się ich unikać.
keywords: object oriented programming design analysis design patterns high cohesion low coupling
---
Smutną prawdą jest to, że jest wśród nas gro programistów - nazwijmy ich radosnymi koderami - którzy
za nic mają sobie podstawowe praktyki programistyczne. Niemal każdy, kto ma jako takie
pojęcie [o dobrych praktykach programowania obiektowego](http://michalorman.pl/blog/2010/01/programisci-obiektowi-a-programisci-obiektowi)
styka się z takimi "koderami" w swojej codziennej pracy. Zasadniczo, można próbować z nimi
walczyć, ale walka ta jest raczej skazana na porażkę i w myśl indiańskiego powiedzenia
trzeba wroga polubić, skoro nie można go pokonać.

Można się zastanawiać co jest powodem takiego stanu rzeczy. Oczywiście jako pierwsze
narzuca się niedouczenie naszych "koderów", i jest to jedyny uzasadniony powód
takiej radosnej twórczości. Jedyny uzasadniony dlatego, że nie każdy miał czas i ochotę
zapoznać się z teorią. Jednakże niedouczenie rokuje, że ów delikwent w końcu przeglądnie co nieco
materiału na temat OOP i się poprawi. Gorzej, jeżeli te zachowania wynikają stąd, że wiele takich
rozwiązań pojawia się w różnego rodzaju książkach, a w nich raczej spodziewamy
się rzetelnej wiedzy! W takiej sytuacji ów delikwent może nie tyle nie wiedzieć,
że robi źle, ale wręcz bronić takiego rozwiązania! Jeszcze gorzej jak owe praktyki
występują w API bibliotek standardowych (a o takie w bibliotece standardowej
Javy nie trudno) albo w obu naraz!

Oto przykład kodu, na który natknąłem się czytając książkę Kathy Sierry do SCJP
czyli książki, którą przeczytało tak na oko 99% osób przygotowujących się do egzaminu.
Na temat samego egzaminu nie będę się wypowiadał (teraz), ale ogólnie wiadomo, że przydatność
zdobytej tam wiedzy jest co najmniej wątpliwa. No ale cóż, trzeba zdać, aby nie być w tyle
(i mieć dostęp do kolejnych egzaminów).
W każdym razie, oto wspomniany kod:

{% highlight java %}
import java.io.*;

public class SerializeCat {
  public static void main(String[] args) {
    Cat c = new Cat();
    try {
      FileOutputStream fs = new FileOutputStream("testSer.ser");
      ObjectOutputStream os = new ObjectOutputStream(fs);
      os.writeObject(c);
      oa.close();
    } catch (Exception e) { e.printStackTrace(); }

    try {
      FileInputStream fis = new FileInputStream("testSer.ser");
      ObjectInputStream ois = new ObjectInputStream(fis);
      c = (Cat) ois.readObject();
      ois.close();
    } catch (Exception e) { e.printStackTrace(); }
  }
}
{% endhighlight %}

Powyższy kod jest dramatyczny i aż razi złymi nawykami programistycznymi. Oczywiście
doświadczony programista od razu je wychwyci i zrzuci je na lenistwo ludzi tworzących
tę książkę, jednakże nie czytają ją wyłącznie doświadczeni programiści.

Zacznijmy od najbardziej oczywistych błędów (a do tego najbardziej wrednych). Po pierwsze
połykanie wyjątków w klauzuli ``catch``. No bardzo nieładnie, a potem znajdujemy takie kwiatki
w bibliotekach frameworków (np. [Seam-a](http://michalorman.pl/blog/2009/12/zdradziecki-zielony-pasek-podczas-testow-integracyjnych-w-seam/))!
Dlaczego tak **nie wolno** robić tłumaczyć chyba nie muszę.

Kolejna rzecz to zamykanie strumienia. Taka rzecz **musi** odbywać się w bloku
``finally``! Zrozumiałbym, gdyby ten kod był w rozdziale przed omawianiem tego bloku,
ale nie jest! To już jest po prostu ignorancja! Po co kilka rozdziałów wcześniej całe
pitolenie o bloku ``finally`` jako jedynym słusznym miejscu gdzie należy zwalniać zasoby,
skoro parę stron dalej się te informacje zwyczajnie olewa?

Co w ogóle ciekawe, często taki blok pisany jest zwyczajnie źle. Prawidłowo powinien
wyglądać on mniej więcej tak:

{% highlight java %}
ObjectOutputStream os = null;
try {
  ObjectOutputStream os = new ObjectOutputStream(fs);
} finally {
  if (os != null) {
    try {
      os.close();
    } catch (IOException e) { ... }
  }
}
{% endhighlight %}

Często programiści zapominają o sprawdzeniu czy odpowiednia zmienna nie ma czasem
wartości ``null`` a przecież tworzenie strumienia może spowodować wyjątek, a wtedy
zmienna nie jest zainicjalizowana i dostajemy ``NullPointerException``.

Co ciekawe takie błędne zamykanie strumienia występuje nawet w [oficjalnej dokumentacji](http://java.sun.com/j2se/1.4.2/docs/api/java/io/ObjectOutputStream.html)
Javy dla klasy ObjectOutputStream. Zauważmy również, że w cytowanym przykładzie
strumień do pliku w ogóle nie jest zamykany!

Zasadniczo blok ``try-catch`` otaczający zamykanie strumienia jest tam niejako
pro forma. Demonstruje on pewien językowy bubel Javy, tzw. checked exceptions, czyli
wyjątki, które musimy albo obsłużyć albo wyrzucić w górę stosu. Dlaczego jest to bubel?
Ano konia z rzędem temu kto wymyśli jakąś sensowną metodę obsługi wyjątku rzuconego
podczas tworzenia bądź zamykania strumienia. Otóż okazuje się, że 99% takich obsłużeń
wyjątków to jest zwyczajne logowanie ich (reszta to połykanie ;)). W większości przypadków
nie da się ich obsłużyć. Wszystkie wyjątki powinny być typu unchecked, a wtedy kiedy będziemy wiedzieli jak obsłużyć
taką sytuację to sobie napiszemy stosowny blok (w myśl zasady configuration by exception - czyli
domyślne zachowanie zmieniamy tylko w wyjątkowych sytuacjach). Takie bloki ``try-catch`` które nic
nie robią sensownego zaśmiecają nam tylko kod. Polecam [artykuł](http://misko.hevery.com/2009/09/16/checked-exceptions-i-love-you-but-you-have-to-go/)
Miska Hevery'ego na ten temat.

No dobra przebrnęliśmy przez błędy wynikające z zaniedbań (albo ignorancji) autorów
książki. Jednak cytowany kod ma jeszcze błędy wynikające ze złego zaprojektowania API.
Niestety twórcy API Javy w wielu miejscach się nie popisali a nawyki te są
potem przenoszone na nasze projekty (w końcu wszyscy uczą się na przykładach m.in. z API).

Przyglądnijmy się jak jest serializowany nasz obiekt. Algorytm możemy opisać w następujących
krokach:

1. Stworzenie strumienia wyjściowego do pliku
2. Stworzenie strumienia wyjściowego dla obiektu ze wskazaniem na stworzony wcześniej plik
3. Serializowanie obiektu
4. Zamykanie strumieni

Czy powyższy algorytm nie wydaje wam się nieco zbyt skomplikowany? Owszem, rozumiem, że
operacja serializacji jest skomplikowana, jednak według mnie algorytm taki powinien wyglądać
tak:

1. Serializowanie obiektu

Cała reszta to tylko zbędne czynności. Wydaje się, że twórcy API chcieli wymyślić coś
super uniwersalnego, ale nie do końca chyba przemyśleli czy będzie to komuś potrzebne, a
jeśli już to niewielu programistom (za to wszystkim utrudnia życie).
Na szczęście rzadko kiedy potrzebujemy robić
serializację ręcznie, ale gdybyśmy musieli to głowę daję, że znaczna większość tego
typu kodu wyglądała by tak jak zacytowany (oczywiście z poprawnym zamykaniem strumieni ;)).
Dlaczego zatem musimy się tak trudzić? Wynika to ze złego wydzielenia odpowiedzialności.

Nie znając kodu ani obiektu ``FileOutputStream``, ani ``ObjectOutputStream`` możemy
spróbować wyobrazić sobie co one robią z serializowanym obiektem. Przy pomocy refleksji
jeżdżą po jego polach i polach obiektów do których on się odwołuje (i do których one się
odwołują ;)) itd. Oczywiście pomijając te oznaczone słowem kluczowym ``transient``.
Czyli odkrywają sobie to co my tak skrzętnie przed nimi ukryliśmy za pomocą
enkapsulacji. Czy są to odpowiedzialności tych obiektów? Ależ oczywiście, że nie!
Za serializację powinien być odpowiedzialny sam obiekt! Serializacja powinna
odbywać się mniej więcej tak:

{% highlight java %}
object.serialize();
{% endhighlight %}

I tyle! Bez zbędnych ceregieli! Ewentualnie jako parametr może brać np. nazwę pliku,
albo strumień wyjściowy (albo obie metody przeładowane - overloaded).
Zauważmy, że obiekty ``FileOutputStream`` oraz
``ObjectOutputStream`` to są anemiczne klasy. Nie służą nam kompletnie do niczego!
Tworzymy je, żeby wywołać jedną metodę a potem je pozamykać.

Prawidłowo zaimplementowany mechanizm serializacji powinien być zaimplementowany
tak, żeby obiekt sam potrafił się zserializować, gdyż to on zna najlepiej swój
stan. Nie żadne obiekty "narzędziowe"! Ba, domyślna implementacja powinna już być
gotowa (np. w klasie Object) a jeżeli chcemy to zmienić to używamy, **jedynego
najsensowniejszego** mechanizmu służącego do tego celu, czyli nadpisywania (ang. overriding)!
Po co nam jakieś bzdetne dekoratory i interfejsy markery (które notabene nic nie
znaczą)? Obiekty powinny być z założenia serializowalne
a jeżeli tego nie chcemy oznaczamy je jako ``transient`` i tyle. Analogicznie
obiekt powinien umieć zdeserializować swój stan, bez ujawniania swoich flaków
obiektom zewnętrznym (no chyba, że są one zagregowane wewnątrz).

Niestety to jest najczęstszy błąd z jakim się spotykam, czyli błędne przypisanie
odpowiedzialności. Pół biedy jak wynika ono z ograniczeń języka (nie można zmienić już
istniejącej klasy jeżeli jej nie przekompilujemy, tak jak można to robić np. w językach
dynamicznych), jednakże w klasach które sami projektujemy takie rzeczy nie powinny
występować (tak jak nie powinni ich robić programiści API mając dostęp do źródeł).

Jest kilka prostych sposobów zauważenia, że klasa jaką tworzymy nie ma sensu i
prawdopodobnie popełniliśmy błąd gdzieś w projekcie. Pierwszym symptomem jest brak pól
egzemplarza (ang. instance variables) w klasie. Prawidłowo zaimplementowana klasa powinna mieć
zarówno stan jak i odpowiedzialności (metody). Jeżeli posiada tylko metody to jest to klasa tzw. utilsowa, której
metody możemy spokojnie przenieść do dowolnie innej klasy albo zrobić statycznymi
co jest kolejnym elementem mówiącym nam, że klasa jest źle zaprojektowana. Z drugiej
strony, jeżeli klasa ma tylko pola (czyli stan) i żadnych metod biznesowych, to taka
klasa jest anemiczna ponieważ służy nam jedynie jako worek na dane, a nie jest nam
potrzebna do jakiejkolwiek logiki (no chyba, że do przesyłania danych).

Jak zatem określić do jakiej klasy powinna należeć metoda? Wystarczy przyglądnąć
się jej kodowi. Jeżeli taka metoda nie przyjmuje, żadnego argumentu, oznacza to, że
albo zwraca stałą, albo zwraca coś co pobiera statycznie lub z globalnego stanu co w ogóle oznacza, że jest
źle zaimplementowana. No chyba, że to jest getter ujawniający stan obiektu, co w wielu sytuacjach
również wskazuje na zły design. Jeżeli jednak przyjmuje jakiś argument(y) to należy sprawdzić,
co robimy z takim argumentem. Czy odpytujemy go o jakieś pola po czym robimy operacje
aby wynik zwrócić albo zapisać w tym samym obiekcie? To znaczy, że dana metoda jest odpowiedzialnością
tego obiektu. Rzućmy okiem na przykład:

{% highlight java %}
class DistanceCounter {
  public Double countDistance(ZipCode z1, ZipCode z2) {
    // obliczanie odległości pomiędzy kodami pocztowymi
    return distance;
  }
}
{% endhighlight %}

Powyższa klasa jest błędnie zaimplementowana, gdyż jest bezużyteczna. Metodę
obliczania odległości możemy śmiało zaimplementować w samej klasie ``ZipCode``:

{% highlight java %}
class ZipCode {
  public Double countDistance(ZipCode other) {
    // obliczanie odległości od tego kodu do podanego w parametrze...
    return distance;
  }
}
{% endhighlight %}

Zasadniczo, jeżeli widzimy, że metoda nie jest zaimplementowana we właściwej klasie
(ponieważ posiada któreś z wymienionych symptomów) niemal zawsze da się ona zaimplementować
w klasie którejś z jej parametrów (zwykle tej do której się najczęściej odwołujemy w metodzie).

### Podsumowanie

Wszyscy popełniamy błędy podczas programowania. Nie mam tu na myśli tylko błędów
w działaniu aplikacji, ale w jej projekcie. Wynika to z tego, że często prototypujemy,
albo nie mamy czasu na dokładny design. Ważne jest, abyśmy korzystali jednak z potęgi
refaktoryzacji i widząc oczywiste symptomy antywzorców i błędnych koncepcji poprawiali
je, o ile to możliwe od razu (bo pozostawione będą tam tkwić do końca). Nie łudźmy się,
że będziemy robić super architekturę od razu. To nie przychodzi nawet z doświadczeniem
bo co chwila stajemy przed nowymi wyzwaniami. Nauczmy się jednak czytać kod i wykrywać
potencjalne problemy.

Czytając wszelkie materiały, czy to książki czy API musimy zastosować zasadę
ograniczonego zaufania. Ludzie tworzący ów kod niekoniecznie są orłami w dziedzinie
poprawnego programowania, zgodnego z fundamentalnymi zasadami OO. Uważajmy, abyśmy
się nie nacięli i nie powielali złych praktyk w swoich projektach. Najlepiej filtrujmy
wszystko przez ``ZdrowyRozsądekFilter`` i analizujmy czy rzeczy, które powinny być
proste nie są nazbyt skomplikowane (czasem wynika to z tzw. przeintelektualizowania
problemu).