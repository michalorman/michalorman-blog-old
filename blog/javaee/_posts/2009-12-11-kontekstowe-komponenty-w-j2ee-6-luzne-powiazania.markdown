---
layout: post
title: Kontekstowe komponenty w J2EE 6 - Luźne powiązania
description: W jaki sposób specyfikacja CDI rozluźnia powiązania w aplikacjach, czyli dekoratory, eventy i interceptory w specyfikacji CDI.
keywords: Luźne powiązania loose coupling WebBeans CDI JSR-299 decorator event interceptor
---
Zasadniczo generalne koncepcje specyfikacji JSR-299 mamy już za sobą. Jednakże specyfikacja ta definiuje także kilka ciekawych elementów pozwalających na rozluźnianie powiązań w naszej aplikacji. Jeden taki mechanizm już poznaliśmy, były to metody produkujące (oznaczone adnotacją `@Produces`). Metody te służą do produkowania konkretnych danych, czyli na widoku albo w innym komponencie zamiast zależności do komponentu, który dostarczy nam dane mamy zależność do samych danych, a dostarczeniem ich zajmie się kontener. Niby funkcjonalnie to samo, ale jest to dużo bardziej elastyczne na zmiany dostawcy danych (inaczej musielibyśmy stworzyć jakiś odpowiedni interfejs).

W tym wpisie zrobię przegląd innych mechanizmów specyfikacji pozwalających na poluźnianie napięć w aplikacjach.

### Komponenty przechwytujące

Komponenty przechwytujące dalej zwane interceptorami to komponenty pozwalające na dodawanie logiki przed i po wywołaniu metody innego komponentu. Pozwala to na implementacje logiki przecinającej (ang. cross-cutting) znanej z <a href="http://en.wikipedia.org/wiki/Aspect-oriented_programming">programowania aspektowego</a>.

Zasadniczo funkcjonalność ta istnieje już od jakiegoś czasu w świecie J2EE. Jednak cierpi ona na kilka problemów:


* Ściśle wiąże komponenty z interceptorami - musimy jawnie deklarować klasy interceptorów w adnotacji `@Interceptors`.
* Nie ma możliwości deklaratywnego włączania i wyłączania interceptorów w zależności od środowiska uruchomieniowego.
* Nie ma możliwości sterowania kolejnością wywoływania interceptorów.
* Brak wstrzykiwania zależności.


Jak zapewne się domyślacie, specyfikacja JSR-299 miała na celu poprawienie tych problemów. Zobaczmy zatem co nam ona oferuje.

#### Wiązania interceptorów

Ponieważ jesteśmy we wpisie dotyczącym luźnych powiązań, to od razu wiadomo, że specyfikacja JSR-299 postanowiła rozluźnić te wiązania i uczynić je bardziej deklaratywnymi. Aby powiązać interceptory i komponenty musimy utworzyć wiązanie interceptora przy użyciu meta adnotacji `@javax.interceptor.InterceptorBinding`:

{% highlight java %}
@InterceptorBinding
@Target({TYPE, METHOD})
@Retention(RUNTIME)
public @interface Secure {
}
{% endhighlight %}

Mając adnotację do wiązania interceptora możemy użyć jej w klasie. Mamy dwie możliwości, użyć jej adnotując klasę:

{% highlight java %}
@Secure
public class Cart {
    public void checkout() {
        //...
    }
}
{% endhighlight %}

albo metodę:

{% highlight java %}
public class Cart {
    @Secure
    public void checkout() {
        //...
    }
}
{% endhighlight %}

stąd deklaracja adnotacji wiązania ma w swojej deklaracji `@Target({TYPE, METHOD})`. Jeżeli adnotacja jest nałożona na klasę to wszystkie metody biznesowe będą przechwytywane przez interceptor, w drugim przypadku tylko wywołania metody `checkout`.

No dobra, ale brakuje nam interceptora.

#### Typy i tworzenie komponentów przechwytujących

Specyfikacja CDI określa następujące typy interceptorów:

