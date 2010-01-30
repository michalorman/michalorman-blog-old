---
layout: post
title: Kontekstowe komponenty w J2EE 6 - komponenty produkujące
categories: [Java EE]
tags: [java, j2ee, cdi, jsr-299, dependency injection, component, context]
description: Definiowanie i zastosowanie komponentów produkujących w specyfikacji JSR-299 CDI
keywords: java ee j2ee cdi jsr jsr-299 contextual components dependency injection
---
Ten post jest niejako uzupełnieniem <a href="http://michalorman.pl/blog/2009/11/kontekstowe-komponenty-w-j2ee-6-tworzenie-inicjalizacja-i-wstrzykiwanie-komponentow/">poprzedniego</a> postu (aby poprzedni nie zrobił się czasem zbyt długi). Opisuje on nieco zaawansowanych zagadnień wymienionych w specyfikacji JSR-299.

### Komponenty produkujące

Przyznaję, nazwa jest może nie do końca trafna, ale jakoś nie potrafiłem lepszego terminu znaleźć. Teoretycznie można by użyć słowa fabrykujące, ale to mogłoby być nieco mylące. W każdym razie komponenty produkujące pozwalają nam na niejako ręczne tworzenie komponentów i umieszczanie ich w kontekście. Dlaczego chcielibyśmy takie rzeczy robić? Ano na przykład z następujących powodół:

* Obiekt, który chcemy umieścić w kontekście nie jest komponentem w rozumieniu specyfikacji JSR-299.
* Stworzenie komponentu wymaga wykonania pewnych czynności, które nie mogą być umieszczone w konstruktorze.
* Konkretny typ obiektu może się zmieniać w czasie działania aplikacji.
* Potrzebujemy konkretnych danych a nie komponentu, który nam te dane dostarczy (to bardzo przydaje się do renderowania widoku).

Tak więc kilka sytuacji, kiedy taki mechanizm nam by się przydał istnieje. Komponenty produkujące to nic innego jak zwykłe fabryki (mniej lub bardziej zgodne z wzorcem <a href="http://en.wikipedia.org/wiki/Factory_method_pattern">factory method</a>). Co ważne, w przypadku komponentów WebBeans nie potrzebujemy bezpośredniej zależności pomiędzy producentem (ang. producer) a komponentem konsumującym (ang. consumer). Komponent konsumujący to taki dziwny termin, ale oznacza on każdy komponent (czy jakiekolwiek miejsce gdzie żądamy konkretnej wartości, np. EL) który odwołuje się do wartości tworzonej przez producenta. Nie potrzebujemy ręcznie wywoływać metody produkującej. Zasada jest taka, jeżeli poszukujemy jakiejś wartości (komponentu lub nie) albo za pomocą kwalifikatorów albo za pomocą EL kontener najpierw poszuka odpowiedniego producenta tej wartości, a dopiero jak go nie znajdzie sam spróbuje stworzyć komponent.

Metoda ta świetnie nadaje się do renderowania view. Rzućmy okiem na poniższy fragment kodu:

{% highlight xml %}
<h:dataTable value="#{userFinder.loggedUsers}" var="_user">
    <!-- renderowanie kolumn -->
</h:dataTable>
{% endhighlight %}

Powyższy przykład ilustruje jak można ściśle powiązać wartę widoku z warstwą biznesową. Prawidłowe wyrenderowanie strony zależy od istnienia w pewnym kontekście komponentu userFinder, który będzie nam w stanie zwrócić listę zalogowanych użytkowników. Problem w tym, że to co my tak naprawdę potrzebujemy to listę użytkowników, a nie ważne jest dla nas jaki komponent nam ją dostarczy! W ten sposób odseparujemy nasz widok od konkretnych komponentów przez co będziemy mogli w każdej chwili zmienić komponent, który dostarczy tam dane potrzebne do wyrenderowania tabeli. Prawidłowy kod powinien wyglądać tak:

{% highlight xml %}
<h:dataTable value="#{loggedUsers}" var="_user">
    <!-- renderowanie kolumn -->
</h:dataTable>
{% endhighlight %}

