---
layout: post
title: Kontekstowe komponenty w J2EE 6 - ziarna, komponenty i kwalifikatory
categories: [Java EE]
tags: [java, j2ee, cdi, jsr-299, dependency injection, component, context]
description: Podstawowe zagadnienia dotyczące komponentów w specyfikacji Java EE CDI
keywords: java ee j2ee cdi jsr jsr-299 contextual components dependency injection
---
Ci którzy jej nie znają patrzą na nią z politowaniem, ci którzy jej używali nie potrafią sobie wyobrazić życia bez niej. O czym mowa? O kontekstowości komponentów. Zaczęło się od frameworka [Seam](http://seamframework.org/) (ok. może się i mylę, ale ja pierwszy raz się w tym frameworku z kontekstowością spotkałem). Zjednoczone komponenty, które żyły niezależnie od warstwy aplikacji i kontenera, który tą warstwą zarządzał jednocześnie nie tracąc nic z funkcjonalności dostarczanej przez dany kontener. Ten kto tworzył aplikację w tym frameworku powinien się zgodzić, że był to duży skok jakościowy w kontekście tego co oferuje nam standardowa (czasami aż do bólu!) Java EE. Kontekstowość komponentów tak mnie wciągnęła, że już nie wyobrażam sobie robienia żadnej aplikacji webowej w technologii Java EE bez niej. Pewnie i wiele osób ma tak jak ja, więc naturalnym było, aby te wszelkie udogodnienia wkroczyły w szeregi standardów Javy korporacyjnej. W istocie tak się stało i prace nad [JSR-299: Contexts and Dependency Injection for the Java EE platform](://jcp.org/en/jsr/detail?id=299) są już niemal skończone. Ale czy wiemy o co w tym tak naprawdę chodzi?

### Singletony i prototypy

Tradycyjne podejście do komponentów często nazywanych ziarnami (ang. bean) zostało opracowane wraz z dwiema technologiami. Technologią EJB, wywodzącą się wprost z odmętów standardów Javy korporacyjnej i frameworka Spring, który stanowić miał lekką alternatywę dla tej pierwszej technologii. Obie te technologie pozwalały na dość efektywne tworzenie aplikacji zarówno webowych jak i stand-alone. Prędzej czy później jednak (zwłaszcza w kontekście aplikacji webowych) frameworki te wymuszały na programiście implementację różnych tworów. Jedne zarządzały stanem tych komponentów, drugie zajmowały się kopiowaniem danych z jednego kontenera w drugi. A kontenerów się mnożyło wraz z kolejnymi cudownymi specyfikacjami Javy EE. Obecnie każda aplikacja webowa składa się z co najmniej kilku kontenerów, np. takich:

* Kontener serwletów
* Kontener JSF (managed beans)
* Kontener EJB/Spring (serwisy, encje, transakcje)

Każdy z tych kontenerów oferuje pewne usługi. Dobrze jest gdy sam framework potrafi odpowiednio przenosić komponenty pomiędzy kontenerami, gorzej jeżeli trzeba to robić ręcznie.

Problem ze Springiem i EJB jest taki, że frameworki te nie oferują praktycznie żadnych możliwości zarządzania długością życia komponentów. Jedyne co nam oferują to komponenty, które są tworzone za każdym razem kiedy się do nich odwołujemy (stateless, prototype) albo żyją przez całą długość trwania aplikacji (stateful, singleton). Niby to wystarczy, jednak czy nie lepiej byłoby móc dostawać takie komponenty, których cykl życia jest lepiej dopasowany do konkretnej sytuacji? Czy nie lepiej by było, aby kontener dostarczał nam komponenty niejako dopasowane na miarę przypadku użycia jaki implementujemy? Ten problem rozwiązywał właśnie Seam jak i rozwiązać ma nowa specyfikacja JSR-299.

### Ziarna i kontekstowe komponenty

Tradycyjnie instancje obiektów zarządzanych przez kontenery nazywane są ziarnami (ang. beans). Na potrzeby specyfikacji JSR-299 istnieje pewne semantyczne rozróżnienie pomiędzy ziarnem a kontekstowym komponentem. Ziarno (komponent) jest to każda klasa, która może być zarządzana przez kontener, kontekstowy komponent, zwany też <em>kontekstową instancją ziarna</em> to nic innego jak instancja komponentu stworzona i zarządzana przez kontener i umieszczona w pewnym kontekście. Tak więc ziarna traktujemy jako źródła kontekstowych komponentów, których instancje mogą być tworzone i umieszczane w różnych kontekstach przez kontener.

Kontekstowe komponenty mogą być wstrzykiwane do innych komponentów np:

{% highlight java %}
@Inject Credentials credentials;
{% endhighlight %}

Kontener jest odpowiedzialny za następujące rzeczy:

* Tworzenie i niszczenie komponentu
* Umieszczanie komponentu w odpowiednim kontekście
* Wstrzykiwanie zależności i odszukiwanie komponentu (np. wołanego przez EL)
* Obsługę cyklu życia komponentu (w tym wywoływania metod do tego cyklu należących)
* Przechwytywanie wywołań metod jak i dekorację
* Obsługę zdarzeń

Dla przeciętnego programisty EJB czy Spring część tych terminów może być obca, jednak dla programisty Seam to niemal chleb powszedni.

Każdy komponent może być niemal dowolnego typu wliczając w to: interfejsy, konkretne i abstrakcyjne klasy (także oznaczone słowem kluczowym `final`!), tablice, prymitywy (w tym wypadku instancje komponentów będą autoboxowane na odpowiadające wrappery), typy generyczne (ale z konkretnymi typami, a nie tzw. wildcardami).

### Kwalifikatory

To co mogło sprawiać wiele problemów zarówno w frameworku Seam jak i innych frameworkach to tzw. zmienne kontekstowe. Zmienne te to nic innego jak klucze, pod którymi znajdowały się nasze komponenty. Np:

{% highlight java %}@Name("credentials")
public class Credentials {
    // ciało klasy...
}{% endhighlight %}

Powyższy zapis oznacza, że komponent `Credentials` będzie dostępny pod nazwą kontekstową "credentials". Pozwalało to na identyfikowanie komponentów np. ze stron widoków. Podejście to ma jednak kilka zasadniczych wad:

* Nie jest bezpieczny na literówki
* Sprawia problemy przy refactoringu (zmiana nazwy komponentu może być pracochłonna)
* Wymaga znajomości nazw komponentów (poza nazwą samej klasy)
* Nie można nadać takiej adnotacji w miejscu gdzie nie mamy dostępu do źródła (np. jakaś biblioteka) i musimy ratować się konfigurowaniem komponentów w XML co powoduje, że część mamy definiowanych za pomocą adnotacji a część w XML

Z powyższymi problemami musimy walczyć tylko po to, aby jednoznacznie określić o jaki komponent nam chodzi a w 99% przypadków nazwy te i tak nie różniły się niczym, poza pierwszą literą, od nazw klasy! A przecież język Java już niemal od samego początku (a może i od samego ;)) posiadał doskonały sposób jednoznacznego identyfikowania obiektów, jest nim kanoniczna nazwa klasy (czyli nazwa klasy wraz z przedrostkiem pakietowym np: `java.lang.String`). Taki zapis jednoznacznie określi nam o jaki obiekt (komponent) nam chodzi! Wszyscy zaznajomieni z frameworkiem <a href="http://code.google.com/p/google-guice/">Guice</a>. Wszystko byłoby fajnie, gdyby nie jedna cecha języka Java (bynajmniej jednak nie specyficzna dla tego języka). Mianowicie chodzi o polimorfizm. Wyobraźmy sobie dla przykładu taką sytuację:

{% highlight java %}
public class LdapAuthenticator implements Authenticator {
    // logika uwierzytelniania...
}

public class JpaAuthenticator implements Authenticator {
    // logika uwierzytelniania...
}
{% endhighlight %}

Mamy dwa komponenty służące do uwierzytelniania (potocznie logowania) użytkownika. Jeden wykorzystuje protokół <a href="http://pl.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol">LDAP</a> natomiast drugi rekordy w relacyjnej bazie danych. Teraz chcąc wstrzyknąć taki komponent do innego komponentu napiszemy:

{% highlight java %}
public class AuthenticationAction {
    @Inject
    private Authenticator authenticator;
}
{% endhighlight %}

No i zasadne staje się pytanie: który zostanie wstrzyknięty? Rozwiązaniem tego problemu są właśnie kwalifikatory (o ile się nie mylę to rozwiązanie również zapożyczone zostało z frameworka Guice). Otóż to nic innego jak zwyczajne adnotacje. Kwalifikatorem może być dowolna adnotacja, która zostanie oznaczona meta-adnotacją `@Qualifier`. Meta-adnotacje to adnotacje, które są nakładane na inne adnotacje (np. `@Retention`, `@Target`). Zatem moglibyśmy stworzyć odpowiednie kwalifikatory w następujący sposób:

{% highlight java %}
@Qualifier
@Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface JPA {}
{% endhighlight %}

{% highlight java %}
@Qualifier
@Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface LDAP {}
{% endhighlight %}

Co ważne. Kwalifikator, jako adnotacja, powinien być możliwy do nałożenia na metodę, pole klasy, parametr metody albo całą klasę. Teraz mając już kwalifikatory musimy określić, która klasa komponentu będzie identyfikowana przez który kwalifikator. Wystarczy po prostu nałożyć odpowiednie kwalifikatory na odpowiednie klasy (stąd muszą być one "nakładalne" na klasę):

