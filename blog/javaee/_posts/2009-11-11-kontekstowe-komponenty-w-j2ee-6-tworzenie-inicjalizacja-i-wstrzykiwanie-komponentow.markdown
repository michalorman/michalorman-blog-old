---
layout: post
title: Kontekstowe komponenty w J2EE 6 - tworzenie, inicjalizacja i wstrzykiwanie komponentów
description: Sposoby tworzenia komponentów, inicjalizacji oraz wstrzykiwania zależności w specyfikacji CDI (Contexts and Dependency Injection for the Java).
keywords: java ee j2ee cdi jsr jsr-299 contextual components dependency injection
---
W <a href="http://michalorman.pl/blog/2009/11/kontekstowe-komponenty-w-j2ee-6/">poprzednim</a> poście wstępnie opisałem ideę jaka przyświecała specyfikacji JSR-299. Wstępnie opisałem czym są komponenty, jak je deklarować i wstrzykiwać oraz jak je identyfikować. Teraz przyszedł czas na nieco bardziej dogłębną analizę. Na początek jednak muszę napisać małą dygresję na temat nazewnictwa używanego w specyfikacji.

Otóż w tradycji J2EE przyjęło się, że instancje klas zarządzane przez kontener nazywa się ziarnami (ang. beans), głównie ze względu na specyfikację <a href="http://pl.wikipedia.org/wiki/JavaBeans">JavaBeans</a>. Ja osobiście ani za bardzo nie przepadam za tą specyfikacją gdyż promuje one <a href="http://www.javaworld.com/javaworld/jw-09-2003/jw-0905-toolbox.html">złe praktyki programowania</a> (oczywiście można dyskutować, że to nie wina specyfikacji, tylko niekompetentnych programistów, tak jak firma produkująca noże nie promuje seryjnych morderców, jednak niesmak pozostaje, przynajmniej u mnie), ani nie uważam, ażeby nazwa ziarno była szczególnie trafiona. Zapewne autorom chodziło tutaj o grę słów, Java - <a href="http://pl.wikipedia.org/wiki/Java_(kawa)">rodzaj kawy</a> i ziarna (kawy). Ja osobiście wolę nazwę komponent i takiej będę konsekwentnie używał (no może, czasem jakieś ziarno mi się wetknie ;)). Nazwa komponent zdecydowanie lepiej pasuje mi w kontekście kontenerów, które je tworzą i nimi zarządzają bo inaczej kontenery musielibyśmy nazywać młynkami (ang. grinder, mill), filiżankami (ang. cup) albo jakimiś puszkami (ang. canister) a wtedy dopiero byłoby to wszystko komiczne dla znajomych ze świata .NET czy innych Railsów. Tak więc instancję klasy tworzoną i zarządzaną przez kontener nazywać będę komponentem - koniec dygresji.

### Komponenty

Specyfikacja JSR-299 definiuje dwa rodzaje komponentów:

* Komponenty (ang. managed beans), oraz
* Komponenty sesyjne (ang. session beans)

Dlaczego tych pierwszych nie nazywam np, "komponentami zarządzanymi"? Dlatego, że komponenty są zarządzane (przez kontener) z definicji, więc po co się powtarzać.

Specyfikacja pozwala także na definiowanie swoich typów komponentów (np. przez aplikację, framework czy kontener) poprzez implementację interfejsu `javax.enterprise.inject.spi.Bean`, jednak o tym w tej części pisać nie będę.

Zatem jakie klasy mogą być komponentami? Zasadniczo każda klasa, która albo spełnia warunki bycia komponentem kontenera dowolnej specyfikacji Javy EE (np. servlety, managed-beans z JSF, EJB), albo spełnia pewne określone warunki (o tym za chwilę). Kwestia tylko, czy klasa jest komponentem czy komponentem sesyjnym.

#### Komponenty zarządzane

Regularnym komponentem zarządzanym, jest każdy komponent dowolnej specyfikacji Javy EE wyłączając specyfikację EJB (dla niej tworzone są komponenty sesyjne), albo każdy komponent spełniający poniższe warunki:

* Nie jest niestatyczną klasą wewnętrzną (bo stworzenie instancji takiej klasy wymaga stworzenia instancji klasy zewnętrznej, a z tym zadaniem kontenery sobie nie poradzą, tzn. mogłyby, ale po co? Takie twory jedynie komplikowałyby aplikację, a nie wnosiłyby żadnej sensownej funkcjonalności, więc twórcy specyfikacji po prostu to zostawili - i bardzo dobrze, nie potrzeba nam dodatkowych komplikacji, wystarczą już te, które przychodzą wraz z samym językiem Java).
* Jest konkretną (nieabstrakcyjną) klasą, albo oznaczoną adnotacją `@Decorator`.
* Nie jest oznaczona adnotacjami definiującymi komponenty EJB ani nie jest zadeklarowana w pliku `ejb-jar.xml` (bo jak już wspomniałem, takie komponenty są komponentami sesyjnymi).
* Posiada odpowiedni konstruktor:
  * domyślny (bezparametrowy), albo
  * posiadający parametry, ale oznaczony adnotacją `@Inject`

To wszystko, nie trzeba żadnych dodatkowych deklaracji w postaci konfiguracji XML czy adnotacji, aby zadeklarować klasę jako typ komponentu. Kontener sam wykryje odpowiednie klasy i pozwoli na tworzenie komponentu o tym typie.

#### Komponenty sesyjne

Komponenty sesyjne, są to wszelkie komponenty, które zadeklarowane są zgodnie ze specyfikacją EJB 3.x i są zarządzane przez ten kontener. Nie potrzeba żadnych dodatkowych deklaracji. Można za to komponenty sesyjne (EJB) oznaczać adnotacjami wynikającymi bezpośrednio ze specyfikacji JSR-299 (np. `@Default`, `@Model`, `@ConversationScoped` itd.), które niejako rozszerzają funkcjonalność komponentów o rzeczy wynikające z tej specyfikacji.

Komponenty sesyjne, w przeciwieństwie do zwykłych komponentów, otrzymują domyślne nazwy (tak jakby były oznaczone adnotacją `@Named`), przez co można się do nich odwoływać za pomocą EL. Domyślna nazwa jest standardowa, czyli nazwa klasy z pierwszą literą zamienioną z wielkiej na małą.

### Konfiguracja przez konwencję

Podejście zastosowane w specyfikacji WebBeans, czyli konfiguracja (komponentów) przez konwencję, ma szereg zalet. Nie wymusza to na nas, żadnej dodatkowej konfiguracji nie wynikającej bezpośrednio z wymagań konkretnej specyfikacji Java EE np. EJB. Jeżeli jakaś klasa spełnia warunki bycia pełnoprawnym komponentem to nie potrzeba przecież żadnej dodatkowej deklaracji, która by nam mówiła "tak panie kontener, chcę tworzyć komponenty tej klasy". Po prostu kontener sam powinien kwalifikować klasy jako te które mogą być komponentami i te które nie mogą nimi być (i ewentualnie rzucać wyjątkami na lewo i prawo, kiedy jakiś programista spróbuje stworzyć komponent niedozwolonego typu). Ma to jeszcze jedną implikację, mianowicie plik konfiguracyjny (tradycyjnie XML-owy). Jeżeli nasza aplikacja wykorzystywała jakąś bibliotekę, a my nie mieliśmy możliwości edycji źródeł i rekompilacji (aby nałożyć jakąś adnotację) to jedynym sposobem zadeklarowania komponentu o typie z biblioteki był plik konfiguracyjny. W przypadku specyfikacji JSR-299 nie potrzebujemy żadnych deklaracji, aby można było tworzyć komponenty o typie zdefiniowanym w bibliotece, o ile zadowolimy się konfiguracją domyślną. Jeżeli potrzebujemy dodatkowych deklaracji (jak zakres) to nie obejdziemy się bez pliku konfiguracyjnego (albo odpowiedniej metody fabrykującej oznaczonej adnotacją `@Produces`, ale o tym później).

### Dziedziczenie i specjalizacja