W tej sytuacji potrzebujemy jedynie listy użytkowników, którą dostarczy nam dowolny komponent. Nie mamy zależności pomiędzy renderowanym widokiem a jakimś komponentem. Oczywiście nie bawimy się tutaj ręcznym wrzucaniem danych do listy atrybutów sesji, ale deklaratywnie definiujemy, który komponent będzie nam dostarczał wymagane dane a samym dostarczeniem zajmie się kontener.

Aby zadeklarować miejsce, w którym produkujemy dane używamy adnotacji `@javax.enterprise.inject.Produces`. Specyfikacja WebBeans pozwala nam na nałożenie tej adnotacji na metodę lub na pole klasy.

### Metody produkujące

Metodami produkującymi nazywamy wszelkie metody oznaczone adnotacją `@Produces`

Metoda produkująca może zwracać wartość `null`, jednak w tym przypadku wymagane jest aby zakres zwracanej był `@Dependent` (o zakresach będzie w którymś z przyszłych postów).

Jeżeli metoda zwraca wartość generyczną, deklaracja musi określać konkretną wartość (nie możemy użyć tzw. wildcardów). Kontener zwróci nam błąd jeżeli nie spełnimy tego warunku.

Metody produkujące można wywoływać bezpośrednio, jednak w tym przypadku wartość zwrócona przez nie nie zostanie umieszczona w żadnym kontekście. Podobnie kontener nie wstrzyknie nam żadnych zależności, będzie to zwyczajne wywołanie metody. Jeżeli chcemy aby rezultat wywołania metody był umieszczony w kontekście musi zostać ona wywołana przez kontener (czyli de facto zdelegowany przez jakiś interceptor).

Deklaracja takiej metody wygląda następująco:

{% highlight java %}
public class UserFinder {
    @Produces
    public List<User> getLoggedUsers() {
        // pobieranie danych...
    }
}
{% endhighlight %}

Oczywiście powyższa deklaracja umieści nam listę użytkowników w domyślnym kontekście i pod domyślną nazwą, ale jeżeli chcemy to zmienić to jak najbardziej możemy to zrobić:

{% highlight java %}
public class UserFinder {
    @Produces
    @ConversationScoped
    @Members
    @Named("loggedUsers")
    public List<User> getLoggedUsers() {
        // pobieranie danych...
    }
}
{% endhighlight %}

Powyższy przykład umieści nam dane w kontekście konwersacji a identyfikowane będą za pomocą kwalifikatora `@Members` a także pod nazwą "loggedUsers".

Metody produkujące mogą mieć dowolną liczbę parametrów. Każdy parametr takiej metody jest automatycznie miejscem wstrzyknięcia:

{% highlight java %}
public class UserProfileFactory {
    @Produces
    @ConversationScoped
    public Profile createUserProfile(@Selected User user) {
        return user.getProfile();
    }
}
{% endhighlight %}

W ten sposób możemy definiować ciąg wywołań metod produkujących, które dostarczą nam dane potrzebne do wyrenderowania widoku. Trzeba jednak uważać, aby nie stało się to zbyt skomplikowane i w efekcie nie generowało zbyt dużej ilości zapytań do bazy danych, jak zawsze w takich przypadkach trzeba kierować się zdrowym rozsądkiem.

A co jeśli chcemy, aby kontener wszystkie wywołania jednej metody produkującej zastąpił drugą? Tutaj z pomocą przychodzi znana nam adnotacja `@Specializes`, jednak metoda taka musi spełniać następujące warunki:

* Przeciążać (ang. override) wersję którą chcemy zastąpić.
* Być nie statyczną (podobnie jak metoda, którą chcemy zastąpić).

Z powyższych punktów wynika, że nasz komponent z metodą zastępującą musi dziedziczyć po komponencie, w którym metodę chcemy zastąpić (aby móc nadpisać metodę). Niestety specyfikacja nie zabrania użycia słowa kluczowego `final`, ale oczywistym jest, że metoda oznaczona tym modyfikatorem nie może zostać podmieniona. Podobnież specyfikacja nie mówi nic o modyfikatorach dostępu, ale domyślać się można, że metody te powinny być publiczne (specyfikacja mówi tylko, że w przypadku komponentów sesyjnych - EJB - metoda musi być metodą biznesową w myśl tej specyfikacji). Oto przykład nadpisania metody produkującej:

{% highlight java %}
@Mock
public class MockUserFinder extends UserFinder {
    @Overrides
    @Produces
    @Specializes
    public List<User> getLoggedUsers() {
        // pobieranie danych...
    }
}
{% endhighlight %}

Powyższy przykład pokazuje także, jak łatwo można stworzyć sztuczne dane na potrzeby testów.

Domyślna nazwa nadawana metodzie produkującej to nazwa tej metody, chyba że metoda stosuje się do konwencji <a href="http://pl.wikipedia.org/wiki/JavaBeans">JavaBeans</a> w takim przypadku domyślną nazwą jest nazwa pola wskazywanego przez metodę. Np:

{% highlight java %}
@Produces @Named
public List<User> getLoggedUsers() {}
{% endhighlight %}

W tym wypadku domyślną nazwą będzie `loggedUsers`, natomiast w następującym:

{% highlight java %}
@Produces @Named
public EntityManager entityManager() {}
{% endhighlight %}

będzie `entityManager`.

#### Zwalnianie zasobów

Jak wspomniałem metody produkujące mogą być wywoływane, jeżeli tworzenie komponentu wymaga czynności, które nie mogą zostać użyte w konstruktorze. Jednakże w czasie konstruowania obiektu mogą zostać zarezerwowane zasoby, które należy ręcznie zwalniać w momencie usuwania komponentu. W przypadku regularnych komponentów tworzonych przez kontener mamy możliwość określenia metod, które mają zostać wywołane w czasie stworzenia komponentu jak i w czasie jego usuwania (o tym szerzej w którymś z przyszłych postów). W przypadku metod produkujących nie mamy jednak do czynienia z komponentami tworzonymi przez kontener, ale tworzone są przez aplikacje, a potem w gotowej, niejako surowej formie, są umieszczane przez kontener w zadeklarowanym (albo domyślnym) kontekście. Jak zatem w takim przypadku powiedzieć kontenerowi, że należy wywołać jakąś metodę, która zwolni zasoby? Teoretycznie można by wykorzystać ten sam sposób jak przy regularnych komponentach (teoretycznie kontener mógłby je traktować tak samo), problem w tym, że dane tworzone przez metody produkujące w cale nie muszą być komponentami! To mogą być zwykłe porcje danych, które jednak nie są komponentami (w myśl specyfikacji WebBeans). Co w takim przypadku? Należy użyć adnotacji `@javax.enterprise.inject.Disposes`.

Za pomocą adnotacji @Disposes możemy określić jaka metoda ma zostać wywołana podczas usuwania danych stworzonych przez konkretną metodę produkującą. Adnotacji tej należy użyć na parametrze, którego typ odpowiada typowi zwracanemu przez metodę produkującą a także kwalifikatorom. Parametr oznaczony tą adnotacją jest parametrem likwidowanym i tylko jeden taki parametr może istnieć na liście parametrów metody zwalniającej (jakoś brakuje mi sensownego odpowiednika dla disposer method). Przykładowo poniższa metoda służy do zwalniania zasobów (i robienia wszelkich innych akcji "czyszczących") zarezerwowanych w czasie produkowania listy zalogowanych użytkowników:

{% highlight java %}
public class UserFinder {
    @Produces
    public List<User> getLoggedUsers() {
        // pobieranie danych...
    }

    public void clearLoggedUsers(@Disposes List<User> loggedUsers) {
        // zwalnianie zasobów...
    }
}
{% endhighlight %}

Metoda zwalniająca musi znajdować się w tym samym komponencie co metoda produkująca. Jedna metoda zwalniająca, może być przypisana do tylko jednej metody produkującej i jedna metoda produkująca może mieć tylko jedną metodę zwalniającą.

### Pola produkujące

Inną formą zadeklarowania wartości, która ma zostać umieszczona w kontekście są pola. Pole produkujące deklaruje się podobnie jak metody, za pomocą adnotacji `@Produces` pole to musi należeć do komponentu i może być statyczne lub nie, jednak w przypadku komponentów sesyjnych (komponentów EJB) pole musi być statyczne! Sposób inicjalizacji pola jest zasadniczo dowolny, jednakże jeżeli dopuszczamy, żeby pole mogło mieć wartość `null` musimy zadeklarować kontekst `@Dependent`, podobnie musimy w przypadku gdy pole jest typu generycznego z konkretnym typem (nie można użyć typu nieokreślonego - wildcard). Każdy komponent może deklarować wiele pól produkujących.

