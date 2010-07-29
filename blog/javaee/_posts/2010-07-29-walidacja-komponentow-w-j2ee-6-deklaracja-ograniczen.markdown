---
layout: post
title: Walidacja komponentów w J2EE 6 - deklaracja ograniczeń
description: Analiza drugiej sekcji specyfikacji JSR 303 dotyczącej deklaracji ograniczeń oraz procesu walidacji.
keywords: JSR 303 bean validation constraint deklaracja ograniczenie walidacja J2EE 6
---
Kolejna sekcja specyfikacji **JSR 303 Bean Validation** dotyczy formalnych wymagań dotyczących
deklaracji ograniczeń w komponentach, oraz samemu procesowi walidacji. Sekcja ta mimo iż krótka, to
czyta się ją dość długo, głównie ze względu na "suchość" i formalność podanych informacji. No ale
nie ma co przedłużać, przejdźmy od razu do rzeczy.

## Wymagania dotyczące komponentów

Specyfikacja zaczyna się od wyszczególnienia wymagań dotyczących komponentów, które mogą deklarować
ograniczenia. Komponent musi, jak wszystko w świecie J2EE, być zgodny z założeniami konwencji
[JavaBeans](http://pl.wikipedia.org/wiki/JavaBeans). Dodatkowo pojawia się informacja, że pola i
metody statyczne nie są poddawane walidacji.

## Deklaracja ograniczeń

Specyfikacja JSR 303 określa, że adnotacje ograniczeń mogą zostać zadeklarowane na poziomie pola
klasy, gettera zgodnego ze specyfikacją JavaBeans oraz na poziomie całej klasy. Jeżeli adnotacja
jest zadeklarowana na poziomie pola to wartość tego pola jest przesyłana jako parametr do walidatora
(klasy implementującej interfejs ``javax.validation.ConstraintValidator`` zadeklarowanej w definicji
adnotacji ograniczenia). Jeżeli adnotacja zadeklarowana jest na poziomie gettera to przesyłana jest
wartość zwracana przez ten getter. Jeżeli natomiast adnotacja jest na poziomie całej klasy, to referencja
do obiektu tej klasy zostanie przesłana do walidacji.

Jest to w pewnym sensie rozwiązanie problemu walidacji pól, których wartości zależą od siebie nawzajem
(tak jak pisałem w [poprzednim poście](/blog/2010/07/walidacja-komponentów-w-j2ee-6-ograniczenia/)). Jeżeli
potrzebujemy walidować takie pola to adnotację powinniśmy umieścić na poziomie klasy. Przykładowo, mając taki
model:

{% highlight java %}
@Entity
public class RentOrder {
  @Column
  private Date rentFrom;

  @Column
  private Date rentTo;

  public boolean isRentToAfterRentFrom() {
    return rentTo.after(rentFrom);
  }
}
{% endhighlight %}

Chcielibyśmy sprawdzać, czy aby wartość pola ``rentTo`` nie jest datą przed ``rentFrom``. Aby rozwiązać
ten problem moglibyśmy utworzyć adnotację ograniczenia, np: ``@RentPeriod`` i umieścić go na poziomie
klasy:

{% highlight java %}
@Entity
@RentPeriod
public class RentOrder {
  // ...
}
{% endhighlight %}

Odpowiedni walidator wyglądałby następująco:

{% highlight java %}
public class RentPeriodValidatorForRentOrder implements ConstraintValidator<RentPeriod, RentOrder> {
  public void initialize(RentPeriod period) { }

  public boolean isValid(RentOrder order, ConstraintValidatorContext context) {
    return order.isRentToAfterRentFrom();
  }
}
{% endhighlight %}

Tak więc używając adnotacji na poziomie klasy możemy sprawdzić wartości zależnych pól. Nie jest to rozwiązanie
doskonałe, jak widać nasza klasa walidatora jest ściśle powiązana z klasą, którą waliduje. Jeżeli inna klasa
będzie potrzebowała podobnej walidacji musielibyśmy stworzyć kolejny walidator. Nie jest to zbyt fajne.
Moglibyśmy spróbować zrobić walidator bardziej uniwersalnym deklarując jakiś interfejs np. ``Periodical``, który implementował
by model, jednak działałoby to w przypadku gdy posiadalibyśmy tylko 1 parę dat zależnych od siebie (jako okres od - do).
Być może specyfikacja w dalszej części w lepszy sposób rozwiązuje ten problem, na razie zostaje nam tylko ten
powyższy, nie do końca doskonały sposób.

No dobra, jest jeszcze jeden sposób, ale nie jestem pewien w tym momencie czy zadziała (tzn. zgodnie ze specyfikacją powinien,
ale nie sprawdzałem go jeszcze w praktyce). Moglibyśmy adnotację walidacji nałożyć na metodę sprawdzającą okres wypożyczenia
w modelu:

{% highlight java %}
@Entity
public class RentOrder {
  @Column
  private Date rentFrom;

  @Column
  private Date rentTo;

  @True(message = "Date of rent from should be before date of rent to.")
  public boolean isRentToAfterRentFrom() {
    return rentTo.after(rentFrom);
  }
}
{% endhighlight %}

Walidator dla ograniczenia ``@True`` sprawdzałby czy walidowana wartość wynosi ``true``. Skoro specyfikacja mówi,
że dla getterów JavaBeans (a metoda ``isRentToAfterRentFrom()`` jest, zgodnie z tą konwencją, prawidłowym getterem
dla zmiennej typu ``Boolean``) walidowana jest wartość zwracana przez te gettery, to powyższa konstrukcja powinna
działać. I jest to rozwiązanie generalnie lepsze niż poprzednie, ponieważ nie mnożymy walidatorów (ani dla innych klas
ani dla innych kombinacji zależnych atrybutów) i możemy podpiąć
je do wielu zależnych atrybutów jednocześnie (w różnych kombinacjach). Poza tym o sposobie walidacji poszczególnych
pól decyduje sama klasa modelu, przez co nie musimy niszczyć enkapsulacji getterami i setterami i zapisywać logiki
gdzieś indziej. Możemy też łatwo ręcznie odpalić taką walidację bez potrzeby tworzenia instancji walidatora.
Jednak jak już wspomniałem, działanie powyższej techniki trzeba by sprawdzić w praktyce.

## Dziedziczenie

Dziedziczenie adnotacji ograniczeń (i generalnie adnotacji używanych w J2EE) to temat nieco kontrowersyjny, ponieważ
działają one **niezgodnie z językiem Java**. Język Java mówi jasno:

  * Adnotacje **nie są** domyślnie dziedziczone.
  * Adnotacje są dziedziczone jedynie w przypadku, gdy **posiadają meta adnotację** ``@Inherited`` oraz **są zadeklarowane
na poziomie typu**.

Co to oznacza w praktyce? Nie ma możliwości dziedziczenia adnotacji nałożonych na poziomie metod, oraz potrzebujemy
meta adnotacji ``@Inherited`` aby dziedziczyć adnotacje zadeklarowane na poziomie typu. Tyle język Java. Niestety
są to ograniczenia językowe, które utrudniałyby pewne sprawy w wszelkiego rodzaju frameworkach, stąd często jest tak,
że je się po prostu ignoruje. Nie inaczej postępuje specyfikacja J2EE i trzeba sobie po prostu zdawać z tego sprawę,
a nie traktować tego jako błąd.

Wróćmy zatem do adnotacji ograniczeń. Specyfikacja Bean Validation mówi, że każda adnotacja ograniczenia zadeklarowana
na poziomie klasy czy interfejsu będzie dotyczyła klas rozszerzających albo implementujących interfejs (nie wspomina
przy tym o potrzebie użycia meta-adnotacji ``@Inherited``). Podobnie
ma się sytuacja w przypadku getterów. Adnotacje zadeklarowane na getterze będą brane pod uwagę przy walidacji wraz
z adnotacjami zadeklarowanymi w klasie potomnej, na przeciążonej wersji gettera. Przykładowo:

{% highlight java %}
@BaseConstraint
public class Base {
  @NotNull
  public String getString() { return ""; }
}

@DerivedConstraint
public class Derived extends Base {
  @Override
  @Size(max = 20)
  public String getString() { return ""; }
}
{% endhighlight %}

Metoda ``getString()`` klasy ``Derived`` będzie walidowana tak jakby posiadała ograniczenia ``@NotNull`` oraz ``@Size``,
natomiast klasa ``Derived`` tak jakby posiadała ograniczenia ``@BaseConstraint`` i ``@DerivedConstraint``.
Innymi słowy adnotacje na typach oraz getterach się kumulują.

## Podsumowanie

Wpis ten koncentrował się na drugiej sekcji specyfikacji JSR 303 a w szczególności na sposobie deklaracji adnotacji
ograniczeń. Sekcja ta opisuje także grupowanie ograniczeń oraz proces walidacji. Grupowanie pozwala nam organizować
ograniczenia w grupy, a grupy w sekwencje, dzięki czemu możemy określić kolejność wywoływania walidacji. W ten sposób
możemy na przykład walidacje stosunkowo tanie pod względem nakładu pracy uruchamiać jako pierwsze, a te które wymagają
skomplikowanych i długich obliczeń w dalszej kolejności. Jest to jednak temat trochę skomplikowany i jeszcze nie do
końca go rozumiem toteż poruszę go w kolejnym wpisie.