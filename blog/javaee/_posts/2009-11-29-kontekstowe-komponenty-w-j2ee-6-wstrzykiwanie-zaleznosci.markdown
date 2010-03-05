---
layout: post
title: Kontekstowe komponenty w J2EE 6 - Wstrzykiwanie zależności
description: Wstrzykiwanie zależności w specyfikacji CDI (Contexts and Dependency Injection for the Java).
keywords: java ee j2ee cdi jsr jsr-299 contextual components dependency injection
---
<a href="http://pl.wikipedia.org/wiki/Wstrzykiwanie_zależności">Wstrzykiwanie zależności</a> (ang. dependency injection) jest obecnie jednym z bodaj najczęściej używanych wzorców projektowych w świecie korporacyjnej Javy. Jest całe mnóstwo frameworków, które w różny sposób realizują to samo zadanie, które polega na wstrzyknięciu do komponentu referencji do wszelkiego rodzaju serwisów i zasobów, zwalniając tym samym komponent z potrzeby tworzenia i wyszukiwania ich na własną rękę. Wstrzykiwanie zależności jest częścią większego wzorca zwanego odwróceniem kontroli (ang. <a href="http://en.wikipedia.org/wiki/Inversion_of_control">inversion of control</a>).

Specyfikacja JSR-299 ma na celu zintegrowanie różnego rodzaju kontenerów występujących w aplikacjach JEE np. EJB, Servlet czy JSF. Siłą rzeczy wstrzykiwanie zależności jest jedną z najważniejszych rzeczy jakie ta specyfikacja powinna opisywać.

### Miejsca wstrzyknięcia

Co prawda nie ma chyba formalnie takiego pojęcia, ale samozwańczo pozwoliłem sobie na spolszczenie angielskiego terminu injection point. Tak więc miejsce wstrzyknięcia to jest ten punkt w klasie, do którego kontener wstrzyknie zależności. Specyfikacja WebBeans pozwala na zdefiniowanie następujących miejsc wstrzyknięć:
 
* Pole klasy. 
* Każdy parametr konstruktora komponentu (nie mylić z konstruktorem klasy!), metody inicjalizującej, metody produkującej lub metody zwalniającej. 
* Każdy parametr metody obserwującej (poza parametrem zdarzenia) - o zdarzeniach i obserwatorach będzie w przyszłości. 
 
Generalnie miejscami wstrzyknięć będą wszelkie miejsca, gdzie dozwolone jest użycie adnotacji `@Inject`, `@Produces`, `@Disposes` lub `@Observes`. Oto kilka przykładów deklarowania miejsc wstrzyknięć:

{% highlight java %}
public class Order {
    private Cart cart;

    @Inject
    public Order(Cart cart) {
        this.cart = cart;
    }
}
{% endhighlight %}

Powyższy przykład przedstawia konstruktor komponentu, czyli konstruktor oznaczony adnotacją `@Inject`. Pamiętajmy, że klasa może mieć wiele konstruktorów, ale tylko jeden może być konstruktorem komponentu. Jeżeli komponent nie ma adnotacji `@Inject` na żadnym ze swoich konstruktorów to konstruktorem komponentu staje się konstruktor domyślny.

{% highlight java %}
public class Order {
    private Cart cart;

    @Inject
    public void setOrder(Cart cart) {
        this.cart = cart;
    }
}
{% endhighlight %}

W tym wypadku adnotacja `@Inject` jest umieszczona na metodzie ustawiającej wartość. Taka metoda nazywa się w terminologii WebBeans metodą inicjalizacyjną (ang. initializer method). Metoda taka nie musi ograniczać się do tylko jednego parametru, może ich mieć dowolnie wiele i każdy parametr takiej metody staje się miejscem wstrzyknięcia.

{% highlight java %}
public class Order {
    @Inject
    private Cart cart;
}
{% endhighlight %}