Pole produkujące może być niemal dowolnego typu, interfejs, klasa, zmienna prymitywna, zakres (ang. array), generyczna z konkretnym typem. Specyfikacja nie mówi nic o modyfikatorach dostępu jak i użyciu słowa kluczowego `final`.

Jak już napisałem pole produkujące deklarujemy podobnie jak metodę:

{% highlight java %}
public class LoggedUsersFinder {
    @Produces
    private List<User> loggedUsers;
}
{% endhighlight %}

Możemy też użyć kwalifikatorów, zadeklarować zakres jak i nadać nazwę:

{% highlight java %}
public class LoggedUsersFinder {
    @Produces
    @ConversationScoped
    @Named
    @Members
    private List<User> loggedUsers;
}
{% endhighlight %}

Domyślna nazwa jest zawsze nazwą pola, czyli w powyższym przypadku `loggedUsers`. Pól produkujących nie możemy specjalizować a także specyfikacja nie definiuje sposobu wywoływania metod czyszczących ten mechanizm można użyć tylko wobec metod produkujących, przynajmniej tak mówi specyfikacja, a jest to dla mnie trochę dziwne. Być może autorzy specyfikacji doszli do wniosku, że nie ma po co niepotrzebnie komplikować specyfikację, jak ktoś potrzebuje zwalniać zasoby to zdefiniuje sobie metodę produkującą zamiast pola.

Jeszcze taka mała dygresja co do pól i metod produkujących. Autorzy specyfikacji doszli do wniosku, że nie ma sensu dodawać do specyfikacji znaną z Seama adnotację `@Out`. Autorzy specyfikacji stwierdzają, że adnotacja ta zbytnio <a href="http://seamframework.org/Community/SomeKindOfOutjection">komplikowała aplikacje</a> a nie przynosiła pożytku. Moim zdaniem nie jest to dobre posunięcie. Owszem, ja również początkowo byłem bardzo niechętny tzw. outjection gdyż widziałem w tym potencjalne źródło problemów, jako że łatwo można było stracić kontrolę nad komponentami umieszczanymi w kontekstach. Jednakże było kilka zastosowań, gdzie outjection było całkiem pomocne (a metody produkujące nieco sztucznie będą to symulować). Problem tutaj nie leży w samej adnotacji `@Out` a jedynie w programistach, źle korzystających (albo nadto korzystających) z tego mechanizmu (to tak jak zabronić produkcji noży, bo są używane przez zabójców). Dodatkowo na tym etapie analizy specyfikacji WebBeans nie wiem czy adnotacja `@Produces` bardziej zachowuje się jak adnotacja `@Factory` czy `@Unwrap` z Seama. Podejrzewam, że ta pierwsza, jednak nie spotkałem jeszcze w specyfikacji potwierdzenia moich przypuszczeń.

### Podsumowanie

Komponenty produkujące, czy to za pomocą metod czy pól, mogą nam świetnie służyć do dostarczania konkretnych danych na widok czy do innych komponentów, redukując tym samym zależności w projekcie. Często jest tak, że potrzebujemy konkretnych danych a nie komponentu, który nam je dostarcza i ten mechanizm właśnie nam na to pozwala. Wszystko robione przez kontener i poszczególne warstwy czy komponenty nawet nie wiedzą kto im dostarcza dane (bo po co ma ich to obchodzić?). Jest to tylko jeden z wielu mechanizmów specyfikacji JSR-299 pozwalających na rozluźnianie powiązań pomiędzy poszczególnymi komponentami.

Specyfikacja dostarcza nam wszelkich potrzebnych mechanizmów do tworzenia danych jak i dokonywania niezbędnych czynności czyszczących w momencie jak kontener będzie usuwał dane przez nas wyprodukowane. Co ważne, dane te nie muszą być komponentami WebBeans, mogą to być dowolne dane, które kontener umieści nam w kontekście i będzie nam wstrzykiwał je na żądanie, jednakże pola i metody produkujące muszą znajdować się w komponentach.