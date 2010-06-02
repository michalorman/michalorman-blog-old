---
layout: post
title: Refactoring SDK Androida z wzorcem Template Method
description: SDK platformy Android w niektórych miejscach wydaje się trochę dziwne. Przy użyciu prostych metod OO możemy je nieco doprowadzić do ładu.
keywords: Object Oriented Programming Wzorce Projektowe Android SDK Refactor
navbar_pos: 1
---
W [poście na temat Metody Szablonowej](/blog/2010/05/metoda-szablonowa/) komentujący zasugerowali mi, aby
zamiast przykładów gastronomicznych (lub innych tego typu) pokazać zastosowanie wzorca na przykładzie bardziej
życiowym. Jako, że ostatnio dużo zajmuję się poznawaniem [platformy Android](http://www.android.com/)
postanowiłem pokazać w jaki sposób przy użyciu tego wzorca można uczynić tę bibliotekę odrobinę przyjemniejszą
w użyciu.

## ``super.``Android

To co od razu rzuca się w oczy tworząc [aktywność](http://developer.android.com/reference/android/app/Activity.html) to wszędobylskie odwołania do
metod zdefiniowanych w klasach nadrzędnych. Jak nietrudno się
domyślić programista, zwłaszcza początkujący, często jest skonfundowany tym w którym miejscu ma wykonać
to wywołania, że o sytuacji, w której zapomina to zrobić nie wspomnę.

Rzućmy okiem na przykładową klasę aktywności:

{% highlight java %}
public class ViewTasks extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        new MenuInflater(getApplication()).inflate(menuId, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case R.id.create_project:
            startActivity(new Intent(this, CreateProject.class));
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

}
{% endhighlight %}

Implementację tej klasy można uogólnić do następującej postaci:

{% highlight java %}
public class ViewTasks extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // kod inicjalizacji ...
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // dodawanie opcji menu ...
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // obsługa wybrania opcji ...
        return super.onOptionsItemSelected(item);
    }

}
{% endhighlight %}

To co nam zostało to szablony metod. Generalnie w podobny sposób będą wyglądały wszelkie metody ``onCreate()``, ``onCreateOptionsMenu()`` czy
``onOptionsItemSelected()`` we wszystkich aktywnościach. Oczywiście od tej reguły mogą pojawić się wyjątki, ale i z nimi można sobie
łatwo poradzić w myśl zasady **configuration by exception**.

## Refactoring

Zatem widząc jak wyglądają szablony metod, oraz znając wzorzec Metody Szablonowej, możemy rozszerzyć klasę ``android.app.Activity`` i uczynić ją
nieco bardziej przyjazną.

Oto jak mogłaby się prezentować ta klasa:

{% highlight java %}
public abstract class Activity extends android.app.Activity {

    @Override
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        initialize(bundle);
    }

    protected abstract void initialize(Bundle bundle) {
      // empty, no action by default
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        addMenuOptions(menu);
        return super.onCreateOptionsMenu(menu);
    }

    protected void addMenuOptions(Menu menu) {
        // empty, no options by default
    }

    protected void inflateMenuOptions(int menuId, Menu menu) {
        new MenuInflater(getApplication()).inflate(menuId, menu);
    }


    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        boolean result = handleMenuItemSelection(item);
        return result ? result : super.onOptionsItemSelected(item);
    }

    protected boolean handleMenuItemSelection(MenuItem item) {
        return false;
    }

}
{% endhighlight %}

Zastosowany został tutaj właśnie wzorzec Metody Szablonowej. W tej implementacji zamiast metod ``onCreate()``, ``onCreateOptionsMenu()`` czy
``onOptionsItemSelected()`` klasa potomna powinna rozszerzać metody ``initialize()``, ``addMenuOptions()`` lub ``handleMenuItemSelection()``.
Metody te są haczykami wspomnianymi w opisie wzorca Metoda Szablonowa.
Jeżeli przypadkiem mielibyśmy do czynienia z niestandardowym przypadkiem, który np. wymagałby nie wywoływania metod z nadklasy, przeciążylibyśmy
szablonowe metody, zamiast haczyków.

Wykorzystując tą klasę nasza aktywność przybiera następującą postać:

{% highlight java %}
public class ViewTasks extends Activity {

    @Override
    protected void initialize(Bundle bundle) {
        setContentView(R.layout.main);
    }

    @Override
    protected void addMenuOptions(Menu menu) {
        inflateMenuOptions(R.menu.main_menu, menu);
    }

    @Override
    protected boolean handleMenuItemSelection(MenuItem item) {
        switch (item.getItemId()) {
        case R.id.create_project:
            startActivity(new Intent(this, CreateProject.class));
            return true;
        }
        return false;
    }

}
{% endhighlight %}

Kod ten jest odrobinę bardziej czytelny bez tych wszystkich odwołań do ``super``. Metody realizują tylko i wyłącznie swoją logikę, nie martwiąc
się tym czy i kiedy należy wywołać wersję metody z klasy nadrzędnej.

## Podsumowanie

Jak widać z pomocą wzorca Metoda Szablonowa możemy wyczyścić nasze androidowe klasy aktywności ze zbędnych odwołań do wersji metod z klas nadrzędnych.
Dzięki temu nie musimy się martwić, że zapomnimy w którymś miejscu odwołać się. Implementacja nie zamyka nam także drogi zmiany działania metody
szablonowej w sytuacji, gdy chcemy w ogóle się nie odwoływać do metody nadrzędnej, albo chcemy to zrobić w innym miejscu.

Podobnie można zrefaktorować wiele innych metod z SDK Androida, gdyż bardzo często występuje
sytuacja, w której musimy odwoływać się do metod nadrzędnych.

W kolejnym wpisie przedstawię inną modyfikacją jaką można dodać do naszej wersji klasy ``Activity`` pozwalającej w lepszy sposób wyszukiwać
komponenty widoków.

### Zasoby

Kod zaprezentowanej tu klasy ``Activity`` można podejrzeć w rozwijanej przeze mnie bibliotece:

  * [android-core](http://github.com/michalorman/android-core)

Klasa jest niepełna, ponieważ rozwijam ją sukcesywnie w miarę jak używam kolejnych rzeczy z SDK platformy Android.