{% highlight java %}
@LDAP
public class LdapAuthenticator implements Authenticator {
    // logika uwierzytelniania...
}
{% endhighlight %}

{% highlight java %}
@JPA
public class JpaAuthenticator implements Authenticator {
    // logika uwierzytelniania...
}
{% endhighlight %}

Na koniec pozostało tylko określenie, który komponent ma zostać wstrzyknięty:

{% highlight java %}
public class AuthenticationAction {
    @Inject @JPA
    private Authenticator authenticator;
}
{% endhighlight %}

W tym przypadku zostanie wstrzyknięty komponent `JpaAuthenticator`, co można deklaratywnie zmienić zmieniając tylko adnotację.

Podejście to początkowo wydaje się bardziej skomplikowane, od zwykłych nazw, jednak jest ono dość proste i ma szereg zalet:

* Jest odporne na literówki.
* Środowiska IDE mogą nam z łatwością pomagać w refactoringu i wyszukiwaniu komponentów i ich użyć.
* Adnotacje mogą posiadać parametry i można je wykorzystywać do innych celów.

### Kwalifikatory standardowe

Standard JSR-299 przynosi nam kilka standardowych kwalifikatorów. Każdy komponent posiada niejawnie zadeklarowany kwalifikator `@Any` chyba, że jawnie zadeklarowano kwalifikator `@New`. Jeżeli komponent nie posiada jawnie zadeklarowanego kwalifikatora, innego niż `@Named`, to otrzymuje niejawnie kwalifikator `@Default`. Zatem mamy cztery wbudowane kwalifikatory:

* `@Default`
* `@Any`
* `@Named`, oraz
* `@New`

Kwalifikator `@Default` jest niejawnie używany wszędzie tam gdzie występuje odwołanie do komponentu. Jeżeli z pomocą tego kwalifikatora nie można jednoznacznie wyznaczyć komponentu, potrzeba jest zadeklarowanie innego, który jednoznacznie go określi. Każdy komponent może być oznaczony dowolną liczbą kwalifikatorów. I kilka przykładów:

{% highlight java %}
public class Cart {}
{% endhighlight %}

Powyżej zadeklarowany komponent otrzyma kwalifikatory: @Any oraz @Default.

{% highlight java %}
@Named("order")
public class Order {}
{% endhighlight %}

Powyższy komponent otrzyma kwalifikatory: @Any, @Default oraz @Named (z parametrem "order").

{% highlight java %}
@LDAP
public class LdapAuthenticator {}
{% endhighlight %}

Powyższy komponent otrzyma kwalifikatory: @Any oraz @LDAP.

Natomiast poniższe deklaracje są równoważne:

{% highlight java %}
public class Cart {
    @Inject
    public void checkout(PaymentProcessor paymentProcessor) {
    }
}
{% endhighlight %}

{% highlight java %}
public class Cart {
    @Inject
    public void checkout(@Default PaymentProcessor paymentProcessor) {
    }
}
{% endhighlight %}

Jak wcześniej wspomniałem, każdy komponent może mieć dowolną liczbę kwalifikatorów, podobnie miejsce wstrzyknięcia (ang. injection-point) może deklarować wiele kwalifikatorów. W tym przypadku wstrzyknięty zostanie komponent, który jest oznaczony wszystkimi kwalifikatorami zadeklarowanymi w miejscu wstrzyknięcia.

Specyfikacja JSR-299 pozwala na oznaczenie kwalifikatorem nie tylko klasy komponentu, ale i metody, która produkować będzie określone wartości. Metoda ta działać będzie jak fabryka dostarczająca zamiast komponentów to konkretnych danych. Funkcjonalność ta świetnie nadaje się do dostarczania danych na widok.

### Podsumowanie

Kontekstowe komponenty mają znaczną przewagę nad tradycyjnymi ziarnami znanymi w świecie Javy EE. Ich czas życia jest ściśle określony i zarządzany przez kontener, przez co dużo łatwiej można dopasować je do wymagań konkretnej funkcjonalności. Wymaga to nieco zmiany myślenia o komponentach, jednak daje wyraźne zyski. Kod jest czystszy, luźniej powiązany i bardziej zwięzły. Oczywiście można sprzeczać się, że wymaga to nieco więcej wiedzy od programisty, ale w końcu, każdy z nas lubi pogłębiać swoją wiedzę czyż nie?

Artykuł ten jest wstępem do pełnej analizy specyfikacji JSR-299, którą zamierzam przeprowadzić. Relacje z poszczególnych jej etapów będę tutaj umieszczał, a w międzyczasie będę tworzył aplikację w tej technologii (wykorzystując implementację <a href="http://seamframework.org/Weld">Weld</a>, która dostępna jest razem z serwerem JBoss 5.2). Mam również w planach przeanalizowanie innych specyfikacji nowej Javy korporacyjnej (w wersji 6). Zobaczymy na ile mi czas pozwoli zrealizować te plany.