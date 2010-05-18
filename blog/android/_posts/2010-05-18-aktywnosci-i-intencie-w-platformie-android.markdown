---
layout: post
title: Aktywności i intencje w platformie Android
description: Podstawową jednostką pracy w platformie Android jest aktywność (ang. Activity). Aby z jednej aktywności uruchomić inna musimy stworzyć intencję (ang. Intent).
keywords: android activity intent geo startActivity startActivityForResult onActivityResult
navbar_pos: 1
---
[Android](http://pl.wikipedia.org/wiki/Android_%28platforma%29) to bardzo ciekawa i dynamicznie rozwijająca się platforma dla urządzeń mobilnych. Do głównych cech tej platformy należy
zaliczyć jej przejrzystość, wystarczy ściągnąć i zainstalować SDK i można bawić się w pisanie aplikacji mobilnych (nie potrzeba
przy tym wydawać grubej kasy na sprzęt, instalować dziwnych certyfikatów, płacić za możliwość pisania aplikacji a na końcu
prosić się o umieszczenie swojej aplikacji w sklepie).

Platforma Android wspiera wielowątkowość od razu. Główną jednostką pracy jest aktywność (ang. Activity), którą można rozumieć
jako proces w systemie desktopowym, aczkolwiek nie jest to dokładne porównanie. Z założenia aktywność powinna odpowiadać za
obsługę konkretnego widoku (w aplikacji desktopowej mówilibyśmy o oknie), oczywiście można jedną aktywność zaprzędz do obsługi
wszystkich widoków w naszej aplikacji, ale posiadanie takiej kombo-aktywności nie będzie dobrym pomysłem i nie będzie o nas
dobrze świadczyło.

Co ciekawe aktywność może jednocześnie pełnić rolę swoistego serwisu. Każda aplikacja może posiadać wiele aktywności
i oczywistym jest, że platforma pozwala nam na uruchamianie z poziomu jednej aktywności innej. Czynimy to tworząc tzw.
intencje tudzież zamierzenia (ang. intent) - trzeba przyznać, że polski odpowiednik brzmi co nieco komicznie. Ale to nie wszystko
platforma pozwala nam na uruchamianie aktywności innych aplikacji, co tworzy je serwisami w pełnym tego słowa znaczeniu!

## Aktywności jako serwisy

Zatem jak działa mechanizm uruchamiania aktywności? Możemy go przyrównać do protokołu [HTTP](http://pl.wikipedia.org/wiki/Hypertext_Transfer_Protocol). Protokół ten generalnie składa się
z dwóch podstawowych części: czasownika, oraz adresu [URL](http://pl.wikipedia.org/wiki/Uniform_Resource_Locator) (ściślej [URI](http://pl.wikipedia.org/wiki/Uniform_Resource_Identifier)).
Czasownik określa nam czynność jaką chcemy wykonać np. GET, POST natomiast URI definiuje nam adres zasobu na którym chcemy wykonać daną czynność.

Intencje platformy Android działają podobnie jak protokół HTTP. Podajemy nazwę akcji którą chcemy wykonać, co jest odpowiednikiem
czasownika protokołu HTTP, oraz *dane*, które są odpowiednikiem adresu URI, aczkolwiek Android rozszerza nieco tę opcję. W platformie
Android jako dane możemy podać:

  * Adres URI reprezentujący zasób na jakim chcemy wykonać akcję.
  * Kategorię, reprezentującą kategorię aktywności (np. główna aktywność posiada kategorię LAUNCHER, inne kategorie to DEFAULT lub ALTERNATIVE).
  * Typ MIME, typ zasobu jeżeli nie znamy adresu URI.
  * Nazwę komponentu, a dokładniej klasę aktywności jaką chcemy wywołać.
  * Informacje dodatkowe (ang. extras) jakie chcemy przesłać do uruchamianej aktywności.

Jak widać kombinacji jest sporo, ale to jeszcze nie wszystko, ponieważ każdą aktywność można uruchomić w dwóch trybach. W pierwszym
trybie nasza aktywność nie oczekuje ażeby rezultat działania uruchomionej aktywności był do niej przesyłany, w drugim trybie, jak
łatwo się domyśleć, tak. Generalnie nie zawsze będzie nas interesował rezultat działania uruchamianej aktywności stąd platforma
Android daje nam możliwość odpalenia jej w takim trybie.

### Przykład aktywności-serwisu

Zobaczmy na przykładzie jak taka aktywność w formie serwisu działa. Oto prosta aplikacja korzystająca z wbudowanej w platformę aktywności,
która wyświetla na mapie lokalizację podaną we współrzędnych geograficznych. Aby ją wyświetlić musimy uruchomić odpowiednią akcję
z adresem uri w formacie:

    geo:latitude,longitude

Zatem do roboty, oto jak wyglądać będzie widok:

{% highlight xml %}
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:a="http://schemas.android.com/apk/res/android"
    a:orientation="vertical"
    a:layout_width="fill_parent"
    a:layout_height="fill_parent">

    <TextView
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:background="#333"
        a:paddingLeft="7px"
        a:paddingTop="3px"
        a:paddingBottom="3px"
        a:textStyle="bold"
        a:text="Specify your location:" />

    <TableLayout
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:stretchColumns="1"
        a:padding="10px">

        <TableRow>
            <TextView
                a:layout_width="fill_parent"
                a:layout_height="wrap_content"
                a:text="latitude:"
                a:gravity="right" />
            <EditText
                a:id="@+id/latitude"
                a:layout_width="fill_parent"
                a:layout_height="wrap_content"
                a:layout_marginLeft="10px"
                a:inputType="numberSigned|numberDecimal" />
        </TableRow>

        <TableRow>
            <TextView
                a:layout_width="fill_parent"
                a:layout_height="wrap_content"
                a:text="longitutde:"
                a:gravity="right" />
            <EditText
                a:id="@+id/longitude"
                a:layout_width="fill_parent"
                a:layout_height="wrap_content"
                a:layout_marginLeft="10px"
                a:inputType="numberSigned|numberDecimal" />
        </TableRow>
    </TableLayout>

    <Button
        a:id="@+id/show"
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:text="Show" />
</LinearLayout>
{% endhighlight %}

Warto zwrócić uwagę, iż pola tekstowe w których podajemy współrzędne geograficzne mają typ ``numberSigned|numberDecimal`` (pomiędzy jest znak '|'), czyli
dziesiętne liczby ze znakiem. To spowoduje, że platforma wyświetli nam odpowiednią klawiaturę (tylko z cyframi i odpowiednimi znakami), a do tego zapewni
nam odpowiednie filtrowanie znaków wprowadzanych z tejże klawiatury.

Teraz czas na kod aktywności:

{% highlight java %}
public class IntentsDemoActivity extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        // Łączymy elementy z widokiem
        final EditText latitude = (EditText) findViewById(R.id.latitude);
        final EditText longitude = (EditText) findViewById(R.id.longitude);
        Button showButton = (Button) findViewById(R.id.show);

        // Konfigurujemy listenera dla przycisku
        showButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Pobieramy wartości edytowalnych pól tekstowych
                String lat = latitude.getText().toString();
                String lon = longitude.getText().toString();

                // Tworzymy URI
                Uri uri = Uri.parse("geo:" + lat + "," + lon);

                // startujemy aktywność
                startActivity(new Intent(Intent.ACTION_VIEW, uri));
            }
        });
    }
}
{% endhighlight %}

