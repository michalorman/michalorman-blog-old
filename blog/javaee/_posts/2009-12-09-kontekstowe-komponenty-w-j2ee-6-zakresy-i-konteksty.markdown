---
layout: post
title: Kontekstowe komponenty w J2EE 6 - Zakresy i konteksty
description: Opis zakresów i kontekstów zdefiniowanych w specyfikacji CDI (Contexts and Dependency Injection for the Java).
keywords: Context Dependency Injection JSR-299 WebBeans session request conversation application zakres CDI Java EE J2EE
---
"Zakresy i konteksty" - taki tytuł nosi 6-ta sekcja specyfikacji JSR-299. Zakresy określają długość życia komponentu, na przykład komponent należący do zakresu sesji będzie żył przez czas trwania tej sesji. Oznacza to tyle, że każdy komponent, który deklaruje ów sesyjny komponent jako zależność i należy do tej samej sesji (niekoniecznie jako zakresu) będzie posiadał referencję do tego samego obiektu. Na początku zaznaczę, iż nie wiem jaka jest różnica między kontekstem i zakresem w myśl specyfikacji WebBeans, dlatego będę używał tych nazw naprzemiennie, ale dla mnie ich znaczenie jest takie samo.

Tradycyjnie było tak, że dozwolone było wstrzykiwanie komponentów tylko do komponentów o zakresie takim samym lub węższym. Miało to uchronić nas, programistów przed niejawnym rozszerzaniem zakresów komponentów. W przypadku specyfikacji WebBeans (czy jak kto woli CDI od angielskiego Contextual Dependency Injection) problem ten rozwiązywać mają odpowiednie obiekty proxy, które delegują odwołania do odpowiednich obiektów w odpowiednich zakresach (pisałem o tym w <a href="http://michalorman.pl/blog/2009/11/kontekstowe-komponenty-w-j2ee-6-wstrzykiwanie-zaleznosci/">poprzednim</a> poście). Zatem nie musimy się niczym martwić a tylko korzystać z dobrodziejstw jakie nam owe zakresy proponują.

### Zakresy podstawowe

Specyfikacja JSR-299 określa następujące zakresy:

* zakres żądania, oznaczany adntoacją `@RequestScoped`,
* zakres konwersacji, oznaczany adnotacją `@ConversationScoped`,
* zakres sesji, oznaczany adnotacją `@SessionScoped`, oraz
* zakres aplikacji, oznaczany adnotacją `@ApplicationScoped`.

Wszystkie wymienione wyżej zakresy to tzw. zakresy normalne (specyfikacja określa jeszcze tzw. pseudo zakresy). Specyfikacja pozwala także na definiowanie własnych zakresów, ale ta funkcjonalność jest dedykowana programistom, którzy tworzą własne frameworki, tak więc nie będę się specjalnie rozwodził z jej opisem.

Trzy z czterech zakresów definiowanych przez specyfikację WebBeans to standardowe zakresy znane programistom JEE. Są to zakresy definiowane przez Servlet API. Dodatkowy zakres to zakres konwersacji. Został on stworzony specjalnie z myślą o żądaniach JSF. Pozostałe zakresy są dostępne podczas:

* przetwarzania żądania servletowego,
* wywoływania web serwisów,
* wywoływania zdalnych metod EJB,
* timeoutów EJB, oraz
* podczas dostarczania komunikatów do ziaren sterowanych komunikatami.

Także w czasie jakiegokolwiek z powyższych działań mamy dostęp do podstawowych zakresów a dodatkowo podczas przetwarzania żądania JSF mamy zakres konwersacji.

Ponieważ standardowe zakresy raczej wszyscy znają opiszę tutaj tylko dodatkowy zakres mianowicie konwersacji.

### Zakres konwersacji

Jak wcześniej napisałem aby oznaczyć komponent jako żyjący w zakresie konwersacji należy oznaczyć go adnotacją @ConversationScoped. Co jednak daje nam ten zakres? Aby w pełni zrozumieć potrzebę istnienia kontekstu konwersacji musimy przypomnieć sobie jaki model web aplikacji mieliśmy dotychczas i jakie wiązały się z tym problemy.

<h4>Krótka opowieść o zakresie sesji</h4>
Dawno, dawno temu. Za siedmioma... i tak dalej. Kiedy tworzyliśmy aplikację webową z użyciem Servlet API większość naszych komponentów istniała w zakresie żądania. Dane w nich zawarte zostawały albo zamieniane na HTML i wysyłane użytkownikowi, albo były to dane wprowadzone to formularza. Czasem jednak istniała potrzeba, aby dane w komponentach przeżywały nieco dłużej niż jedno żądanie, a w szczególności były dostępne po przekierowaniu. W takiej sytuacji ładowaliśmy dane do zakresu sesji co właściwie było najgorszą rzeczą jaką mogliśmy zrobić - to się chyba nazywa ironia losu.

