---
layout: post
title: Otrzymywanie intencji i wyniki działania aktywności w Androidzie
description: W jaki sposób zarejestrować aktywność, tak aby otrzymywała ona intencje, oraz w jaki sposób dobrać się do wyników działania aktywności.
keywords: intencja aktywność platforma android intent activity
navbar_pos: 1
---
[Poprzednim](/blog/2010/05/aktywnosci-i-intencie-w-platformie-android/) razem pisałem o tym w jaki sposób z jednej
aktywności uruchomić inną za pomocą mechanizmu intencji (ang. intent). Dzięki temu nasze androidowe aktywności
nabierały cech serwisów. Teraz przyszedł czas na to, aby pokazać w jaki sposób można poinformować platformę o tym,
że nasza aktywność chce być uruchamiana za pomocą intencji, oraz jak dobrać się do rezultatów działania aktywności.

## Tworzenie aktywności-serwisu

Najpierw musimy stworzyć aktywność, która będzie pełniła rolę serwisu. Serwis nie jest tu może do końca dokładnym
określeniem, ponieważ od serwisu raczej wymaga się aby wykonał swoją prace w tle i zwrócił wyniki. W naszym przypadku
aktywność nie jest uruchamiana w tle i do tego wymaga interakcji z użytkownikiem.

Zatem do dzieła. Stwórzmy aktywność, która symulować będzie działanie skanera kodów kreskowych. Nie ma sensu
przedstawiać tutaj faktycznej implementacji takiej aktywności (aczkolwiek może kiedyś napiszę takiego posta), dlatego
nasza aktywność będzie tylko symulować działanie. W przypadku gdybyśmy potrzebowali faktycznie skanera zamiast
zabierać się za jego pisanie lepiej wykorzystać jakąś istniejącą bibliotekę np. [ZXing](http://code.google.com/p/zxing/).

W pierwszej kolejności tworzymy layout naszego pseudo-skanera:

{% highlight xml %}
<LinearLayout
    xmlns:a="http://schemas.android.com/apk/res/android"
    a:orientation="vertical"
    a:layout_width="fill_parent"
    a:layout_height="fill_parent">

    <EditText
        a:id="@+id/code"
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:hint="Specify barcode"
        a:inputType="number" />

    <Button
        a:id="@+id/scan"
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:text="Scan" />

</LinearLayout>
{% endhighlight %}

Z pewnością żaden skaner kodów nie powinien posiadać takiego layoutu, ale nie o skaner w tym poście chodzi, a o
uruchamianie aktywności za pomocą intencji.

Stwórzmy teraz naszą aktywność:

{% highlight java %}
public class FakeBarcodeScanner extends Activity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        Button scan = (Button) findViewById(R.id.scan);

        scan.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                EditText code = (EditText) findViewById(R.id.code);
                Intent result = new Intent();
                result.putExtra("code", code.getText().toString());
                setResult(RESULT_OK, result);
                finish();
            }
        });
    }
}
{% endhighlight %}

Ciekawe rzeczy dzieją się tutaj wewnątrz metody ``onClick()`` w naszej anonimowej klasie rejestrowanej jako
nasłuchiwacz kliknięć. Tworzymy nową intencję oraz dodajemy do niej wartość pobraną z naszego
pola tekstowego (która ma symulować zeskanowany kod kreskowy). Dodanie kodu wygląda dokładnie tak, jak
dodanie wartości do mapy:

{% highlight java %}
result.putExtra("code", code.getText().toString());
{% endhighlight %}

Dalej znajduje się takie oto wywołanie:

{% highlight java %}
setResult(RESULT_OK, result);
{% endhighlight %}

Jest to ustawienie wartości rezultatu działania aktywności. Android pozwala nam zwrócić rezultat działania
dwojako. Albo jako zwyczajny kod, reprezentujący zwracany status, do wyboru mamy:

  * ``RESULT_OK``,
  * ``RESULT_CANCELLED``, oraz
  * dowolny ``int`` reprezentujący kod powrotu zaczynający się od ``RESULT_FIRST_USER``.

Android oprócz samego kodu powrotu pozwala nam opcjonalnie przesłać dane w postaci obiektu ``Intent`` (to jest ten drugi
sposób zwracania wyników aktywności). W ten sposób możemy przesłać coś więcej niż tylko ``int``-a z kodem
powrotu.