Dziedziczenie to jedna z podstawowych i najczęściej wykorzystywanych koncepcji w programowaniu obiektowym (i jednocześnie najczęściej wykorzystywana <a href="http://www.parashift.com/c++-faq-lite/proper-inheritance.html#faq-21.6">źle</a>). W przypadku komponentów zarządzanych pojawia się kilka problemów. Weźmy dla przykładu scenariusz w którym pewna klasa dziedziczy po innej klasie, chcąc wykorzystać funkcjonalność klasy bazowej (nieco ją modyfikując) a jednocześnie obie klasy spełniają warunki bycia komponentem. Nasuwa się pytanie, czy jeśli klasa bazowa deklaruje jakieś kwalifikatory, zakresy czy inne adnotacje to czy klasa potomna też je deklaruje? Ci co znają dobrze język Java powiedzą: to zależy czy konkretne adnotację są oznaczone adnotacją `@Inherited`. Oczywiście to jest prawda, w istocie tak się będzie działo, jednak co w przypadku, gdy klasa bazowa deklaruje pola, których zależności mają zostać wstrzyknięte przez kontener (miejsca wstrzyknięcia)? Zależności te mogą (i pewnie są) wykorzystywane przez tę klasę i trzeba je najpierw rozwiązać, aby móc z niej korzystać. Tutaj temat jest nieco kontrowersyjny, gdyż teoretycznie język Java nie pozwala na dziedziczenie adnotacji nałożonych na pola zwłaszcza prywatne z prostej przyczyny - pola prywatne nie są widoczne przez klasy potomne (nie są przez nie dziedziczone), więc po co miałyby być dziedziczone same adnotacje. Zasada ta jednak dla potrzeb prawidłowego działania została niejako złamana. Oznacza to, że jeżeli komponent bazowy deklaruje prywatne pola jako miejsca wstrzyknięcia, to stworzenie komponentu potomnego spowoduje zainicjalizowanie tych pól (nie ważne, że klasa potomna nic o nich nie wie). Co ciekawe, specyfikacja JSR-299 twierdzi, że to zachowanie jest standardowe, czytamy:

> * If X declares an injected field x then Y inherits x.
> 
> (This behavior is defined by the Common Annotations for the Java Platform specification.)

Jednakże specyfikacja JSR-250 (o której tam mowa), mówi coś zupełnie innego:

> Members inherited from a superclass and which are not hidden or overridden
> maintain the annotations they had in the class that declared them, including
> member-level annotations implied by class-level ones.

Zmienna prywatna jest jak najbardziej zmienną ukrytą przed potomkami, więc teoretycznie nie powinna być dziedziczona. Według mnie problem leży tutaj gdzie indziej i wynika jedynie ze słownictwa użytego w specyfikacji. Mianowicie, kontener wstrzyknie zależności nawet prywatnym polom klas bazowych (nie ważne czy są one widoczne z poziomu aktualnej klasy czy nie), aby zapewnić im prawidłowe działanie, ale to nie ma nic wspólnego z dziedziczeniem (ani pole, ani tym bardziej adnotacja nie jest dziedziczona). Tak więc wystarczyłoby, aby w specyfikacji ten problem opisano przy pomocy innych słów (a nie z mylącym dziedziczeniem) i byłoby to dużo bardziej przejrzyste i zrozumiałe.

Tak więc podsumowując, adnotacje nałożone na klasę są dziedziczone, o ile zgodnie z językiem Java są oznaczone adnotacją `@Inherited`, w przypadku pól (zwłaszcza prywatnych) nie mówimy o dziedziczeniu, a jedynie o tym, że kontener wstrzyknie zależności niezależnie od tego czy pole jest prywatne czy nie. A teraz przejdźmy do tego co mówi specyfikacja.

#### Adnotacje na poziomie typu

Jak już wspomniałem dziedziczone są wtedy, kiedy oznaczone są adnotacją `@Inherited`. Specyfikacja zaleca oznaczanie adnotacji jako `@Inherited` w następujących przypadkach:

* adnotacji określających zakresy,
* adnotacji określających kwalifikatory, oraz
* adnotacji określających interceptory

W przypadku stereotypów użycie adnotacji `@Inherited` zależy od konkretnego przypadku, dlatego specyfikacja pozostawia tu wolną rękę. Oczywiście to są tylko zalecenia, a nie wymagania.

#### Adnotacje na poziomie pól i metod