Jest wiele problemów jakie wynikały z takiego lekkomyślnego zachowania, a które nie były w prosty sposób rozwiązywane przez żadną specyfikację Java EE (na boga, mamy już prawie 2010 rok!). Problem z sesją jest taki, że jest to jeden wielki wór do którego wrzucamy komponenty, ale także sami musimy zadbać o to aby te dane stamtąd usunąć inaczej będą zajmować nam miejsce w pamięci (i kto powiedział, że w Javie nie ma wycieków pamięci?). Jeżeli sami o to nie zadbamy dane będą nam wisieć i zajmować zasoby aż to wygaśnięcia sesji, co w przypadku naszej aplikacji może trwać bardzo długo.

Kolejnym problemem z sesją jest to, że jest ona identyfikowana za pomocą jednego parametru, który z reguły jest przekazywany jako parametr URL-a albo w pliku cookie. Już od bardzo dawna zdradzieckie przeglądarki oferują nam możliwość przeglądania stron WWW w tzw. kartach. Jeżeli teraz użytkownik przegląda naszą witrynę w wielu kartach, może okazać się, że akcje podejmowane w jednej karcie będą wpływały na wyniki pokazywane w innych kartach, gdyż wszystkie karty współdzielą ten sam plik cookie. Trzeba naprawdę trochę nagimnastykować się, aby w taki sposób zarządzać komponentami, aby można było wrzucać je z wielu kart do tej samej sesji nie przeszkadzając sobie nawzajem.

<h4>Prawdziwy problem</h4>
Tak naprawdę prawdziwym problemem zakresu sesji jest to, że jest on za długi i nieodpowiednio podzielony. Wszystkie powyższe problemy znikną jeżeli nasz zakres sesji odpowiednio podzielimy na mniejsze zakresy, które do tego będą istniały w izolacji, czyli akcje podejmowane w jednym z tych zakresów nie będą wpływały na komponenty istniejące w innym zakresie. Dlatego właśnie został wymyślony zakres konwersacji.

W przypadku frameworka Seam, który zakres ten niejako wprowadził, konwersacja była faktycznie wydzielonym fragmentem sesji. Każda posiadała swój identyfikator i była odizolowana od pozostałych konwersacji. W przypadku specyfikacji CDI nie jest to takie jednoznaczne, gdyż specyfikacja nie narzuca implementacji. Tutaj zakres ten traktujemy jako dodatkowy zakres istniejący obok zakresu sesji, a nie taki udawany jak w przykadu Seama.

<h4>Deklarowanie komponentu konwersacyjnego</h4>
Aby zadeklarować komponent jako należący do kontekstu konwersacji używamy adnotacji `@ConversationScoped` jak niżej:

{% highlight java %}
@ConversationScoped
public class Order {
}
{% endhighlight %}

<h4>Konwersacje długo i krótkotrwałe</h4>
Konwersacja trwa przez całą długość żądania JSF. Każde żądanie JSF posiada zakres konwersacji niezależnie czy istnieją jakiekolwiek komponenty należące do tego zakresu czy nie - nie trzeba jakiejkolwiek konfiguracji i nie można tego zachowania wyłączyć. Specyfikacja definiuje dwa rodzaje konwersacji (a właściwie dwa stany w jakich może być konwersacja). Są to stan krótkotrwały (ang. transient) i długotrwały (ang. long-running). Jeżeli konwersacja jest krótkotrwała to pod koniec obsługi żądania JSF jest ona niszczona wraz ze wszystkimi komponentami (a zaraz potem tworzona jest nowa do obsługi kolejnego żądania JSF). Jeżeli jednak chcemy aby konwersacja rozpinała się na wiele żądań JSF musimy oznaczyć ją jako długotrwałą. Do tego celu służy nam komponent, którego dostarczyć musi nam każdy kontener i który implementuje interfejs `javax.enterprise.context.Conversation`. Interfejs ten wygląda następująco:

{% highlight java %}
public interface Conversation {
   public void begin();
   public void begin(String id);
   public void end();
   public boolean isLongRunning();
   public String getId();
   public long getTimeout();
   public void setTimeout(long milliseconds);
   public boolean isTransient();
}
{% endhighlight %}

Aby oznaczyć naszą konwersację jako długotrwałą należy wywołać metodę `begin`, natomiast aby oznaczyć konwersację jako krótkotrwałą należy wywołać metodę `end`. Oznaczenie konwersacji jako krótko albo długotrwałej oznacza jedynie tyle, czy konwersacja wraz z komponentami do niej wrzuconymi ma zostać zniszczona pod koniec żądania JSF czy nie. To jedyna różnica między konwersacjami będącymi w tych stanach.