* interceptory metod biznesowych (ang. business method interceptors),
* interceptory metod cyklu życia (ang. lifecycle callback interceptors), oraz
* interceptory zdarzeń czasowych EJB (ang. timeout method interceptors).


Interceptory biznesowe dotyczą wywołań metod biznesowych, deklarowane są tradycyjną adnotacją `@AroundInvoke`. W przypadku interceptorów metod cyklu życia używamy adnotacji takich samych jak na tych metodach (np. `@PostConstruct`), natomiast w przypadku zdarzeń czasowych adnotacji `@AroundTimeout`. Ja skupię się tylko na tym pierwszym rodzaju interceptorów.

Zatem, mój interceptor wyglądałby tak:

{% highlight java %}
@Secure
@Interceptor
public class SecurityInterceptor {
    @AroundInvoke
    public Object handleInterception(InvocationContext context) throws Exception {
        // jakieś operacje
        return context.proceed()
    }
}
{% endhighlight %}

Uwaga na adnotacje na klasie interceptora, to jest adnotacja `@javax.interceptor.Interceptor` a nie `@javax.Interceptors` reszta to zasadniczo taka sama logika jak zawsze przy tworzeniu interceptora. Interceptory mogą posiadać zadeklarowane zależności które będą wstrzykiwane przez kontener. Co ważne na nasz interceptor musimy nałożyć adnotację wiążącą, taką samą jak na komponencie do którego odwołania chcemy przechwytywać. Specyfikacja pozwala na zadeklarowanie wielu adnotacji wiążących na interceptorze, w takim przypadku interceptor będzie przechwytywał odwołania do metod oznaczonych wszystkimi adnotacjami jak na interceptorze (adnotacje wiążące zachowują się podobnie jak stereotypy identyfikujące komponenty do wstrzyknięcia). To się robi trochę zagmatwane w kontekście tego, że adnotacje mogą być nałożone na metody i typy. Przykładowo mamy taki interceptor:

{% highlight java %}
@Transactional @Secure @Interceptor
public class TransactionalSecurityInterceptor {
    // ciało interceptora...
}
{% endhighlight %}

będzie on przechwytywał wywołania wszystkich metod biznesowych następującej klasy:

{% highlight java %}
@Transactional @Secure
public class Cart {
}
{% endhighlight %}

jednakże w tym przypadku:

{% highlight java %}
@Transactional
public class Cart {
    public void addToCart(Product product) {
        // ...
    }

    @Secure
    public void checkout() {
         // ...
    }
}
{% endhighlight %}

tylko odwołania do metody `checkout` (pozostałe metody będą przechwytywane przez interceptor deklarujący tylko adnotację wiązania `@Transactional`) podobnie jak w poniższym przypadku:

{% highlight java %}
public class Cart {
    public void addToCart(Product product) {
        // ...
    }

    @Transactional @Secure
    public void checkout() {
         // ...
    }
}
{% endhighlight %}

System jest prosty, interceptor przechwytuje odwołania do metod które deklarują takie same adnotacje wiązania jak on sam.

#### Aktywacja komponentów przechwytujących

Napisałem wcześniej, że specyfikacja CDI pozwala na aktywację i dezaktywację interceptorów zależnie od środowiska uruchomieniowego oraz określanie kolejności wywołań. Robi się to podobnie jak w przypadku komponentów alternatywnych w deskryptorze `beans.xml`. Domyślnie interceptory są dezaktywowane, chyba że jawnie je aktywujemy:

{% highlight xml %}
<beans xmlns="http://java.sun.com/xml/ns/javaee"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://java.sun.com/xml/ns/javaee  http://java.sun.com/xml/ns/javaee/beans_1_0.xsd">
   
   <interceptors>
      <class>pl.michalorman.SecurityInterceptor</class>
      <class>pl.michalorman.TransactionInterceptor</class>
   </interceptors>
</beans>
{% endhighlight %}

Tylko interceptory zadeklarowane w deskryptorze `beans.xml` są aktywne, do tego uruchamiane są w takiej kolejności w jakiej są zadeklarowane w sekcji `&lt;interceptors&gt;`. Im wcześniej zadeklarowany tym wcześniej się uruchamia.