Same pola i adnotacje nie są dziedziczone, tylko dziedziczone jest miejsce wstrzyknięcia, zatem w tym kontekście specyfikacja definiuje następujące reguły:

* dziedziczone są wszystkie miejsca wstrzyknięcia oznaczone na polach,
* w przypadku metod miejsca te, jak i metody dotyczące cyklu życia oraz interceptory są dziedziczone tylko wtedy, jeżeli klasa dziedzicząca, ani żadna klasa nadrzędna nie nadpisze tych metod (ang. override).

Metody i pola oznaczone adnotacją `@Producer` nie są dziedziczone w żadnym przypadku (pamiętajmy, że nie chodzi o samo dziedziczenie pól czy metod, ale funkcjonalności fabrykującej).

#### Typy generyczne

Co ciekawe, specyfikacja określa także jak powinny być traktowane zmienne generyczne w miejscach wstrzyknięć. Na przykład mając następującą klasę:

{% highlight java %}
public class Action<T> {
    @Inject
    private EntityHome<T> home;
}
{% endhighlight %}

I klasę rozszeżającą:

{% highlight java %}
public class SpecificAction extends Action<User> {
}
{% endhighlight %}

To klasa `SpecificAction` dziedziczy miejsce wstrzyknięcia, ale w jej przypadku zostanie wstrzyknięty obiekt `EntityHome`.

#### Specializacja

Czasami zachodzi taka sytuacja, że chcemy całkowicie zastąpić jednym komponentem inny komponent, tak aby ten drugi nie był używany w aplikacji. Oczywiście, moglibyśmy wymienić wszystkie miejsca użycia tego drugiego komponentu na pierwszy, jednak nie jest to najlepsze rozwiązanie i łatwo jest popełnić błąd lub po prostu zapomnieć gdzieś zmienić. Może też być tak, że wymieniamy np. komponent dostarczony wraz z frameworkiem i nawet nie możemy wymienić wszelkich punktów wstrzyknięć i wyrażeń EL. Problem się jeszcze bardziej komplikuje, jeżeli komponent, który chcemy wymienić ma metody fabrykujące oznaczone adnotacją `@Produces` (o których jeszcze nie mówiłem, ale nie jest to teraz tak istotne). Specyfikacja WebBeans definiuje jednak eleganckie rozwiązanie dla tego problemu.

Jeżeli chcemy całkowicie jeden komponent drugim, tak aby kontener nie tworzył instancji tego drugiego musimy:

* odziedziczyć komponent który chcemy zastąpić (tak, aby z pewnością implementować ten sam interfejs), oraz
* oznaczyć komponent adnotacją `@Specializes`

Jeżeli spełnimy powyższe warunki kontener nigdy nie powoła do życia komponentu o typie bazowym a zawsze o typie odziedziczonym. Nawet jeżeli typ bazowy deklarował metody adnotacją @Produces zostanie ona wywołana na instancji komponentu specjalizującego. Tylko jeden komponent może specjalizować inny komponent, w przeciwnym razie kontener zgłosi błąd w momencie inicjalizacji aplikacji, można jednak specjalizować komponent, który specjalizuje inny komponent (tworząc taki łańcuch specjalizacji i komplikując przy tym model :P).

### Konstrukcj i spełnianie zależności komponentu

Kontener jest odpowiedzialny zarówno za tworzenie jak i wstrzykiwanie (spełnianie) zależności komponentu wszędzie tam gdzie zadeklarowane są miejsca wstrzyknięcia (ang. injection points) w całej hierarchii dziedziczenia (we wszystkich nad typach). Czynności te wykonywane są automatycznie. Jednak aby kontener mógł stworzyć nasz komponent musi wywołać konstruktor.

#### Konstruktory komponentów

Specyfikacja JSR-299 pozwala na zdefiniowanie konstruktora z parametrami lub bez, ale tylko jeden konstruktor może zostać zadeklarowany jako ten, na podstawie którego kontener ma tworzyć komponent. Aby zadeklarować konstruktor argumentowy używamy adnotacji `@Inject` jak na poniższym przykładzie:

{% highlight java %}
public class Order {
    private Product product;