Możemy też zadeklarować adnotację `@Inject` bezpośrednio na polu klasy, tak jak na powyższym przykładzie. Specyfikacja JSR-299 nie nakazuje deklarowania tzw. getterów i setterów dla pól w które chcemy mieć wstrzyknięcie zależności (wartości wstrzykiwane są za pomocą mechanizmu refleksji). Jednakże specyfikacja ta łączy ze sobą inne specyfikacje stosu JEE może się okazać, że inna specyfikacja wymaga tych metod (jest tak np. w przypadku JSF). Dlatego trzeba uważać w jakim kontekście będzie używany konkretny komponent.

### Identyfikacja komponentu

Referencje do komponentów można jeszcze otrzymać w inny sposób niż przez wstrzyknięcie. Klasa może niejako ręcznie, programowo wyszukać i wyciągnąć komponent z kontekstu. Referencje otrzymujemy także w miejscach w których odwołujemy się do komponentu za pomocą tzw. <a href="http://java.sun.com/products/jsp/reference/techart/unifiedEL.html">Unified  EL</a>.

Za każdym razem kiedy kontener musi odwołać się do komponentu, czy to w celu wstrzyknięcia czy aby wywołać metodę, musi zidentyfikować, który dokładnie komponent jest w danej chwili żądany. W zależności od tego z jakim przypadkiem użycia mamy do czynienia specyfikacja definiuje różne sposoby identyfikowania komponentu. Komponent żądany w celu wstrzyknięcia szukany jest po typie pola bądź parametru wstrzykiwanego, kwalifikatorach lub konfiguracji alternatywnej zdefiniowanej w deskryptorze `beans.xml` (o nim będzie później). W przypadku gdy komponent żądany jest przez EL kontener szuka komponentu po nazwie (adnotacja `@Named`) bądź alternatywnych komponentach skonfigurowanych w deskryptorze `beans.xml`.

W przypadku gdy komponent jest szukany celem wstrzyknięcia kontener rozstrzyga jakiej klasy komponent ma stworzyć po typie i kwalifikatorach, specyfikacja określa to terminami wymaganego typu (ang. required type) oraz wymaganych kwalifikatorów (ang. required qualifiers). Aby komponent został zakwalifikowany jako ten który należy wstrzyknąć musi spełniać wszystkie warunki, czyli mieć wymagany typ i wymagane kwalifikatory (typ i wymagane kwalifikatory są deklarowane w miejscu wstrzyknięcia). Kontener w czasie inicjalizowania aplikacji będzie starał się pospinać komponenty ze sobą, tak aby ewentualne problemy (np. brakujące komponenty, albo niejednoznaczne powiązania) sygnalizować już w momencie uruchamiania aplikacji.

Dodatkowo, aby komponent mógł zostać zakwalifikowany jako zdatny do wstrzyknięcia musi spełniać następujące warunki:
 
* Musi być aktywny (włączony). 
* Nie może być zadeklarowany jako komponent alternatywny, albo musi być wybranym komponentem alternatywnym (o wybieraniu komponentów alternatywnych będzie za chwilę) w danym środowisku uruchomieniowym. 
* Spełnia warunki kontenerów specyfikacji Java EE albo kontenera servletów. 
 
### Kwalifikatory

O kwalifikatorach już <a href="http://michalorman.pl/blog/2009/11/kontekstowe-komponenty-w-j2ee-6/">wcześniej</a> pisałem dlatego nie będę się powtarzał, uzupełnię jednak informacje.

Kwalifikatory to adnotacje oznaczone metaadnotacją `@Qualifier`. Służą one do "kwalifikowania" komponentów, czyli określania wymaganych warunków, które komponent musi spełniać, aby mógł zostać zakwalifikowany jako ten, którego należy użyć jako zależność. Każdy taki kwalifikator może opisywać pewną właściwość bądź typ komponentu (w zależności od tego co autor kwalifikatora miał na myśli), jednakże takich typów czy właściwości może być dużo, stąd celem zredukowania ryzyka wystąpienia zjawiska zwanego wysypem adnotacji, specyfikacja WebBeans dopuszcza wykorzystywanie w kwalifikatorach pól (czy może są to raczej metody? Nieważne, nie znam dobrego tłumaczenia angielskiego słowa <em>member</em>, a członki jakoś mi nie pasują :)). Dzięki temu możemy stworzyć jedną adnotację kwalifikatora, jednak w miejscu wstrzyknięcia będziemy mogli wybrać konkretny typ. Oto przykład:

{% highlight java %}
enum PaymentMethod {
    CHECK, TRANSFER, CREDIT_CARD
}
{% endhighlight %}

{% highlight java %}
@Qualifier
@Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface Payment {
   PaymentMethod value();
}
{% endhighlight %}

{% highlight java %}
public class Order {
    @Inject
    public Order(Cart cart, @Payment(TRANSFER)  PaymentProcessor payment) {
        // operacje...
    }
}
{% endhighlight %}

W powyższym przykładzie zdefiniowaliśmy jeden kwalifikator `@Payment` określający rodzaj płatności za pomocą pola `value`. Klasa `Order` będzie zatem obsługiwała zamówienia z wybranym przelewem jako sposobem płatności. Inna klasa może obsługiwać zamówienia z kartą kredytową jako wybranym sposobem płatności.

Jeżeli chcemy a kontener ignorował jakieś pole adnotacji (nie brał go pod uwagę identyfikując komponent) oznaczamy to pole adnotacja `@NonBinding`.

Zarówno w miejscu wstrzyknięcia jak i na komponencie można zadeklarować wiele kwalifikatorów, jednakże to miejsce wstrzyknięcia określa wymagane kwalifikatory. Komponent musi deklarować wszystkie wymagane kwalifikatory, aby mógł być wstrzyknięty, jednak nie oznacza to, że musi deklarować dokładnie takie kwalifikatory, może deklarować ich więcej. Na przykład, tak oznaczony komponent:

{% highlight java %}
@Resolver @Srevice(LOCAL)
public class LocationResolver {
}
{% endhighlight %}

może zostać wstrzyknięty w następujących miejscach wstrzyknięcia:

{% highlight java %}
@Inject @Resolver
private LocationResolver resolver;
{% endhighlight %}

{% highlight java %}
@Inject @Service(LOCAL)
private LocationResolver resolver;
{% endhighlight %}

{% highlight java %}
@Inject @Resolver @Service(LOCAL)
private LocationResolver resolver;
{% endhighlight %}

Oczywiście kwalifikatory mają sens tylko wtedy jak mamy wiele komponentów rozszerzających jeden wspólny typ albo implementujących jeden interfejs. W przeciwnym razie wystarczy nam domyślny kwalifikator `@Default`.

### Deskryptor komponentów

Każda specyfikacja czy framework wprowadza jakiś deskryptor(y). Nie inaczej jest ze specyfikacją WebBeans. Niestety w niektórych frameworkach zbyt dużą wagę przywiązano do tych plików, zmuszając nas deweloperów do programowania w XML-u (zjawisko takie nazywamy piekłem XML-owym). Adnotacje wprowadzone wraz z językiem Java 5 poprawiły tę sytuacje pozwalając na względnie deklaratywne konfigurowanie komponentów bez zbędnego babrania się w plikach XML (względna deklaratywność bierze się z tego, że aby zmiany wprowadzone w takiej konfiguracji miały miejsce trzeba ponownie skompilować klasę i załadować do JVM). Mimo wszystko deskryptory XML-owe mają swoje miejsce. Potrzebne są one wszędzie tam, gdzie konfiguracja może zmieniać się w zależności od środowiska uruchomieniowego czy kontenera (np. różne systemy operacyjne, kontenery czy środowisko testowe lub produkcyjne).

