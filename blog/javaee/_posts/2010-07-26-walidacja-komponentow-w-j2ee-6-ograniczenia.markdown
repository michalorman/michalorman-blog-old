---
layout: post
title: Walidacja komponentów w J2EE 6 - definiowanie ograniczeń
description: Opis specyfikacji JSR 303 Bean Validation definiującej szereg mechanizmów walidacji komponentów J2EE.
keywords: J2EE JSR 303 Bean Validation Walidacja Ziaren Constraint ograniczenia
---
Wszystko co dobre kiedyś się kończy, tak mawiają. Urlop się skończył i powoli czas wracać do programistycznej
rzeczywistości. Dawno, dawno temu pisałem o specyfikacji **JSR 299** czyli **Context Dependency Incjection**. Kolejnym
krokiem miała być specyfikacja **JSR 303** czyli **Bean Validation**, jednak dużo wody w Wiśle i Odrze upłynęło zanim
miałem okazję się jej przyjrzeć. Teraz nadarza się taka okazja toteż nadrabiam zaległości.

Specyfikacja Bean Validation to jedna z tych (po CDI) po których najwięcej sobie obiecuję, a to dlatego, że
wprowadza bardzo przydatną funkcjonalność jaką jest deklaratywna walidacja na poziomie modelu (tak przynajmniej
zakładam, w końcu jestem przed jej przeczytaniem ;)). Brak takiego mechanizmu w dotychczasowym świecie korporacyjnej
Javy traktowałem co najmniej w kategorii nieporozumienia. Ograniczenia deklarowane na poziomie adnotacji ``@Column``
są zdecydowanie niewystarczające a walidatory podpinane jako komponenty JSF (za pomocą ``<f:validator>``) to już
jakiś totalny absurd. Dlaczego? Dlatego, że walidacja na poziomie warstwy widoku to jest nonsens, który nigdy
nie powinien mieć miejsca (to równie głupie jak walidacja na poziomie przeglądarki realizowana za pomocą
JavaScriptu).

<div class="hola_dog">
<p>Co jest złego w deklarowaniu walidacji na poziomie formularzy? W końcu to one służą do wprowadzania danych do
naszej aplikacji!</p>
</div>