    @Inject
    public Order(@Selected Product product) {
        this.product = product;
    }
}
{% endhighlight %}

Powyższy komponent zostanie stworzony za pomocą konstruktora oznaczonego adnotacją `@Inject` a jako parametr zostanie przekazany komponent identyfikowany kwalifikatorem `@Selected`. Każdy komponent może mieć wiele konstruktorów (w tym i bezargumentowy), ale tylko jeden może być oznaczony adnotacją `@Inject` w przypadku braku konstruktora oznaczonego tą adnotacją domyślnie brany jest bezargumentowy, a jeżeli takiego nie ma to zgłaszany jest odpowiedni wyjątek.

#### Wstrzykiwanie zależności

Kiedy komponent zostanie stworzony kontener we wszystkich miejscach wstrzyknięcia będzie umieszczał komponenty zależne (zgodnie z regułami dopasowania przez kwalifikatory). Procedura wstrzykiwania zależności została już częściowo opisana we wcześniejszym wpisie, jednak tutaj przedstawię ją nieco szczegółowiej.

Miejscem wstrzyknięcia zależności jest miejsce oznaczone adnotacją `@Inject`. Adnotacja ta może być umieszczona zarówno na polu klasy jak i jej metodzie np:

{% highlight java %}
public class Authenticator {
    @Inject
    private Credentials credentials;

    private HashGenerator hashGenerator;

    @Inject @SHA
    public setHashGenerator(HashGenerator hashGenerator) {
        this.hashGenerator = hashGenerator;
    }

    // reszta metod...
}
{% endhighlight %}

Nie są to wszystkie możliwe miejsca wstrzyknięcia, ale na razie skupmy się naC tych dwóch, bo są one bardziej tradycyjne. Pamiętamy, że każdy komponent identyfikowany jest kwalifikatorem i w razie jego braku wykorzystywany jest kwalifikator `@Default` i pod takim kwalifikatorem będzie szukany komponent `Credentials` natomiast `HashGenerator` zostanie wstrzyknięty ten który identyfikowany jest przez kwalifikator `@SHA`. Pole oznaczone jako miejsce wstrzyknięcia nie może być statyczne ani oznaczone słowem kluczowym `final`, natomiast metoda nie może być oznaczona słowami kluczowymi `abstract` i `final` nie może także przyjmować parametru generycznego, specyfikacja (przynajmniej do tego miejsca ;)) nie mówi, czy taka metoda może zwracać wartości czy musi być oznaczona jako `void`.

De facto metody, które można oznaczyć jako miejsca wstrzyknięcia, nie ograniczają się do "setterów". Może to być dowolna metoda (spełniająca opisane wcześniej warunki) przyjmująca dowolną liczbę parametrów, przy czym każdy taki parametr zostaje punktem wstrzyknięcia (zależnością do komponentu, którą kontener musi zidentyfikować, odnaleźć lub stworzyć i wstrzyknąć).

Jeżeli w miejscu wstrzyknięcia zadeklarowano więcej niż jeden kwalifikator, to aby komponent mógł być wstrzyknięty musi deklarować wszystkie wymagane kwalifikatory np:

{% highlight java %}
public class Car {
    @Inject @Petrol @Turbo
    private Engine engine;
}
{% endhighlight %}

W miejscu wstrzyknięcia zostanie wstrzyknięty taki komponent, który deklaruje kwalifikatory `@Petrol` i `@Turbo` (oba, a nie jeden z nich).

O samym procesie wstrzykiwania zależności wspomnę jeszcze w którymś z przyszłych wpisów.

### Podsumowanie

Podsumowując ten całkiem długi post. JSR-299 pozwala nam deklaratywnie tworzyć komponenty z niemal dowolnych klas. Podejście <a href="http://en.wikipedia.org/wiki/Convention_over_configuration">convention over configuration</a> pozwala deklarować komponenty bez żadnych dodatkowych semantyk. Specyfikacja określa sposób zachowania kontenerów w przypadku dziedziczenia, jak i pozwala na całkowitą podmianę komponentów przez specjalizację. Wstrzykiwanie zależności również zostało nieco udoskonalone w porównaniu ze standardowym podejściem znanym z frameworka Spring czy EJB.