Deskryptor komponentów wprowadzany w specyfikacji JSR-299 ma umożliwić konfigurację komponentów w zależności od środowiska, w którym uruchamiamy aplikację. Deskryptor ten to plik `beans.xml` znajdujący się w katalogu `META-INF` modułu lub biblioteki Javy (np. jar) w przypadku web aplikacji deskryptor powinien znaleźć się w katalogu `WEB-INF`. Oprócz konfiguracji ma on jeszcze jedno zadanie, mianowicie oznacza archiwum jako to, które powinno działać w środowisku zdefiniowanym przez specyfikację WebBeans. Nie potrzeba zatem żadnej konfiguracji, jeżeli chcemy aby kontener zarządzał komponentami w myśl tej specyfikacji tworzymy pusty plik `META-INF/beans.xml` (`WEB-INF/beans.xml` w przypadku web aplikacji) i kontener automatycznie uruchomi dla nas odpowiednie usługi. Taki plik powinien znajdować się w każdym module i bibliotece aplikacji, która deklaruje chęć korzystania z takich usług.

### Alternatywy

Czasami jest tak, że chcielibyśmy aby kontener w danym środowisku wstrzykiwał nam inne komponenty (np. inne w środowisku produkcyjnym/deweloperskim a inne w środowisku testowym). Specyfikacja JSR-299 pozwala nam na taką konfigurację poprzez zdefiniowanie komponentów alternatywnych. Komponenty alternatywne są bardzo podobne do specjalizacji aczkolwiek nie pozwalają całkowicie zastąpić innego komponentu i trzeba je jawnie definiować w deskryptorze komponentów. Co ciekawe specyfikacja JSR-299 pozwala nam nie tylko na definiowanie alternatywnych komponentów, ale i alternatywne stereotypy przez co możemy "włączyć" serię komponentów alternatywnych za pomocą jednej konfiguracji w deskryptorze `benas.xml`. Najlepiej jak od razu przejedziemy do przykładu.

Załóżmy, że mamy następujący interfejs służący do przetwarzania danych geolokalizayjnych:

{% highlight java %}
public interface GeoLocalizator {
    public GeoCoordinates findCoordinates(String location);
}
{% endhighlight %}

Interfejs definiuje jedną metodę `findCoordinates`, która zwraca współrzędne geograficzne dla lokalizacji podanej w parametrze. W środowisku produkcyjnym podpięli byśmy jakiś komponent, który wyciągałby te dane z jakiegoś zewnętrznego serwisu (np. Google Maps) Oczywiście z wiadomych przyczyn nie chcemy tego w środowisku testowym. Zatem dla potrzeb środowiska testowego moglibyśmy zdefiniować następujący komponent alternatywny:

{% highlight java %}
@Alternative
public class MockGeoLocalizator implements GeoLocalizator {
    public GeoCoordinates findCoordinates(String location) {
        // zwracanie danych testowych...
    }
}
{% endhighlight %}

Jednak samo zadeklarowanie komponentu alternatywnego nie wystarczy, trzeba jeszcze jawnie aktywować go w deskryptorze `beans.xml`:

{% highlight xml %}
<beans
   xmlns="http://java.sun.com/xml/ns/javaee"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/beans_1_0.xsd">

   <alternatives>
          <class>pl.domena.MockGeoLocalizator</class>
   </alternatives>

</beans>
{% endhighlight %}

Można mieć wiele zadeklarowanych komponentów alternatywnych, ale tylko jeden może być aktywny! Podobnie możemy skonfigurować komponent odpowiedzialny za wysyłanie maili (w końcu nie chcemy wysyłać spamu w czasie testów czy codziennego kodowania).

Co jednak gdy mamy wiele komponentów alternatywnych a nie chcemy ich wszystkich wymieniać w deskryptorze? Jak już wspomniałem możemy zadeklarować stereotyp, który będzie nam oznaczał komponenty jako alternatywne a ich aktywowanie sprowadzi się do aktywacji w deskryptorze tylko tego stereotypu. Przykładowo możemy mieć wiele komponentów jak ten przedstawiony powyżej i chcielibyśmy je zamienić na komponenty testowe, które nie korzystają z zewnętrznych serwisów. Możemy zdefiniować następujący stereotyp wykorzystując meta adnotacje `@Stereotype` oraz `@Alternative`:

{% highlight java %}
@Alternative
@Stereotype
@Retention(RUNTIME)
@Target(TYPE)
public @interface LocalService {}
{% endhighlight %}

Następnie oznaczyć niem wszelkie lokalne serwisy jako alternatywy dla serwisów webowych:

{% highlight java %}
@LocalService
public class MockGeoLocalizator implements GeoLocalizator {
}
{% endhighlight %}

Pozostało nam jeszcze aktywować alternatywne komponenty w pliku `beans.xml`:

{% highlight xml %}
<beans
   xmlns="http://java.sun.com/xml/ns/javaee"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/beans_1_0.xsd">

   <alternatives>
          <stereotype>pl.domena.LocalService</stereotype>
   </alternatives>

</beans>
{% endhighlight %}

W środowisku z tym deskryptorem kontener będzie wstrzykiwał komponenty oznaczone adnotacją `@LocalService` jako alternatywy dla innych komponentów (oczywiście o ile takie alternatywy zostaną zadeklarowane). W tym przypadku tylko jeden komponent może zostać oznaczony stereotypem `@LocalService` jako komponent alternatywny dla innego komponentu inaczej kontener zwróci błąd ponieważ nie może jednoznacznie określić, który komponent ma wstrzyknąć.

### Dynamiczne a statyczne wstrzykiwanie zależności

Temat statycznego i dynamicznego wstrzykiwania zależności sam w sobie mógłby być tematem wpisu blogowego. Jednakże muszę tutaj poruszyć nieco ten temat, gdyż jest on w dużym stopniu powiązany z kontekstowymi komponentami. Nie pisałem jeszcze szerzej o samych kontekstach, jednak wszyscy powinniśmy znać podstawowe konteksty definiowane przez specyfikację Java Servlet i na nich się tutaj oprę.

W przypadku tradycyjnych kontenerów takich jak <a href="http://pl.wikipedia.org/wiki/Spring_Framework">Spring</a> czy <a href="http://pl.wikipedia.org/wiki/Enterprise_JavaBeans">EJB</a> mamy do czynienia ze statycznym wstrzykiwaniem zależności. Oznacza to, że zależności są wstrzykiwane w momencie utworzenia komponentu przez kontener i komponent uwiązany jest do tych referencji przez całe swoje życie. Zasadniczo model ten sprawdza się w aplikacjach stand-alone, ale niekoniecznie w web-owych.

Wyobraźmy sobie taką sytuację. Mamy komponent, który żyje przez całą długość trwania sesji. Jeżeli teraz do takiego komponentu wstrzykniemy komponent, którego cykl życia trwa tyle co jedno żądanie (ang. request) niejawnie zwiększymy jego zakres do zakresu sesji - a** to nie jest to czego oczekujemy**! To czego oczekujemy, to to że z każdym żądaniem nasz komponent sesyjny **dostanie nową referencję** do komponentu z zakresu żądania, tak aby miał zawsze aktualną referencję! W przypadku wstrzykiwania statycznego model ten nie jest obsługiwany przez kontener i sami, ręcznie musimy ratować się przed takimi sytuacjami, jednakże wstrzykiwanie dynamiczne rozwiązuje nam ten problem. Kontener, który realizuje wstrzykiwanie dynamiczne wstrzykuje zależności za każdym razem kiedy następuje odwołanie do komponentu. Dzięki temu nasz komponent w momencie wywołania akcji ma zawsze aktualne referencje do aktualnych komponentów z innych zakresów. Wstrzykiwanie dynamiczne realizuje na przykład framework <a href="http://seamframework.org/">Seam</a>.

Specyfikacja WebBeans definiuje, że **zależności mają być wstrzykiwane w sposób statyczny**. Czyli wszelkie zależne komponenty zostają wstrzyknięte tylko w momencie stworzenia instancji komponentu. Czy to oznacza, że specyfikacja ta jest podatna na problem opisany wcześniej? Nie, specyfikacja ta proponuje inne rozwiązanie tego problemu w oparciu o właśnie wstrzykiwanie statyczne.