Cała magia znajduje się w wywołaniu jednej metody:

{% highlight java %}
startActivity(new Intent(Intent.ACTION_VIEW, uri));
{% endhighlight %}

``ACTION_VIEW`` to jest typ naszej akcji, która określa, że chcemy podejrzeć informacje z zasobu. Pełna lista akcji znajduje się oczywiście
w [dokumentacji platformy](http://developer.android.com/reference/android/content/Intent.html). Drugim parametrem jest adres URI, który
tworzymy zgodnie z formatem podanym wcześniej i wartościami pobranymi z pól tekstowych.

Oto jak wygląda nasza aktywność:

<a href="/images/android-intents/activity.png" rel="colorbox" title="Wygląd zdefiniowanej aktywności">
  <img src="/images/android-intents/activity.png" alt="Wygląd zdefiniowanej aktywności" />
</a>

A tak uruchomiona przez nas aktywność:

<a href="/images/android-intents/map.png" rel="colorbox" title="Wygląd uruchomionej aktywności">
  <img src="/images/android-intents/map.png" alt="Wygląd uruchomionej aktywności" />
</a>

Jak widać mapa wskazuje na lokalizację, dla której podaliśmy współrzędne w naszej aktywności (tak współrzędne 53.43, 14.529 to współrzędne
miasta Szczecin). Klikając przycisk powrotu wrócimy do naszej aktywności. Jak widać w tym przypadku nie ma sensu pobieranie rezultatu
działania wywołanej aktywności (bo co by miało być takim rezultatem?) stąd aktywność wywołana została za pomocą metody ``startActivity``.
Gdybyśmy potrzebowali otrzymać wyniki działania aktywności musielibyśmy wywołać metodę ``startActivityForResult`` oraz przeładować metodę
``onActivityResult``, która zostanie wywołana kiedy zakończy się uruchomiona aktywność.

## Podsumowanie

Jak widać wywołanie innej aktywności jako swoistego serwisu jest proste. Taka architektura daje nam wiele możliwości i powinna być szeroko stosowana
zwłaszcza w czasach, gdzie architektura [SOA](http://pl.wikipedia.org/wiki/Architektura_zorientowana_na_us%C5%82ugi) staje się coraz popularniejsza.
Platforma Android ten rodzaj architektury ma niejako wbudowaną, ponieważ każda aktywność może pełnić rolę serwisu. W następnym wpisie
przedstawię jak stworzyć i zarejestrować własny serwis oraz w jaki sposób otrzymywać rezultaty jego działania.