Rezultat będzie rozpropagowany do wszystkich aktywności, które zadeklarowały, że nasłuchują na rezultat działania
tej aktywności. Stanie się to jednak nie w momencie ustawienia rezultatu, ale zakończenia aktywności, stąd ostatnim
wywołaniem jest wywołanie metody ``finish()``, która zakończy aktywność i rozpropaguje rezultat jej działania do
wszystkich zainteresowanych aktywności.

W tej chwili pseudo-skaner wygląda tak:

{% assign i_src='android-intents/scanner.png' %}
{% assign i_title='Pseudo skaner kodów kreskowych' %}
{% include image.html %}

### Rejestrowanie aktywności jako odbiorcy intencji

Aby aktywność mogła być uruchamiana za pomocą intencji musimy powiedzieć Androidowi jakie intencje mają
inicjować naszą aktywność. Robimy to w pliku ``AndroidManifest.xml`` ustawiając atrybut ``intent-filter``
dla naszej aktywności. Obecnie, dla nowo wygenerowanej aplikacji, w pliku tym powinno się znajdować coś takiego:

{% highlight xml %}
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="android.demo.scanner">

    <application android:icon="@drawable/icon" android:label="@string/app_name">
        <activity android:name=".FakeBarcodeScanner"
                  android:label="@string/app_name">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
{% endhighlight %}

Jak widać nasza aktywność już przyjmuje jedną intencję. Owa konfiguracja określa, że nasza aktywność jest
aktywnością główną dla naszej aplikacji, oraz należy do kategorii ``LAUNCHER`` co powoduje, że można ją
uruchamiać klikając w jej ikonę.

Teoretycznie moglibyśmy wykorzystać istniejącą konfigurację do uruchamiania naszej aktywności, ale lepsza
będzie bardziej serwisowa formuła. Załóżmy, że chcemy aby nasza aktywność dostępna była dla następującego adresu
URI:

    scan://code

Aby tak było musimy dodać nowy atrybut ``intent-filter`` w naszym manifeście:

{% highlight xml %}
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="android.demo.scanner">

    <application android:icon="@drawable/icon" android:label="@string/app_name">
        <activity android:name=".FakeBarcodeScanner"
                  android:label="@string/app_name">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.PICK" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:scheme="scan" android:path="code" />
            </intent-filter>
        </activity>
    </application>
</manifest>
{% endhighlight %}

W ten sposób skonfigurowaliśmy, że intencja wywołująca akcję ``ACTION_PICK`` z adresem
URI ``scan://code`` będzie uruchamiała naszą aktywność. Teraz możemy przejść do napisania aktywności klienta.

## Tworzenie aktywności-klienta

Aplikacja kliencka będzie bardzo prosta. Jeden przycisk, którego kliknięcie spowoduje uruchomienie naszego
pseudo-skanera, oraz pole tekstowe przedstawiające wynik zwrócony z tejże aktywności. Zatem najpierw layout:

{% highlight xml %}
<LinearLayout
    xmlns:a="http://schemas.android.com/apk/res/android"
    a:orientation="vertical"
    a:layout_width="fill_parent"
    a:layout_height="fill_parent">

    <LinearLayout
        a:orientation="horizontal"
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:layout_marginBottom="20px" >

        <TextView
            a:layout_width="wrap_content"
            a:layout_height="wrap_content"
            a:text="Scanned barcode: " />

        <TextView
            a:id="@+id/code"
            a:layout_width="wrap_content"
            a:layout_height="wrap_content"
            a:textStyle="bold" />

    </LinearLayout>

    <Button
        a:id="@+id/scan"
        a:layout_width="fill_parent"
        a:layout_height="wrap_content"
        a:text="Get the barcode" />

</LinearLayout>
{% endhighlight %}

Nie ma tutaj nic ciekawego, zatem od razu przejdźmy do kodu aktywności:

{% highlight java %}
public class ActivityResultDemo extends Activity {
    private TextView code;

    private final int REQ_CODE = 1;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        code = (TextView) findViewById(R.id.code);
        Button scan = (Button) findViewById(R.id.scan);