### Obiekty proxy

Właściwie każdy kontener (a przynajmniej te z którymi ja się spotykałem ;)) nie wstrzykują jako zależności bezpośrednio instancji klas komponentów zależnych. Zwykle wstrzykiwane są obiekty pośredniczące (ang. proxy), które delegują akcje. Komponent odwołując się do zależności faktycznie odwołuje się do obiektu pośredniczącego, który przekazuje dalej sterowanie do faktycznego komponentu. Często też takich pośredników jest kilka.

Po co to wszystko jest tak zrobione? Dla tych którzy znają paradygmat <a href="http://en.wikipedia.org/wiki/Aspect-oriented_programming">programowania aspektowego</a> (ang. Aspect Oriented Programming) to pośrednicy tacy pozwalają na definiowanie tzw. punktów przecięć (ang. cross-cut), a dla tych co nie znają tego paradygmatu to po prostu pośrednicy tacy pozwalają na uruchamianie dowolnej logiki przed i po wywołaniu akcji na danym komponencie. Możemy na przykład rozpocząć transakcję przed i zakończyć po wywołaniu metody, możemy sprawdzać jakieś polityki bezpieczeństwa itd. Zastosowań jakie można wykorzystać w takich miejscach jest całe mnóstwo.

To co zakłada specyfikacja JSR-299 to to, że obiekty pośredniczące same są w stanie odszukać aktualną, kontekstową instancję komponentu zależnego (między którym pośredniczą). Tak więc w podejściu dynamicznym na barkach kontenera leży odpowiedzialność odszukiwania odpowiednich instancji komponentów i umieszczania ich w komponencie do którego się odwołujemy. W przypadku opisanym przez specyfikację WebBeans ta odpowiedzialność spada na obiekty pośredniczące, stąd nie ma sensu implementacji dynamicznego wstrzykiwania zależności.

Są pewne ograniczenia co do typów dla jakich kontener nie może utworzyć obiektów pośredniczących. Są to:
 
* klasy, które nie posiadają publicznego konstruktora domyślnego, 
* klasy oznaczone słowem kluczowym `final` albo posiadające metody oznaczone tym modyfikatorem, 
* tablice i typy prymitywne 
 
W tych przypadkach wymagane jest aby komponent posiadał zakres `@Dependent`. Zakres ten to tak naprawdę pseudo zakres i oznacza się nim komponenty, które mają zostać wstrzyknięte bezpośrednio, bez obiektu pośredniczącego.

### Dane na temat miejsca wstrzyknięcia

Czasami jest tak, że jakiś komponent wstrzykiwany nie jako pośrednik ale jako instancja (zakres `@Dependent`) potrzebuje pewnych informacji o miejscu wstrzyknięcia bądź komponencie do którego jest wstrzykiwany aby wykonać swoją pracę (obiekty pośredników mają dostęp do tych informacji ze względu na sam mechanizm pośrednictwa). Specyfikacja WebBeans określa interfejs `javax.enterprise.inject.spi.InjectionPoint` w którym znajdują się metody pozwalające na wyciągnięcie niektórych informacji o samym komponencie jak i miejscach wstrzyknięć komponentu do którego coś jest wstrzykiwane. Każdy kontener musi dostarczyć wbudowany komponent implementujący ten interfejs. Brzmi to trochę pogmatwanie, jednak zobaczmy jak to wygląda na przykładzie.

Czy nie byłoby fajnie, gdybyśmy parametry URL-a przypisywali polom konkretnego komponentu za pomocą jednej adnotacji, na przykład tak:

{% highlight java %}
public class SearchAction {
    @HttpParam("query")
    private String queryString;
}
{% endhighlight %}

Za pomocą wyżej opisanego mechanizmu jest to bardzo proste, najpierw definiujemy stosowną adnotację:

{% highlight java %}
@BindingType
@Retention(RUNTIME)
@Target({TYPE, METHOD, FIELD, PARAMETER})
public @interface HttpParam {
   @NonBinding public String value();
}
{% endhighlight %}