Interceptory w ten sposób zadeklarowane uruchamiają się po interceptorach zadeklarowanych przy użyciu adnotacji `@Interceptors` i zadeklarowanych w deskryptorze `ejb-jar.xml` w przypadku komponentów XML (a przed dekoratorami omówionymi później).

#### Interceptory z parametrami

Adnotacje w Javie mogą mieć pola (tudzież metody a ściślej to członki ;)). Specyfikacja JSR-299 traktuje je podobnie jak w przypadku stereotypów, czyli uwzględnia podczas łączenia interceptora z komponentami. Na przykład do naszej adnotacji wiążącej możemy dodać pole `rolesAllowed` pozwalający zdefiniować role w jakich ma się znajdować zalogowany użytkownik podczas wywołania jakiejś metody. Definicja adnotacji wiążącej wyglądałaby tak:

{% highlight java %}
@InterceptorBinding
@Target({TYPE, METHOD})
@Retention(RUNTIME)
public @interface Secure {
    String[] rolesAllowed;
}
{% endhighlight %}

Teraz należałoby zaktualizować nasz interceptor:

{% highlight java %}
@Secure(rolesAllowed="Admin")
@Interceptor
public class SecurityInterceptor {
    // ...
}
{% endhighlight %}

Interceptor ten będzie przechwytywał wszelkie odwołania do klas, które deklarują adnotację wiążącą `@Secure` z parametrem `rolesAllowed` ustawionym na `"Admin` jak poniżej:

{% highlight java %}
@Secure(rolesAllowed="Admin")
public class Cart {
}
{% endhighlight %}

Nie zawsze jednak takie sztywne przypisanie ma sens, a na pewno nie w powyższym przykładzie. Nie chcemy wymuszać wywołania naszego interceptora dla konkretnych ról, a już na pewno nie tylko dla roli administratora. Jeżeli chcemy przekazać kontenerowi, aby nie uwzględniał pola w procesie wiązania oznaczamy go adnotacją `@Nonbinding` jak poniżej:

{% highlight java %}
@InterceptorBinding
@Target({TYPE, METHOD})
@Retention(RUNTIME)
public @interface Secure {
    @Nonbinding String[] rolesAllowed default {};
}
{% endhighlight %}

W tej sytuacji kontener nie uwzględnia parametru `rolesAllowed` podczas wiązania, a interceptor może go wykorzystywać do implementowania swojej logiki (w zależności od tego czy jest podany czy ma wartość domyślną).

### Dekoratory
Interceptory to świetny mechanizm pozwalający wykonywać jakąś logikę przed i po wywołaniu metody biznesowej konkretnego komponentu. Świetnie nadają się do implementacji <a href="http://en.wikipedia.org/wiki/Aspect-oriented_programming">AOP</a>. Jednakże w wielu przypadkach ich ogólność może być wadą. Interceptory nie są świadome szerszego kontekstu - interfejsu - komponentu do którego odwołanie przechwytują. Dekoratory można rozumieć jako takie interceptory, ale świadome kontekstu komponentu do którego odwołania będą przechwytywać i dekorować. Nie należy jednak rozumieć tego w taki sposób, że dekoratory to ulepszone interceptory. Co to to nie! Każde z nich ma swoje miejsce i zadania. Interceptorów będziemy używać w bardziej ogólnym kontekście, a dekoratorów wtedy jak będziemy chcieli udekorować wywołania do konkretnego komponentu.

Zatem czym są dekoratory? Dla tych, którzy nie znają <a href="http://en.wikipedia.org/wiki/Decorator_pattern">wzorca projektowego dekorator</a> polecam najpierw zapoznanie się z nim. To co daje nam specyfikacja to dokładnie implementacja tego wzorca z tym, że wspierana przez kontener :). Za pomocą kilku adnotacji możemy udekorować nasz komponent dodatkową logiką. Ponieważ dekoratory dekorują konkretne komponenty doskonale znają jego interfejs ba, porządne dekoratory powinny mieć ten sam interfejs, jednakże w naszym przypadku dekorator może być klasą abstrakcyjną i nie musi implementować wszystkich metod wspólnego interfejsu. Brzmi to dość dziwnie, ale zobaczmy jak to wygląda w praktyce.

