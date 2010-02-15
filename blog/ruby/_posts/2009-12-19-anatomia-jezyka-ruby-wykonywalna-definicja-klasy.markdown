---
layout: post
title: Anatomia języka Ruby - wykonywalna definicja klasy
description: W jaki sposób Ruby realizuje wykonywalność ciała klasy.
keywords: Ruby Klasa Definicja Deklaracja Ciało Kod wykonywalność
---
Niniejszy wpis stanowi wytłumaczenie znaczenia wykonywalności definicji klasy w języku Ruby dla programistów programujących w takich językach jak Java. W pierwszej chwili zrozumienie iż definicja klasy (jej ciało) jest kodem wykonywalnym jest trudne. Jednakże zrozumienie tego zagadnienia otwiera nam szeroki wachlarz możliwości i ciekawych rozwiązań chociażby związanych z tworzeniem języka specyficznego dla konkretnej domeny (<a href="http://en.wikipedia.org/wiki/Domain-specific_language">DSL</a>).

### Odbiorcy komunikatów

Miejsce wykonywalne to zasadniczo miejsce z którego możemy wysyłać komunikaty. Komunikaty zawsze mają odbiorcę. Odbiorcę albo deklarujemy jawnie, albo korzystamy z domyślnego odbiorcy którym jest `self` (taki odpowiednik referencji `this` z języka Java). Na przykład:

{% highlight ruby %}
a.komunikat  # komunikat zostanie przesłany do obiektu do którego odwołuje się 'a'
komunikat  # komunikat zostanie przesłany do obiektu do którego odwołuje się 'self'
self.komunikat  # j.w.
{% endhighlight %}

Kluczem do zrozumienia wykonywalności definicji klasy jest zrozumienie kto będzie odbiorcą komunikatu. Rzućmy okiem na poniższy rysunek:

<a href="/images/wykonywalne_sekcje.png" rel="colorbox"><img src="/images/wykonywalne_sekcje.png" alt="wykonywalne_sekcje" title="wykonywalne_sekcje" width="587" height="360" class="alignnone size-full wp-image-529" /></a>

Na obrazku tym zaznaczone zostały pewne przestrzenie oznaczające kto będzie domyślnym odbiorcą komunikatu wysłanego z danego miejsca. Głównym odbiorcą komunikatu jest obiekt klasy `Object` (kolor pomarańczowy), jeżeli zdefiniujemy klasę to w jej ciele odbiorcą komunikatu jest obiekt klasy `Class` (zielony) a wewnątrz metody obiekt klasy `Foo` (żółty). Czerwona strzałka oznacza kierunek w jakim deklaracje będą przetwarzane przez interpreter.

Teraz wyobraźmy sobie, że jesteśmy interpreterem. Rozpoczynamy analizowanie pliku (zgodnie ze strzałką) napotykamy na:

{% highlight ruby %}
class Foo
{% endhighlight %}

jest to pewien synonim dla jawnego wywołania komunikatu nakazującego utworzenie klasy. Ponieważ w tym miejscu domyślnym odbiorcą komunikatu jest `Object` to do niego wysyłany jest ten komunikat. Tworzymy odpowiedni obiekt `Class` który będzie odpowiadał za obiekt `Foo` (czyli przechowywał metody itp.). Tak po prawdzie Ruby tworzy tutaj dwa obiekty, pierwszy to obiekt `Foo` na którego będą wskazywać referencję a drugi to obiekt klasy `Class`. Teraz przechodzimy do analizy ciała deklaracji klasy, czyli wchodzimy w obszar gdzie domyślnym odbiorcą komunikatu będzie obiekt `Class` który właśnie stworzyliśmy. Napotykamy na deklarację:

{% highlight ruby %}
def metoda
{% endhighlight %}

jest to synonim dla jawnego wywołania komunikatu nakazującego utworzenie metody. Komunikat ten wysyłamy do domyślnego odbiorcy, czyli obiektu `Class`. Gdybyśmy zmienili domyślnego odbiorcę komunikatu metoda zostałaby utworzona gdzie indziej (stąd taki efekt uboczny, że klasy w Ruby są zawsze otwarte) np:

{% highlight ruby %}
def Object.metoda
{% endhighlight %}

Komunikat zostanie wysłany do obiektu klasy `Object` i tam zostanie utworzona metoda (uwaga, w tym przypadku zostanie utworzona metoda klasy a nie metoda egzemplarza!).

Mając już dodaną metodę jako interpreter wchodzimy do jej ciała i wszystkie wywołania komunikatów będą miały za domyślnego odbiorcę obiekt klasy `Foo`.