(na razie zignorujcie adnotację `@BindingType`, potraktujcie ją jako kolejną meta adnotację). Następnie definiujemy odpowiednią metodę produkującą:

{% highlight java %}
class HttpParams
   @Produces @HttpParam("")
   String getParamValue(ServletRequest request, InjectionPoint point) {
      return request.getParameter(point.getAnnotated().getAnnotation(HttpParam.class).value());
   }
}
{% endhighlight %}

Interfejs `InjectionPoint` pozwoli nam zwrócić wartość adnotacji nałożonej w miejscu wstrzyknięcia. W naszym przypadku jest to klasa `SearchAction` a adnotacja ma wartość "query" i pod takim kluczem będziemy szukali parametru w żądaniu servletowym. Nie wiem jak na was, ale na mnie to robi wrażenie.

Jeszcze tylko rzućmy okiem na wygląd interfejsu `InjectionPoint`:

{% highlight java %}
public interface InjectionPoint {
    public Type getType();
    public Set<Annotation> getQualifiers();
    public Bean<?> getBean();
    public Member getMember();
    public Annotated getAnnotated();
    public boolean isDelegate();
    public boolean isTransient();
}
{% endhighlight %}

Interfejs ten pozwala nam dobrać się dokładnie do miejsca wstrzyknięcia. Możemy pobrać obiekt typu `Bean` reprezentujący komponent w którym występuje miejsce wstrzyknięcia, możemy sprawdzić wymagany typ i kwalifikatory zadeklarowane w tym miejscu, czy też możemy sprawdzić adnotacje. Trzeba przyznać, że może to być całkiem użyteczny mechanizm.

### Programowe wyszukiwanie komponentów

Są sytuacje w których nie możemy określić jaki komponent ma zostać wstrzyknięty przez kontener. Może tak być dlatego, że wybór komponentu jest dynamiczny (a bądź co bądź adnotacje to statyczny sposób konfiguracji), zależy od jakiejś konfiguracji czy środowiska uruchomieniowego. Innymi słowy czasami nie da się określić zależności w czasie kodowania, czy deployment'u czasami musimy to zrobić w tzw. runtimie czyli w czasie działania aplikacji. Do tego celu posłuży nam interfejs `javax.enterprise.inject.Instance`. Podobnie jak w przypadku `InjectionPoint` kontener musi nam dostarczyć wbudowany komponent implementujący interfejs `Instance`. Aby pobrać komponent wywołujemy metodę `get()` jak na poniższym przykładzie:

{% highlight java %}
public class Order {
    @Inject
    private Instance<Cart> instance;

    public void checkout() {
         Cart cart = instance.get();
    }
}
{% endhighlight %}

W ten sposób otrzymamy instancję komponentu w czasie wywołania akcji `checkout()`.

### Podsumowanie

Ależ długi ten wpis! Na szczęście udało mi się dobrnąć do końca. Nie ma co się dziwić wstrzykiwanie zależności to główna funkcjonalność specyfikacji JSR-299 i wpis jej poświęcony siłą rzeczy zawierać będzie wiele materiału. 

Specyfikacja JSR-299 określa, że zależności mają być wstrzykiwane w sposób statyczny i na barki obiektów pośredniczących zrzuca odpowiedzialność delegowania wywołań metod do aktualnych komponentów z konkretnego zakresu. W ten sposób rozwiązany został problem niejawnego zwiększania zakresów dla komponentów z krótkich kontekstów wstrzykiwanych do komponentów o długich zakresach. Specyfikacja ta daje nam też możliwość wyciągnięcia informacji o miejscu wstrzyknięcia dla komponentów, które są wstrzykiwane jako instancje a nie obiekty pośredniczące. W końcu specyfikacja określa w jaki sposób możemy otrzymać komponent wraz z wstrzykniętymi zależnościami w czasie działania aplikacji. Zestaw ten ma na celu udostępnienie programistom prostego mechanizmu do zarządzania zależnościami w aplikacjach.