        scan.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivityForResult(new Intent(Intent.ACTION_PICK, Uri.parse("scan://code")), REQ_CODE);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQ_CODE && resultCode == RESULT_OK) {
            code.setText((String) data.getExtras().get("code"));
        }
    }
}
{% endhighlight %}

Przypięcie obiektu nasłuchującego do przycisku to standard, jednak ciekawe
rzeczy znajdują się w metodzie zwrotnej ``onClick()``. To tutaj uruchamiana jest nasza aktywność. Dzieje się to
za pomocą wywołania metody ``startActivityForResult`` (przypominam, że uruchomić aktywność możemy również za pomocą
wywołania metody ``startActivity`` jednakże w tym przypadku platforma nie zwróci nam wyników działania aktywności).
Metoda ta przyjmuje dwa parametry. Pierwszym jest nasza intencja uruchomienia akcji ``ACTION_PICK`` dla zasobu pod
adresem URI ``scan://code``. Drugi parametr ``REQ_CODE`` to specjalny identyfikator, który wykorzystujemy w metodzie
pobierającej wynik.

Aby otrzymać wynik działania aktywności musimy przeciążyć metodę ``onActivityResult``. Metoda ta przyjmuje trzy
parametry:

  1. ``requestCode``, który będzie odpowiadał wartości podanej w wywołaniu ``startActivityForResult`` przez co
będziemy mogli zidentyfikować, że dla którego żądania jest dany wynik.
  2. ``resultCode``, określający kod powrotu z aktywności (``RESULT_OK``, ``RESULT_CANCELLED``, itd.).
  3. Obiekt ``Intent`` przechowujący wszelkie dane określające rezultat działania aktywności.

O co chodzi z tym parametrem ``requestCode``? Ano może być tak, że nasza aktywność uruchomi wiele razy aktywność
serwisową i w momencie uruchomienia metody ``onActivityResult`` potrzebujemy rozróżnienia dla którego żądania jest
dany pakiet wyników. Parametr ten pozwoli nam się w tym zorientować.

Zatem w naszej metodzie ``onActivityResult`` sprawdzamy, czy wyniki są dla naszego żądania, oraz czy kod powrotu
to ``RESULT_OK``. Jeżeli tak to z obiektu ``Intent`` pobieramy ``Bundle`` z danymi (wywołanie metody ``getExtras()``),
a następnie pobieramy wartość znajdującą się pod kluczem ``code`` i ustawiamy w naszym polu tekstowym.

## Testowanie działania

Mając już gotowy kod możemy odpalić naszą aplikację kliencką i przetestować jej działanie (wcześniej upewniając się, że
aplikacja z naszym pseud-skanerem jest już zainstalowana w telefonie czy emulatorze). Po uruchomieniu przywita
nas ekran:

{% assign i_src='android-intents/activity_result_1.png' %}
{% assign i_title='Ekran powitalny aplikacji klienckiej' %}
{% include image.html %}

Klikamy przycisk "Get the barcode" i uruchamia się nasz pseudo-skaner:

{% assign i_src='android-intents/activity_result_2.png' %}
{% assign i_title='Pseudo skaner kodów kreskowych' %}
{% include image.html %}

Wpisujemy kod, klikamy skan i powracamy do naszej aplikacji klienckiej, która wyświetla nam kod jaki został jej zwrócony
przez skaner:

{% assign i_src='android-intents/activity_result_3.png' %}
{% assign i_title='Wynik działania skanera' %}
{% include image.html %}

Działa, nasza aktywność prawidłowo odczytała rezultat innej aktywności.

## Podsumowanie

Platforma Android pozwala nam nie tylko na uruchamianie wbudowanych aktywności, możemy rejestrować i uruchamiać własne
a także pobierać wyniki działania tychże aktywności. Nie jest to skomplikowane i daje wiele możliwości ponownego
użycia tego samego kodu w innych aplikacjach. Architektura SOA, choć lokalna, jest w tej platformie głęboko zakorzeniona
i gorąca zachęcam do pisania swoich aktywności w ten sposób (i dobrego dokumentowania).

### Zasoby

Kody źródłowe aplikacji stworzonych w tym poście:

  * [Pseudo skaner kodów kreskowych](http://github.com/michalorman/android-demos/tree/master/FakeBarcodeScanner)
  * [Aplikacja kliencka](http://github.com/michalorman/android-demos/tree/master/ActivityResultDemo/)