Konwersacja z założenia powinna trwać krócej niż sesja. Jednakże specyfikacja nie definiuje ile powinna trwać mówi jedynie, że co najwyżej tak długo jak sesja. Co ciekawe specyfikacja daje kontenerom wolną rękę w kontekście ubijania konwersacji. Mogą to robić w dowolnym momencie, kiedy uznają to za słuszne. Co prawda interfejs `Conversation` pozwala na ustawienie czasu aktywności dla konwersacji, po którym powinna zostać ubita (jeżeli dana konwersacja nie była aktywna przez określoną liczbę milisekund), jednakże kontenery mogą traktować to jedynie jako wskazówkę do której wcale nie muszą się stosować. Czy to dobrze, że specyfikacja nie daje nam możliwości sterowania procesem zabijania konwersacji? No cóż, odpowiedź moim zdaniem jest taka jak w większości podobnych pytań, czyli i tak i nie. Pewnie znajdą się sytuację w którym taka funkcjonalność się przyda, jednakże w większości aplikacji nie powinniśmy się przejmować takimi rzeczami jak zwalnianie zasobów. Jeżeli kontener uzna, że potrzebuje zasobów powinien sam decydować o ubijaniu konwersacji celem ich zwolnienia. Byleby robił to w jakiś sensowny sposób a nie ubijał pierwszą lepszą konwersację :).

Zakres konwersacji powinniśmy traktować jako jednostkę pracy. Rozpina się ona na czas trwania konkretnego przypadku użycia systemu, a nie tylko na czas obsługi żądania czy całej sesji.

### Pseudo zakresy

Wymienione wcześniej zakresy to tzw. zakresy normalne. Specyfikacja CDI definiuje także tzw. pseudo zakresy (ang. pseudo-scope). Różnica między tymi typami zakresów jest taka, że w zakresach normalnych zamiast instancji klas zależnych wstrzykiwane są obiekty proxy, podczas gdy przy pseudo zakresie wstrzykiwane są konkretne klasy. Ponieważ przy pseudo zakresach nie mamy obiektów proxy tracimy całą funkcjonalność, którą nam te obiekty oferowały.

Specyfikacja definiuje tylko jeden pseudo zakres `@Dependent`. Komponenty należące do tego zakresu będą wstrzykiwane jako instancje klasy a nie obiekty proxy. Zasadniczo nie widzę jak na razie powodów do tworzenia własnych pseudo zakresów, aczkolwiek specyfikacja pozwala na takie manewry.

### Kwalifikator `@New`

Czasami jest tak, że jakiś komponent zadeklarowany jest w jakimś normalnym zakresie, a my jednak chcemy aby wstrzykiwany był nie jako obiekt proxy. Możemy to uczynić z wykorzystaniem kwalifikatora `@New`.

Załóżmy, że mamy następujący komponent:
{% highlight java %}
@ConversationScoped
public class Factory {
}
{% endhighlight %}

i komponent deklarujący zależności:

{% highlight java %}
public class Action {
    @Inject
    private Factory factory;

    @Inject @New
    private Factory newFactory;
}
{% endhighlight %}

W tej sytuacji w pole `factory` zostanie wstrzyknięty obiekt proxy który będzie delegował wywołania do komponentu umieszczonego w kontekście konwersacji, natomiast w pole `newFactory` zostanie wstrzyknięta instancja klasy `Factory`.

### Podsumowanie

Specyfikacja JSR-299 rozszerza standardową pulę zakresów znaną ze specyfikacji Servlet API o zakres konwersacji. Zakres ten w lepszym stopniu pozwala na zarządzanie danymi, które powinny przeżyć przekierowanie jak i trwa tak długo jak długo realizowany jest konkretny przypadek użycia systemu. Kontekst konwersacji można utożsamiać ze swoistą jednostką pracy. Kontekst ten jest dostępny wraz z każdym żądaniem JSF czy tego chcemy czy nie.

Swoją drogą ciekawi mnie czemu nie dorzucono, bardzo użytecznego moim zdaniem, zakresu strony (ang. page scope). Bardzo fajnie się on nadawał do zarządzania żądaniami AJAX-owymi wysyłanymi w ramach jednego ekranu.

Nie musimy martwić się o wrzucanie i usuwanie komponentów z kontekstów - robi to za nas automatycznie kontener. Naszym zadaniem jest jedynie zadeklarowanie do jakiego kontekstu ma należeć dany komponent. Podobnie nie musimy martwić się o kończenie konwersacji. Kontener sam będzie zamykał konwersacje, gdy stwierdzi, że potrzebuje zwolnić zasoby. Ustawienie czasu aktywności konwersacji jest tylko wskazówką dla kontenera, którą może śmiało zignorować.