Załóżmy, że posiadamy następujący interfejs:

{% highlight java %}
public interface Account {
    public void deposit(BigDecimal amount);
    public void withdraw(BigDecimal amount);
}
{% endhighlight %}

Teraz chcielibyśmy, logować każdą wpłatę na konto powyżej jakiejś kwoty, oczywiście zakładając, że aktualnie system tego nie robi. Moglibyśmy zmienić implementację komponentu który implementuje ten interfejs, jednakże nie moglibyśmy konfigurować tego zachowania w zależności od środowiska uruchomieniowego (np. w jednym kraju moglibyśmy chcieć tę funkcjonalność wyłączyć). Oczywiście moglibyśmy stworzyć odpowiednie alternatywy i zasadniczo rozwiązanie byłoby dobre, jednak wtedy musielibyśmy implementować pełny interfejs i logikę, którą już zasadniczo mamy zaimplementowaną. Specyfikacja JSR-299 daje nam lepszy sposób rozwiązania tego problemu, właśnie dzięki wspomnianym dekoratorom. Oto jakby mógł wyglądać nasz dekorator:

{% highlight java %}
@Decorator
public abstract class LoggableAccountTransactionDecorator implements Account {
     @Decorates @Any
     private Account account;

     public void deposit(BigDecimal amount) {
         // logika logowania ...
         account.deposit(amount);
     }
}
{% endhighlight %}

Aby określić komponent jako dekorator używamy stereotypu `@javax.decorator.Decorator`. Co warto zauważyć, dekorator może być klasą abstrakcyjną, dzięki czemu nie musimy implementować wszystkich metod wspólnego interfejsu. Kolejną rzeczą jaką musimy zdefiniować to komponent który dekorujemy, co w nomenklaturze specyfikacji nazywa się **miejscem wstrzyknięcia delegatu** (ang. delegate injection point). Miejsce to jest dokładnie takim samym miejscem wstrzyknięcia jak każde inne w innych komponentach z tą różnicą, że dodatkowo posiada adnotację `@javax.decorator.Decorates`. Dzięki tej adnotacji kontener wie, że ma dekorować odwołania do danego komponentu. Dekorator może deklarować tylko jeden taki komponent, ale może posiadać dowolną ilość zależności (miejsc wstrzyknięcia). Obiektem dekorowanym będzie każdy obiekt, który może zostać wstrzyknięty w danym miejscu wstrzyknięcia, zgodnie z zasadami opisanymi we wpisie o <a href="http://michalorman.pl/blog/2009/11/kontekstowe-komponenty-w-j2ee-6-wstrzykiwanie-zaleznosci/">wstrzykiwaniu zależności</a>.

Teraz mając już zadeklarowany dekorator i obiekt(y) który(e) dekorujemy musimy określić jakie metody chcemy dekorować (bo przecież nie musimy dekorować wszystkich odwołań do komponentu). Zasadniczo nie trzeba nic robić, tylko zaimplementować stosowną dekorację ;). W powyższym przykładzie zaimplementowana została tylko metoda `deposit` interfejsu `Account` i tylko wywołania tej metody na komponencie dekorowanym przejdą przez dekorator. Dzięki temu nie musimy implementować delegacji na wszystkie pozostałe metody (tak byśmy musieli zrobić w przypadku obiektu alternatywnego). Co jeszcze ciekawe, w metodzie dekorującej wcale nie musimy odwoływać się do metody dekorowanej! Możemy wywołać dowolne inne metody komponentu dekorowanego albo nie wywołać żadnej. Nie różni się to niczym jakbyśmy po prostu pisali bardziej specyficzną metodę `deposit`. To jest też różnica między dekoratorami a interceptorami, w których za pomocą `InvocationContext.proceed()` wywołalibyśmy tylko metodę do której odwołanie przechwyciliśmy. W przypadku dekoratorów możemy wywołać dowolną metodę. Jeżeli metoda wywołana przez dekorator jest także dekorowana, to zostanie wywołany stosowny inny, bądź ten sam, dekorator.

