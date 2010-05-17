---
layout: post
title: Płynne zapytania w Rails
description: W inżynierii oprogramowania znany jest termin płynnych interfejsów (ang. fluent interfaces). W rails przy pomocy dyrektywy named_scope możemy korzystać z tej techniki do tworzenia płynnych zapytań.
keywords: Rails fluent interface interfaces płynne płynny interfejs interfejsy named_scope searchlogic
navbar_pos: 1
---
Inżynieria Oprogramowania opracowała termin [płynnych interfejsów](http://en.wikipedia.org/wiki/Fluent_interface)
(ang. fluent interfaces) jako pewien szczególny sposób projektowania API klasy, tak aby można było wykonywać na obiektach
tej klasy pewne czynności przy użyciu czytelniejszego kodu. Czytając taki kod mamy niemal wrażenie, że czytamy
książkę. Przykładem takiego API może być pewna forma wzorca [Builder](http://en.wikipedia.org/wiki/Builder_pattern):

{% highlight java %}
kawa = Kawa.czarna().goraca().bez_cukru().ze_smietanka();
{% endhighlight %}

Prawda, że czytelne? Podobny rodzaj interfejsów jest często wykorzystywany we wszelkiej maści frameworkach do
mockowania np. [Mockito](http://mockito.org/):

{% highlight java %}
List list = new ArrayList();
List spy = mock(ArrayList.class, withSettings()
                .spiedInstance(list)
                .defaultAnswer(CALLS_REAL_METHODS)
                .serializable());
{% endhighlight %}

Tego typu interfejsy można wykorzystywać nie tylko do budowania obiektów. Są one praktyczne także w przypadku
wyciągania kolekcji z bazy danych. Okazuje się, że framework [Rails](http://rubyonrails.org/) daje nam ciekawą
technikę łatwego tworzenia tego typu interfejsów, są to tzw. named scopes (zakresy nazwane?).

## Płynne zapytania z ``named_scope``

Załóżmy, że mamy taki oto prosty model biznesowy. Prowadzimy wypożyczalnię samochodów i w bazie danych ewidencjonujemy
zarówno samochody, opisywane przez model i markę, jak i zamówienia, które składane są na jeden samochód i przechowują
datę złożenia zamówienia. Chcemy teraz zaimplementować moduł do audytów, pozwalający nam na wyciąganie różnych
zestawień dotyczących zamówień. Powiedzmy, że potrzebujemy wylistować wszystkie zamówienia bieżące, czyli takie, które
dokonane zostały dnia dzisiejszego. Oczywiście moglibyśmy napisać to tak:

{% highlight ruby %}
RentOrder.all(:conditions => { :date => Date.current })
{% endhighlight %}

<div class="wise_owl">
<p>No pięknie! Nie dość, że ten kod jest mało czytelny, to jeszcze trzeba go będzie kopiować w każdym kontrolerze.
Do tego wywleka nam na wierzch wewnętrzną implementację klasy <code>RentOrder</code>. A co z hermetyzacją!?</p>
</div>

Mimo iż działa nie jest to podejście dobre. Po pierwsze ciężko jest na pierwszy rzut oka zrozumieć co autor miał
na myśli, musimy się nieco wgryźć w kod, aby zrozumieć co się dzieje. Po drugie niszczy to [enkapsulację](http://pl.wikipedia.org/wiki/Hermetyzacja), ponieważ obiekt wywołujący
takie zapytanie (którym potencjalnie będzie kontroler) musi znać wewnętrzną implementację klasy ``RentOrder``. Po
trzecie takie podejście nie wspiera zasady [DRY](http://pl.wikipedia.org/wiki/DRY) przez co w każdym miejscu gdzie
będziemy musieli odwołać się do tej kolekcji danych, będziemy musieli utworzyć podobne wyrażenie. Generalnie lipa,
ale Rails przychodzi nam z pomocą i pozwala takie zapytania umieścić w tzw. named scopes. Robimy to używając dyrektywy
``named_scope`` w naszym modelu:

{% highlight ruby %}
class RentOrder < ActiveRecord::Base
  belongs_to :car

  named_scope :current, :conditions => { :date => Date.current }
end
{% endhighlight %}

Dzięki temu pobranie bieżących zamówień możemy skrócić do:

{% highlight ruby %}
RentOrder.current
{% endhighlight %}

Wywołanie to jest zdecydowanie bardziej czytelne niż poprzednie.

<div class="hola_dog">
<p>Ok, zwiększyliśmy hermetyzację, oraz jesteśmy zgodni z zasadą DRY, po co nam jednak jakieś named
scope'y, czy nie mogliśmy użyć metody statycznej? Dlaczego nie lepiej było by skorzystać z konwencji <code>find</code>?</p>
</div>

Faktycznie, moglibyśmy to samo uzyskać w następujący sposób:

{% highlight ruby %}
RentOrder.find_all_by_date(Date.current)
{% endhighlight %}

Jednakże ponownie niszczymy enkapsulację. Zmiana sposobu przechowywania daty (np. zmiana nazwy atrybutu na
``order_date``) spowoduje, że powyższy kod przestanie działać (o czym nawet się nie dowiemy nie posiadając testów).
Jest jednak jeszcze jeden powód, dla którego lepiej utworzyć named scope'a. Mianowicie zakresy te można ze
sobą łączyć (ang. chaining).

### Łączenie ``named_scope``

Co to w praktyce oznacza? Zobaczmy na przykładzie. Dodajmy kolejnego scope'a. Tym
razem chcielibyśmy mieć możliwość pobrania wszystkich zamówień, które dotyczą konkretnej marki samochodu. Taki
scope wyglądałby następująco:

{% highlight ruby %}
class RentOrder < ActiveRecord::Base
  belongs_to :car

  named_scope :current, :conditions => { :date => Date.current }
  named_scope :for_mark, lambda { |mark|
    { :joins => :car, :conditions => ["cars.mark = ?", mark] }
  }
end
{% endhighlight %}

W tym przypadku niestety składnia nie jest zbyt przyjazna, ale gdy się nabierze trochę wprawy to przestaje
być ona taka enigmatyczna. Mamy tutaj przykład dwóch rzeczy. Po pierwsze przesyłania parametru do
named scope'a. Robimy to za pomocą wyrażenia ``lambda`` dostarczając jej blok z naszym parametrem. Kolejna rzecz
to dołączenie tabeli ``Car`` do naszego zapytania (parametr ``:joins``). Dzięki tej technice możemy
poszukać wszystkich zamówień dotyczących samochodu marki Audi w następujący sposób:

{% highlight ruby %}
RentOrder.for_mark('Audi')
{% endhighlight %}

Rails pozwala nam łączyć named scope'y w ciągi. Łącząc dwa nasze named scope'y możemy wyszukać wszystkie bieżące zamówienia samochodów
dotyczące konkretnej marki. Zrobilibyśmy to tak:

{% highlight ruby %}
RentOrder.current.for_mark('Audi')
{% endhighlight %}

Rails połączy te zapytania, generując w wyniku jedno, odpowiednio skonstruowane zapytanie SQL:

{% highlight sql %}
SELECT "rent_orders".* FROM "rent_orders" INNER JOIN "cars" ON "cars".id = "rent_orders".car_id WHERE ((cars.mark = 'Audi') AND ("rent_orders"."date" = '2010-05-07'))
{% endhighlight %}

<div class="hola_dog">
<p>Słyszałem kiedyś o train wrecks, czy czasem nie mamy tutaj z tym do czynienia? No i czy
nie jest niebezpiecznie wywoływać kolejne named scopy na wyniku zwracanym przez poprzedni?</p>
</div>

### Named scope to nie train wreck

Mimo iż taki ciąg wywołań faktycznie wygląda jak train wreck, to nie mamy tutaj do czynienia z "wagonami". Nie
łamiemy także [prawa Demeter](http://pl.wikipedia.org/wiki/Prawo_Demeter) mimo iż wysyłamy komunikaty do obiektów
zwracanych przez poprzednie wywołanie. Dzieje się tak, dlatego że wywołania kierujemy ciągle do tego samego
obiektu, tylko zamiast jedno po drugim, robimy je wszystkie naraz. Zobaczmy z jaką klasą mamy faktycznie do czynienia:

{% highlight irb %}
>> RentOrder.current.class
 => ActiveRecord::NamedScope::Scope
{% endhighlight %}

Zatem wszystkie wywołania będą kierowane do obiektu klasy ``ActiveRecord::NamedScope::Scope``. Oznacza to, że ten sam
efekt, co po złączeniu wywołań, osiągnęlibyśmy i w ten sposób:

{% highlight ruby %}
scope = RentOrder.current
scope = scope.for_mark('Audi')
{% endhighlight %}

Ponieważ wszystkie komunikaty kierujemy do tego samego obiektu to nie mamy do czynienia z żadnym z wyżej wymienionych
zjawisk. Ale w ten sposób nie wygląda to tak elegancko jak poprzednio.

### Problemy z named scope'ami

Generalnie w przypadku named scope możemy wykorzystywać te same parametry, jak przy każdym wyszukiwaniu
metodą ``find``. Jednakże są pewne ograniczenia. Po pierwsze Rails zgłupieje jak w kilku scope'ach znajdzie
poustawiane takie parametry jak ``:limit`` czy ``:order``, dlatego też trzeba być ostrożnym umieszczając
je w scope'ach. Kolejny problem, dotyczy już samego łączenia scope'ów. Przypuśćmy, że chcielibyśmy zrobić coś
takiego:

{% highlight ruby %}
RentOrder.current.for_mark('Audi').for_mark('Renault')
{% endhighlight %}

Niestety taka kombinacja nie zadziała tak jak byśmy tego chcieli, ponieważ poszczególne warunki są łączone
z użyciem operatora AND w efekcie dostajemy takie zapytanie:

{% highlight sql %}
SELECT "rent_orders".* FROM "rent_orders" INNER JOIN "cars" ON "cars".id = "rent_orders".car_id WHERE (((cars.mark = 'Renault') AND (cars.mark = 'Audi')) AND ("rent_orders"."date" = '2010-05-07'))
{% endhighlight %}

Jeżeli nie mamy w bazie samochodów, które mają markę jednocześnie Audi i Renault to zapytanie zwróci nam pustą
tablicę. Mimo kilku wad świadomi ograniczeń named scope'ów możemy korzystać z nich tworząc rozbudowane zapytania z
małych, prostych i reużywalnych klocków. Dodatkowo nasza logika jest hermetycznie zamknięta i znajduje się tam,
gdzie być powinna, czyli w modelu.

## Podsumowanie

Płynne interfejsy to świetna metoda tworzenia czytelnych dla ludzkiego oka API. Dzięki nim możemy tworzyć
ciągi wywołań, które niemal same się będą dokumentowały. Framework Rails pozwala nam tę konwencję przenieść
na zapytanie SQL-owe. Dzięki dyrektywie ``named_scope`` możemy utworzyć proste zapytania, które będziemy
potem mogli płynnie łączyć ze sobą. Jest to prosta i elegancka metoda budowania skomplikowanych
zapytań z prostych klocków, do tego zapewniająca dobrą hermetyzację oraz wspierająca zasadę DRY.