Nie do końca. Po pierwsze może istnieć całe mnóstwo innych miejsc, które wrzucają nam dane do systemu. Jednak
nawet zakładając, że są to tylko formularze z naszej aplikacji to wprowadzone dane poddawane są obróbce i mimo, że z formularza przychodzą
prawidłowe dane, to po obróbce mogą już nimi nie być. Zatem trzeba by tę samą logikę skopiować gdzieś do modelu i na wszystkie
inne formularze, na których używamy tych samych danych. Musielibyśmy wymierzyć solidnego kopniaka zasadzie
[DRY](http://pl.wikipedia.org/wiki/DRY).

Zatem zgodnie z powyższym 3 faza cyklu JSF (czyli faza walidacji) powinna zostać w ogóle wyrzucona z tej specyfikacji,
gdyż jest ona zwyczajnie marnotrawieniem zasobów procesora, na coś co w ogóle nie powinno się w tym momencie odbywać,
a już przynajmniej nie na bazie informacji znajdujących się w pliku JSF. Założenie, że model dostaje poprawne dane jest
założeniem błędnym, ponieważ **model nie służy tylko do utrwalania danych**, on także manipuluje danymi i **dotyczą go takie
same ograniczenia jak te dotyczące formularza**.

Gdzie zatem powinna być zaimplementowana walidacja? Tam, gdzie być powinna czyli w modelu. Walidacja tam zaimplementowana
będzie działała zawsze, niezależnie od tego, czy dane przyjdą z warstwy widoku JSF czy jakiegokolwiek innego źródła, czy
nawet będą to dane, które sami sobie wewnątrz aplikacji stworzymy. **Walidacja dotyczy modelu a nie widoku** i tam powinna
być zaimplementowana.

Niestety jak dotąd specyfikacja Java EE nie oferowała nam żadnego mechanizmu pozwalającego na sensowną walidację
modelu. Trzeba było na piechotę tworzyć jakieś rozwiązania, albo wspomagać się np. [Hibernate Validator](http://www.hibernate.org/subprojects/validator.html)
(nawiasem mówiąc jednej z implementacji specyfikacji JSR 303).
Specyfikacja JSR 303 ma na celu wypełnić brakującą lukę.

Po tym przydługim wstępie, możemy przejść do analizy samej specyfikacji.

## Definiowanie ograniczeń

Walidacja wynika z ograniczeń jakie nałożone są na konkretne atrybuty modelu. Specyfikacja Bean Validation
definiuje meta-adnotację (czyli adnotację do adnotowania adnotacji ;)) ``@Constraint`` pozwalającą nam stworzyć
adnotacje do deklaratywnego definiowania ograniczeń na konkretnych atrybutach. Adnotacja ta przyjmuje jeden
parametr ``validatedBy`` określającą klasę, która przeprowadzi walidację atrybutu. Przykładowo:

{% highlight java %}
@Constraint(validatedBy = EmailFormatValidator.class)
@Target({ METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER })
@Retention(RUNTIME)
public @interface Email {
  String message() default "{com.example.Email.message}";
  Class<?>[] groups() default {};
  Class<? extends Payload>[] payload() default {};
}
{% endhighlight %}

Powyższa adnotacja może służyć do adnotowania modelu:

{% highlight java %}
@Entity
public class User {
  @Email @Column
  private String email;
}
{% endhighlight %}

W ten sposób deklaratywnie nałożyliśmy na atrybut modelu ograniczenie co do formatu adresu email.

Powróćmy do naszej adnotacji ograniczenia, ponieważ związanych jest z nią kilka spraw. Po pierwsze, każda adnotacja
ograniczenia musi deklarować trzy atrybuty: ``message``, ``groups`` oraz ``payload``. O ile w przypadku dwóch ostatnich
deklaracja będzie po prostu domyślna (tak jak w przykładzie) o tyle w przypadku atrybutu ``message`` podajemy
klucz do stosownego komunikatu o błędzie (najlepiej zgodnie z konwencją: pakietowa nazwa klasy adnotacji ograniczenia + końcówka ".message").
Oczywiście zamiast klucza możemy podać sam komunikat, ale nie ułatwi nam to ewentualnej lokalizacji aplikacji.

Praktyczne zastosowanie tych atrybutów mam nadzieję poznać podczas dalszej lektury specyfikacji, toteż teraz ich nie będę
opisywał.

Adnotacja ograniczenia może przyjmować dowolne inne atrybuty, np:

{% highlight java %}
@Constraint(validatedBy = ZipCodetValidator.class)
@Target({ METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER })
@Retention(RUNTIME)
public @interface ZipCode {
  Locale locale();
  String message() default "{com.example.ZipCode.message}";
  Class<?>[] groups() default {};
  Class<? extends Payload>[] payload() default {};
}
{% endhighlight %}

Powyższa adnotacja deklaruje parametr ``locale``, który dalej będzie przesyłany do walidatora, aby ten wiedział
jaki format kodu pocztowego (dla jakiego kraju) powinien zostać sprawdzony.

## Wielokrotne ograniczenia i kompozycja

Czasami może być tak, że chcielibyśmy, aby ograniczenie jednego typu było nałożone na atrybut wiele razy (np. wraz z innym
komunikatem o błędzie). Specyfikacja pozwala nam to osiągnąć poprzez wykorzystanie dowolnej adnotacji, która posiada
atrybut ``value``, który zwraca tablicę adnotacji ograniczeń. Każde ograniczenie dodane do tej tablicy będzie użyte do
walidacji danego atrybutu.

Dużo ciekawszym mechanizmem jest jednak kompozycja ograniczeń, pozwalająca nam pojedyncze adnotacje ograniczeń
zbierać razem w bardziej rozbudowane. W ten sposób zamiast nakładać na atrybuty po kilka adnotacji możemy użyć jednej, która
składać się będzie z wielu. W ten sposób pojedyncze ograniczenia mogą być re-używane, jako swoiste cegiełki. Zobaczmy to
na przykładzie:

{% highlight java %}
@Size(min = 11, max = 11)
@NotNull
@Constraint(validatedBy = PESELValidator.class)
@Target({ METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER })
@Retention(RUNTIME)
public @interface PESEL {
  String message() default "{com.example.PESEL.message}";
  Class<?>[] groups() default {};
  Class<? extends Payload>[] payload() default {};
}
{% endhighlight %}

Jeżeli teraz atrybut oznaczymy adnotacją ``@PESEL`` to jednocześnie sprawdzana będzie długość ciągu (11 znaków), oraz
czy pole to nie ma wartości ``null``. Adnotacja ``@NotNull`` została tutaj użyta jedynie przykładowo, w prawdziwym kodzie
specyfikacja **nie zaleca** używania tej adnotacji do kompozycji. Dzieje się tak dlatego, że to model powinien decydować,
czy pole może mieć wartość ``null`` czy nie, a nie adnotacja ograniczenia. Gdyby nasz model zakładał, że PESEL może mieć
wartość ``null`` potrzebowalibyśmy dwóch wersji tego samego ograniczenia. Stąd też specyfikacja wspomina o tym, aby nie używać
tej adnotacji w kompozycji, a zostawić ją do jawnego deklarowania "nie-nullowości" na poziomie modelu. Z resztą każda
adnotacja użyta w kompozycji powinna być przemyślana, czy czasem nie narzuca jakiś bezsensownych ograniczeń.

Pozostaje jeszcze jedno pytanie, jeżeli dajmy na to wszystkie walidacje w kompozycji nie przejdą, jaki komunikat zostanie
dodany? Ano w tym przypadku wszystkie. Specyfikacja daje nam jednak możliwość ograniczenia komunikatów, do tylko komunikatu
ograniczenia komponującego (w naszym przypadku adnotacji ``@PESEL``). Do tego celu służy meta adnotacja ``@ReportAsSingleViolation``. Co
ciekawe specyfikacja pozostawia do decyzji implementacji czy w przypadku, gdy ograniczenie komponowane nie jest spełnione,
a ograniczenie komponujące jest oznaczone tą adnotacją, odpalić pozostałe sprawdzenia czy nie. Także w takim przypadku
nie powinniśmy polegać na tym, że wszystkie walidację się odpalą.

Specyfikacja pozwala nam także na przeciążanie ustawień domyślnych adnotacji komponowanych. Dokonujemy tego, za pomocą
adnotacji ``@OverridesAttribute`` w adnotacji komponującej.

## Definiowanie walidatorów i walidowanie atrybutów

Każda definicja ograniczenia, oznaczona meta adnotacją ``@Constraint`` deklaruje klasę, jaka dokona faktycznej walidacji
(atrybut ``validatedBy`` tej meta adnotacji). Klasa walidatora musi implementować interfejs ``javax.validation.ConstraintValidator``.
Interfejs ten deklaruje dwie metody:

  * ``initialize`` - uruchamiana za każdym razem przed dokonaniem faktycznej walidacji, w celu poinformowania walidatora,
dla jakiej adnotacji ograniczenia wywoływana będzie walidacja (pamiętajmy, że walidator może być deklarowany przez wiele
adnotacji, a czasem może być tak, że walidacja może się różnić w zależności dla jakiej adnotacji jest uruchamiana, a nawet
te same adnotacje mogą być nałożone z różnymi atrybutami).
  * ``isValid`` - dokonująca faktycznej walidacji i zwracająca ``true`` jeżeli wartość spełnia warunki walidatora.

Wydaje mi się, że można było zrezygnować z metody ``initialize``, zwłaszcza że inicjalizacja to proces, który
powinien odbywać się z założenia raz, celem nadania wartości początkowych, stąd jest to co nieco mylące (mnie zmyliło), a odpowiednią
adnotację można było przesłać jako parametr w wywołaniu metody ``isValid``.

Jest jedno bardzo ważne ograniczenie dotyczące walidatorów. Otóż nigdy, przenigdy nie może on zmieniać stanu obiektu,
przesyłanego do walidacji w metodzie ``isValid``. Pamiętajmy, że przesyłana jest tam referencja do obiektu, ktory możemy dowolnie
zmodyfikować, bez wiedzy obiektu walidowanego! Jest to oczywiście [złamaniem enkapsulacji](/blog/2010/03/enkapsulacja-a-modyfikowanie-stanu-obiektow/),
więc należy tego unikać inaczej możemy mieć do czynienia z błędem, którego będzie bardzo trudno potem wykryć.

Kolejną rzeczą jest, podobnie jak w przypadku kompozycji ograniczeń, nie zabranianie, aby atrybut walidowany posiadał
wartość ``null``. Ponownie do tego celu służy nam adnotacja ``@NotNull`` a w każdym innym przypadku powinniśmy zakładać, że
wartość ``null`` jest wartością prawidłową i walidator powinien zwracać ``true`` dla tej wartości atrybutu.

Na koniec jeszcze trzeba dodać, że do tworzenia instancji walidatorów ograniczeń służyć nam będzie obiekt klasy
``java.validation.ConstraintValidatorFactory``.

## Podsumowanie

To tyle jeżeli chodzi o pierwszą sekcję specyfikacji JSR 303 Bean Validation. Wiemy jak definiować ograniczenia i
walidatory oraz jak nakładać je na atrybuty modelu. Niestety w tym momencie nie jesteśmy w stanie sprawdzić wartości atrybutów
zależnych (np. czy data "do" jest na pewno po dacie "od"), ale liczę na to, że w dalszych sekcjach znajdę rozwiązanie tego
problemu. Także liczę na to, że specyfikacja ta jest, albo da się łatwo zintegrować z innymi specyfikacjami (zwłaszcza JSF i JPA).
Mam nadzieję, że nie jest to tak, jak to w przypadku specyfikacji Javy EE zwykło bywać, że każda specyfikacja to autonomiczny
twór, który żyje we własnym świecie nieświadomy tego co go otacza i trzeba napisać się sporo kodu, aby jakoś skomunikować
te światy ze sobą.