Co warto jeszcze wspomnieć to to, że interceptory są wywoływane przed dekoratorami. Także jak mamy jakieś interceptory tworzące i zamykające transakcje, czy zajmujące się security to dekoratory będą już działać w odpowiednio zainicjalizowanym kontekście.

Pozostała jeszcze jedna rzecz, o której jak dotąd nie wspomniałem. W kodzie naszej aplikacji możemy mieć wiele dekoratorów a także możemy chcieć niektóre wyłączać w danym środowisku uruchomieniowym. Zasadniczo sytuacja jest podobna jak z interceptorami, jeżeli nie zadeklarujemy dekoratora w pliku `beans.xml` dekorator będzie nieaktywny. Tak więc jeżeli chcemy udekorować nasze komponenty musimy dodać stosowny wpis w deskryptorze w sekcji `&lt;decorators&gt;`:

{% highlight xml %}
<beans xmlns="http://java.sun.com/xml/ns/javaee"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/beans_1_0.xsd">

   <decorators>
          <class>pl.michalorman.LoggableAccountTransactionDecorator</class>
   </decorators>

</beans>
{% endhighlight %}

Sekcja `&lt;decorators&gt;` może zawierać zdefiniowanych wiele dekoratorów. Są one przetwarzane zgodnie z kolejnością deklaracji w deskryptorze. Ten dekorator który został zadeklarowany najwcześniej uruchamia się jako pierwszy.

### Zdarzenia

Zdarzenia to bodaj najciekawsza funkcjonalność, specyfikacji WebBeans, pozwalająca na redukowanie zależności pomiędzy komponentami. Jest to nieco ulepszona implementacja wzorca projektowego <a href="http://pl.wikipedia.org/wiki/Obserwator_(wzorzec_projektowy)">obserwator</a>, z tym, że wspierana przez kontener i deklaratywna (deklarowana a jakże, ze pomocą adnotacji ;)).

Zdarzenia możemy utożsamiać z pewnego rodzaju szyną danych. Jeden komponent umieszcza dane o zdarzeniu w szynie a wszystkie komponenty, które zadeklarowały chęć otrzymywania informacji o danym zdarzeniu są przez kontener powiadamiane. Daje nam to kompletne rozdzielenie komponentów produkujących zdarzenia jak i je obserwujących. Rozdzielenie to jest posunięte do tego stopnia, że komponenty produkująco-obserwujące mogą należeć do zupełnie innych warstw. Idea jest prosta, przejdźmy zatem do praktyki.

Zdarzenie reprezentowane jest przez dowolną, niegeneryczną instancję klasy języka Java. Klasy te mogą być oznaczone kwalifikatorami (tymi samymi jakie używamy do identyfikacji komponentu do wstrzyknięcia). Kwalifikatory pozwalają obserwatorom oddzielać różne zdarzenia tego samego typu (tej samej klasy). Można by powiedzieć, że są to tematy zdarzenia do wyboru przez obserwatorów. Oto przykład takiego kwalifikatora:

{% highlight java %}
@Qualifier
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
public @interface Saved {
}
{% endhighlight %}

#### Deklarowanie obserwatora

W specyfikacji CDI nie deklaruje się samego obserwatora, a raczej metody obserwujące czyli metody, które mają zostać wywołane podczas wygenerowania zdarzenia konkretnego typu. Aby zadeklarować taką metodę używamy adnotacji `@javax.enterprise.event.Observes`:

{% highlight java %}
public void onDocumentEvent(@Observes Document document) {
    // ...
}
{% endhighlight %}

Powyższa metoda zadziała na każde zdarzenie wygenerowane dla typu zdarzenia `Document`, jednakże za pomocą kwalifikatora możemy uściślić o jakie zdarzenie nam chodzi:

{% highlight java %}
public void onDocumentSaved(@Observes @Saved Document document) {
    // ...
}
{% endhighlight %}