Pulę domyślnych odbiorców traktujmy jak stos. Deklaracje takie jak `class` czy `def` każą nam wysłać komunikat i odłożyć na stosie nowego odbiorcę komunikatów. Natomiast `end` każe nam odłożyć ze stosu ostatniego odbiorcę (tym samym przywracając poprzedniego). Nie jestem pewien czy w tym momencie jest wysyłany komunikat czy jest to tylko wskazówka dla intepretera, zatem moje umiejscowienie `end` w obszarach jest niejako przypadkowe.

Rzućmy jeszcze okiem na poniższy fragment kodu:

{% highlight ruby %}
puts "1. Object: #{self.class}"

def method
  puts "2. Object.method: #{self.class}"
end

method

class TestClass
  puts "3. Class(TestClass): #{self.class} (#{self.name})"
  
  method

  def method
    puts "4. TestClass.method: #{self.class}"
  end

  def TestClass.method
    puts "5. Class(TestClass).method: #{self.class} (#{self.name})"
  end

  method
end

t = TestClass.new
t.method
TestClass.method
{% endhighlight %}

Wynikiem jego działania jest:

<pre>
$ ruby -w selftests.rb
1. Object: Object
2. Object.method: Object
3. Class(TestClass): Class (TestClass)
2. Object.method: Class
5. Class(TestClass).method: Class (TestClass)
4. TestClass.method: TestClass
5. Class(TestClass).method: Class (TestClass)
</pre>

Zatem widzimy, że to co pisałem wcześniej zasadniczo jest prawdą. 

Zastanawialiście się kiedyś dlaczego metody stworzone poza jakąkolwiek klasą są dostępne we wszystkich klasach, tak jakby były globalne? Tutaj macie odpowiedź (zwróćcie uwagę na wywołania metody na rzecz obiektu `Object`). Ponieważ domyślnym odbiorcą jest `Object` w nim jest tworzona metoda, a ponieważ każdy obiekt w Ruby rozszerza klasę `Object` stąd ma dostęp do metod w nim zdefiniowanych. Czyli mimo iż początkowo wygląda to jako nieobiektowe podejście w gruncie rzeczy jest jak najbardziej obiektowe! Podobnie ma się sprawa z takimi metodami jak `puts` czy `gets`. Niby wygląda na to, że są to jakieś metody globalne ale tak naprawdę to są metody modułu `Kernel` który to jest dołączany do obiektów klasy `Object`.

Możemy pociągnąć temat dalej i zastanowić się nad zmiennymi egzemplarza. Dlaczego zmienne egzemplarza deklarujemy w metodzie `initialize` a nie w ciele klasy (tak jak to jest w Javie)? Dlatego, że w ciele klasy odbiorcą komunikatów jest obiekt `Class` i w nim zostałaby stworzona zmienna! Dla przykładu:

{% highlight ruby %}
class Foo
  @a
  def initialize
    @b
  end
end
{% endhighlight %}

W tym przypadku zmienna `@a` będzie zmienną egzemplarza obiektu `Class` a zmienna `@b` zmienną obiektu `Foo`. **To gdzie co zostanie utworzone nie zależy od tego  w którym miejscu deklaracji się to znajduje, ale kto będzie odbiorcą komunikatu!** Jest to więc można powiedzieć nawet bardziej obiektowe podejście niż na przykład w Javie (widać mówienie, że Ruby to w pełni obiektowy język to nie puszczanie słów na wiatr).

Możemy nawet dla tych atrybutów zadeklarować dyrektywy (które są komunikatami) pamiętając o odpowiednim odbiorcy komunikatu:

{% highlight ruby %}
class Foo
  @a = 5

  class << self
    attr :a, true
  end

  attr :b, true

  def initialize
    @b = 7
  end
end

Foo.a = 1
puts Foo.a

f = Foo.new
f.b =3
puts f.b
{% endhighlight %}

Daje na wyjściu:

<pre>
$ ruby -w class.rb
1
3
</pre>

### Podsumowanie

Ruby to język w dużo większym stopniu obiektowy od takich języków jak Java. Tutaj zasadniczo nie ma deklaracji, są one synonimami wywoływań odpowiednich komunikatów. Zależnie od tego kto jest odbiorcą tego komunikatu wykonywane są jakieś akcie (dodawanie metody, tworzenie instancji klasy itp.). To co pozornie wygląda na metody i zmienne globalne to de facto metody i zmienne dodane do klasy `Object` a ponieważ klasa ta jest rozszerzana przez inne klasy i one mają dostęp do tych metod i zmiennych.

W Rubym zasadniczo nic się nie marnuje. Nawet ciało klasy jest miejscem wykonywalnym gdzie możemy wysyłać komunikaty. Deklaracje jako takie nie istnieją. Pamiętajmy, że nie jest ważne co i gdzie zdefiniowaliśmy, ale kto jest odbiorcą odpowiedniego komunikatu i czy odbiorca ten jest w stanie obsłużyć ten komunikat. To jest istota programowania w Rubym.