W tym przypadku metoda obserwująca zostanie wywołana w przypadku zapisania dokumentu. Parametr `document` jest nazywany parametrem zdarzenia (ang. event parameter). Metoda obserwująca może deklarować tylko jeden parametr zdarzenia i dowolną ilość innych parametrów. Pozostałe parametry stają się automatycznie miejscami wstrzyknięcia (tak, obserwatorzy mogą mieć zależności, które są wstrzykiwane przez kontener, są to normalne komponenty!). Typ parametru zdarzenia jest to typ zdarzenia (ang. event type) i określa on typ klasy, która reprezentuje zdarzenie, które chcemy obserwować.

#### Generowanie zdarzenia
Wiemy już jak łapać zdarzenia, teraz dowiemy się jak je generować. Aby tego dokonać komponent musi wstrzyknąć sobie komponent o typie `javax.enterprise.event.Event`, który jest wbudowanym komponentem dostarczanym przez kontener i służy do generowania zdarzeń. Typ ten jest typem parametryzowanym (generycznym), a typ parametru określa typ zdarzenia jakie chcemy wygenerować. Oto jak wygląda deklaracja:

{% highlight java %}
@Inject
private Event<Document> documentEvent;
{% endhighlight %}

Każda taka zależność ma niejawnie dodawany kwalifikator `@Any` (nawet jeżeli deklaruje inne kwalifikatory), oznacza to, że dane zdarzenie będzie obserwowane przez każdą metodę która nie deklaruje kwalifikatorów w parametrze zdarzenia. Jednakże jeżeli chcielibyśmy uściślić nasze zdarzenie (nadać mu temat), możemy do deklaracji dorzucić kwalifkiator:

{% highlight java %}
@Inject @Saved
private Event<Document> documentEvent;
{% endhighlight %}

Pamiętajmy jednak, każda metoda obserwująca zdarzenia danego typu, która nie deklaruje żadnych kwalifikatorów parametru zdarzenia (innych adnotacji niż `@Observes`) zawsze zostanie poinformowana o zdarzeniu, a deklarująca kwalifikator tylko wtedy jak deklaruje kwalifikator odpowiedniego typu (`@Saved` w tym przypadku). Pamiętajmy także, że kwalifikatory (adnotacje) mogą posiadać pola i o ile nie są one oznaczone adnotacją `@Nonbinding` wartości te są uwzględniane przy kwalifikowaniu metod obserwujących (jest to czynione automatycznie przez kontener).

Teraz jak mamy już wstrzyknięty komponent `Event` możemy wygenerować zdarzenie za pomocą metody `fire`:

{% highlight java %}
documentEvent.fire(document);
{% endhighlight %}

Jako parametr przekazujemy obiekt o typie zdarzenia który pełni rolę ładunku (ang. payload) naszego zdarzenia. Obiekt ten jest następnie wykorzystywany przez metody obserwujące wywołane w odpowiedzi na wygenerowane zdarzenie.

Powyższy przykład ma jedną wadę, które w niektórych przypadkach może przeszkadzać. Mianowicie, co jeżeli jakiś komponent chce generować zdarzenia, jednak każdemu przypisując inne kwalifikatory? Specyfikacja CDI rozwiązuje nam ten problem pozwalając dodawać kwalifikatory w czasie wykonania za pomocą metody `select`. Metoda ta tworzy potomny obiekt generujący zdarzenie, który posiada te same kwalifikatory co przodek i dodatkowe przekazane jako parametry w wywołaniu metody `select`:

{% highlight java %}
documentEvent.select(new Updated()).fire(document);
{% endhighlight %}

Wywołanie to utworzy potomny komponent typu `Event` który będzie posiadał kwalifikatory przodka czyli `Saved` oraz dodatkowy `Updated`.

Jest tutaj subtelna różnica w porównaniu z wstrzykiwaniem zależności, w przypadku gdy mamy wiele kwalifikatorów. W przypadku wstrzykiwania zależności mieliśmy tak, że wstrzykiwany był ten komponent, który miał odpowiedni wymagany typ i deklarował wszystkie kwalifikatory jakie były zadeklarowane w miejscu wstrzyknięcia. W przypadku zdarzeń jest jednak inaczej. Jeżeli komponent generujący zdarzenie deklaruje wiele kwalifikatorów (czy to za pomocą adnotacji czy w metodzie `select`) zostaną odpalone wszystkie metody obserwujące zdarzenia danego typu które albo nie deklarują żadnych kwalifikatorów albo deklarują co najmniej jeden z zadeklarowanych w miejscu wstrzyknięcia komponentu generującego zdarzenia.

#### Warunkowe wywołanie metod obserwujących
Adnotacja `@Observes` posiada kilka parametrów (dokładnie dwa), a jeden z nich służy do zadeklarowania warunkowego wywołania metody obserwującej. Specyfikacja pozwala nam w zasadzie tylko na sprawdzenie jednego warunku, mianowicie wywołania metody obserwującej tylko wtedy, gdy komponent deklarujący metodę obserwującą istnieje w kontekście (w przeciwnym razie kontener stworzyłby ten komponent). Aby tego dokonać ustawiamy parametr `reveive` (według specyfikacji to `receive` jednak według dokumentacji <a href="http://java.sun.com/javaee/6/docs/api/javax/enterprise/event/Observes.html#notifyObserver()">javadoc</a> to parametr `notifyObserver` - obstawiam, że to dokumentacja javadoc jest nieaktualna ;)) na wartość `Reception.IF_EXISTS` enumeracji `javax.enterprise.event.Reception`:

{% highlight java %}
public void onDocumentSaved(@Observes(receive = IF_EXISTS) @Saved Document document) {
    // ...
}
{% endhighlight %}

#### Wywołania metod obserwujących

Pisałem o tym, że kontener sam wywoła stosowne metody obserwujące wygenerowane zdarzenie. Nie napisałem jednak kiedy to następuje. Wywołanie metody obserwującej zależy od typu tej metody (nie mylić z typem zdarzenia!). Mamy do wyboru dwa typy zwykłą i transakcyjną.

W przypadku zwykłych metod obserwujących są one wywoływane natychmiast inaczej mówiąc, wywołanie metody `fire` ciągnie za sobą wywołania metod obserwujących a dopiero jak te się zakończą aplikacja kontynuuje działanie w miejscu wygenerowania zdarzenia.

W przypadku metod transakcyjnych czas wywołania metod obserwujących zależy od tego jak są one zadeklarowane. Do tego celu służy nam drugi parametr adnotacji `@Observes` o nazwie `during`. Może on przyjąć jedną z wartości enumeracji `javax.enterprise.event.TransactionPhase`:

{% highlight java %}
public enum TransactionPhase {
    IN_PROGRESS,
    BEFORE_COMPLETION,
    AFTER_COMPLETION,
    AFTER_FAILURE,
    AFTER_SUCCESS
}
{% endhighlight %}

Przy czym wartość `IN_PROGRESS` jest wartością domyślną dla tego parametru. Pole enumeracji zasadniczo mówi o tym kiedy metoda zostanie wywołana:

* `BEFORE_COMPLETION` - tuż przed zakończeniem transakcji,
* `AFTER_COMPLETION` - po zakończeniu transakcji,
* `AFTER_FAILURE` - po zakończeniu transakcji, ale w przypadku niepowodzenia.
* `AFTER_SUCCESS` - po zakończeniu transakcji, ale tylko w przypadku powodzenia.


Nie ma możliwości na sterowanie kolejnością wywołań metod obserwujących. Także nie powinno się pisać aplikacji polegających na jakiejś konkretnej kolejności wywołań.

### Podsumowanie

Specyfikacja CDI spory nacisk kładzie na rozluźnienie zależności w aplikacjach. Nie tylko rozszerza znane funkcjonalności tj. komponenty przechwytujące, ale i proponuje nowe rozwiązania oparte o znane wzorce projektowe czyli dekoratory i zdarzenia. Szczególnie te drugie pozwalają na komunikację komponentów należących do różnych warstw i nie posiadających, żadnych zależności do siebie, podobnie jak dzieje się to w szynie danych. Rozwiązania te z pewnością znajdą szerokie zastosowanie w aplikacjach, które będziemy tworzyć w oparciu o tę specyfikację.