---
layout: post
title: Anatomia języka Ruby - tworzymy dyrektywy
description: Tworzymy własną dyrektywę dla języka Ruby tworzącą zmienne egzemplarza i metody w konwencji JavaBeans.
keywords: Ruby JavaBeans Module Class Object define_method dyrektywa bean instance_method_get instance_method_set
---
W <a href="http://michalorman.pl/blog/2009/12/anatomia-jezyka-ruby-deklarowanie-metod/">poprzednim poście</a> pisałem o tym w jaki sposób interpreter Ruby dodaje metody do klas. Pokazałem także na jakie sposoby możemy tworzyć metody i to zarówno w momencie pisania kodu jak i podczas działania skryptu. Przyszedł czas aby wykorzystać tę wiedzę w praktyce.

### Dodajemy dyrektywy JavaBeans

Załóżmy, że chcielibyśmy mieć pewne słowo kluczowe (dyrektywę) w języku Ruby, która dla zadanego symbolu stworzyłaby nam zmienną egzemplarza o tej nazwie a także stworzyła metody dla tej zmiennej w konwencji <a href="http://pl.wikipedia.org/wiki/JavaBeans">JavaBeans</a>.  Aby lepiej zrozumieć co chcemy osiągnąć i będąc w zgodzie z praktykami <a href="http://pl.wikipedia.org/wiki/Test-driven_development">TDD</a> napiszmy najpierw test:

{% highlight ruby %}
require 'test/unit'

class TestClass
  bean :foo, :bar
end

class JavaBeansTest < Test::Unit::TestCase
  def testJavaBeans
    cls = TestClass.new
    
    cls.setFoo("foo")
    cls.setBar("bar")

    assert_equal("foo", cls.getFoo)
    assert_equal("bar", cls.getBar)
  end
end
{% endhighlight %}

i odpalmy:

<pre>
$ ruby tc_javabeans.rb
tc_javabeans.rb:4: undefined method `bean' for TestClass:Class (NoMethodError)
</pre>

No dobra, widzimy, że obiekt klasy `Class` który odpowiada za zarządzanie obiektem klasy `TestClass` nie posiada metody `bean`. To by się zgadzało w kontekście tego co pisałem poprzednio iż ciało klasy jest kodem wykonywalnym na rzecz obiektów klasy `Class`. Dodajmy zatem metodę `bean`, jednakże nie dodamy jej w samej klasie `Class` tylko `Module` (którą `Class` rozszerza). Nie mam specjalnie powodów dlaczego tak poza tym, że dyrektywy takie jak `attr_reader` czy `attr_writer` znajdują się właśnie w klasie `Module` więc dla porządku i my tam swoją zdefiniujmy.

{% highlight ruby %}
class Module
  def bean(*symbols)
  end
end
{% endhighlight %}

Do parametru `symbols` pobieramy wszystkie symbole w postaci tablicy. Teraz odpalmy nasz test:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
E
Finished in 0.000727 seconds.

  1) Error:
testJavaBeans(JavaBeansTest):
NoMethodError: undefined method `setFoo' for #&lt;TestClass:0xb7685d50&gt;
    tc_javabeans.rb:12:in `testJavaBeans'

1 tests, 0 assertions, 0 failures, 1 errors
</pre>

Jak należało się spodziewać, nie mamy metody `setFoo`. Zatem musimy dodać ją w czasie wykonywania metody `bean` zgodnie z tym co pisałem w poście o deklarowaniu metod, czyli wykorzystamy do tego celu komunikat `define_method` pamiętajmy tylko iż musimy go wysłać do odpowiedniej klasy. Jeżeli wywołalibyśmy ten komunikat tak:

{% highlight ruby %}
def bean(*symbols)
  define_method(...) { ... }
end
{% endhighlight %}

poskutkowałoby to dodaniem metody ale do klasy `Module` a przecież nie o tę klasę nam chodzi. Możemy jednak uzyskać referencję do naszej klasy wykorzystując `self`. Zatem to co musimy zrobić to iterować po wszystkich symbolach i dla każdego wysłać komunikat `create_method` do `self` z odpowiednio sformatowaną nazwą metody - prościzna! Zatem do roboty:

{% highlight ruby %}
class Module
  def bean(*symbols)
    symbols.each do |s|
      self.send(:define_method, "set#{s.to_s.capitalize}") do
      end
    end
  end
end
{% endhighlight %}

I uruchamiamy test:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
E
Finished in 0.000407 seconds.

  1) Error:
testJavaBeans(JavaBeansTest):
NoMethodError: undefined method `getFoo' for #&lt;TestClass:0xb77b29f8&gt;
    tc_javabeans.rb:15:in `testJavaBeans'

1 tests, 0 assertions, 0 failures, 1 errors
</pre>

Teraz brakuje nam metody `getFoo`, zatem analogicznie dodajemy jej tworzenie:

{% highlight ruby %}
class Module
  def bean(*symbols)
    symbols.each do |s|
      self.send(:define_method, "set#{s.to_s.capitalize}") do
      end
      self.send(:define_method, "get#{s.to_s.capitalize}") do
      end
    end
  end
end
{% endhighlight %}

Test:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
F
Finished in 0.035466 seconds.

  1) Failure:
testJavaBeans(JavaBeansTest) [tc_javabeans.rb:15]:
&lt;"foo"&gt; expected but was
&lt;nil&gt;.

1 tests, 1 assertions, 1 failures, 0 errors
</pre>

No proszę wydaje się, że już jesteśmy prawie w domu. Metoda `getFoo` zamiast "foo" zwróciła `nil` co w cale nie dziwi skoro ta metod w ogóle nic nie zwraca. Pozostaje tylko pytanie jak mamy dodać zmienną egzemplarza z symbolu? Szybkie zasięgnięcie rady u wujka Google i najlepszym kandydatem staje się metoda `instance_variable_get` klasy `Object`. Zwraca ona wartość zmiennej egzemplarza o nazwie odpowiadającej symbolowi podanemu w parametrze, czyli dokładnie to o co nam chodzi, musimy jedynie dodać znak '@' przed nazwą naszego symbolu, aby jego nazwa była akceptowalna jako nazwa zmiennej egzemplarza. Wypróbujmy to czym prędzej:

{% highlight ruby %}
class Module
  def bean(*symbols)
    symbols.each do |s|
      self.send(:define_method, "set#{s.to_s.capitalize}") do
      end
      self.send(:define_method, "get#{s.to_s.capitalize}") do
        self.instance_variable_get("@#{s.to_s}")
      end
    end
  end
end
{% endhighlight %}

Uruchamiamy test:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
F
Finished in 0.006118 seconds.

  1) Failure:
testJavaBeans(JavaBeansTest) [tc_javabeans.rb:15]:
&lt;"foo"&gt; expected but was
&lt;nil&gt;.

1 tests, 1 assertions, 1 failures, 0 errors
</pre>

Dalej otrzymujemy `nil` ale wygląda na to, że nasza zmienna została dodana do klasy a `nil` wynika z tego, że nasz setter jeszcze jej nie ustawia. Trzeba to zmienić. Najlepszym kandydatem do tego celu jest komunikat `instance_variable_set` klasy `Object` z tym, że mamy jeden problem, jaką wartość ustawić naszej zmiennej? Przecież nie zdefiniowaliśmy żadnych parametrów dla naszego settera! No i jak się w ogóle to robi? Dokumentacja metody `define_method` nam w tym nie pomaga, bo o parametrach nie wspomina nawet słowem. Ale jesteśmy w końcu ludźmi inteligentnymi, więc zdajmy się na naszą intuicję i trochę podedukujmy. Metoda `define_method` tworzy nową metodę. Blok skojarzony z wywołaniem tej metody będzie użyty jako ciało nowo stworzonej metody. Zatem zakładając, że wywołanie naszej nowej metody posiada parametry w jaki sposób przekazać je do bloku? Odpowiedź jest oczywista, przez parametr bloku. Zatem wypróbujmy to podejście:

{% highlight ruby %}
class Module
  def bean(*symbols)
    symbols.each do |s|
      self.send(:define_method, "set#{s.to_s.capitalize}") do |arg|
        self.instance_variable_set("@#{s.to_s}", arg)
      end
      self.send(:define_method, "get#{s.to_s.capitalize}") do
        self.instance_variable_get("@#{s.to_s}")
      end
    end
  end
end
{% endhighlight %}

Uruchamiamy testy:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
.
Finished in 0.000386 seconds.

1 tests, 2 assertions, 0 failures, 0 errors
</pre>

Wygląda na to, że działa, ale dodajmy jeszcze jeden test weryfikujący nasze rozwiązanie z parametrami settera:

{% highlight ruby %}
require 'javabeans'
require 'test/unit'

class TestClass
  bean :foo, :bar;
end

class JavaBeansTest < Test::Unit::TestCase
  def testJavaBeans
    cls = TestClass.new
    
    cls.setFoo("foo")
    cls.setBar("bar")

    assert_equal("foo", cls.getFoo)
    assert_equal("bar", cls.getBar)
    assert_raise(ArgumentError) { cls.setFoo("foo", "bar") }
  end
end
{% endhighlight %}

Uruchamiamy:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
./javabeans.rb:4: warning: multiple values for a block parameter (2 for 1)
  from tc_javabeans.rb:17
F
Finished in 0.007022 seconds.

  1) Failure:
testJavaBeans(JavaBeansTest) [tc_javabeans.rb:17]:
&lt;ArgumentError&gt; exception expected but none was thrown.

1 tests, 3 assertions, 1 failures, 0 errors
</pre>

Wyjątek nie został rzucony? Dlaczego? Ano dlatego, że zapis `"foo", "bar"` Ruby zinterpretował jako tablicę dwuelementową, czyli parametr był jak najbardziej prawidłowy (w końcu tablica to argument jak najbardziej akceptowalny przez settery). Zatem zmieńmy nasz test celem udowodnienia tej tezy:

{% highlight ruby %}
require 'javabeans'
require 'test/unit'

class TestClass
  bean :foo, :bar;
end

class JavaBeansTest < Test::Unit::TestCase
  def testJavaBeans
    cls = TestClass.new
    
    cls.setFoo("foo")
    cls.setBar("bar")

    assert_equal("foo", cls.getFoo)
    assert_equal("bar", cls.getBar)

    cls.setFoo("foo", "bar")
    assert_equal(["foo", "bar"], cls.getFoo)

    assert_raise(ArgumentError) { cls.setFoo(1, 2) }
  end
end
{% endhighlight %}

Uruchamiamy i:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
./javabeans.rb:4: warning: multiple values for a block parameter (2 for 1)
  from tc_javabeans.rb:18
./javabeans.rb:4: warning: multiple values for a block parameter (2 for 1)
  from tc_javabeans.rb:21
F
Finished in 0.006909 seconds.

  1) Failure:
testJavaBeans(JavaBeansTest) [tc_javabeans.rb:21]:
&lt;ArgumentError&gt; exception expected but none was thrown.

1 tests, 4 assertions, 1 failures, 0 errors
</pre>

Niestety wyjątek dalej nie został rzucony a co ciekawe Ruby generuje nam tylko ostrzeżenia o niewłaściwej liczbie parametrów przekazanych do bloku. Wynika z tego, że interpreter Ruby inaczej zachowuje się przekazując parametry do metody inaczej do bloku (w tym pierwszym przypadku jest bardziej restrykcyjny). Dodam także, że używałem Ruby'ego w wersji 1.8 nie jestem pewien czy tak samo to wygląda w wersji 1.9 (ale sprawdzę). 

Aby rozwiązać powyższy problem musimy w inny sposób zadeklarować metodę w czasie wykonania. Inny sposób to wykorzystanie metody `module_eval` która to wykonuje kod podany w argumencie w postaci ciągu znaków tak jakby był to kod dołączony do pliku. Moglibyśmy zmienić nasz kod na następujący:

{% highlight ruby %}
class Module
  def bean(*symbols)
    symbols.each do |s|
      module_eval <<-END
        def set#{s.to_s.capitalize}(arg)
          self.instance_variable_set("@#{s.to_s}", arg)
        end
        def get#{s.to_s.capitalize}
          self.instance_variable_get("@#{s.to_s}")
        end
      END
    end
  end
end
{% endhighlight %}

Poprawmy jeszcze testy:

{% highlight ruby %}
require 'javabeans'
require 'test/unit'

class TestClass
  bean :foo, :bar;
end

class JavaBeansTest < Test::Unit::TestCase
  def testJavaBeans
    cls = TestClass.new
    
    cls.setFoo("foo")
    cls.setBar("bar")

    assert_equal("foo", cls.getFoo)
    assert_equal("bar", cls.getBar)
    
    assert_raise(ArgumentError) { cls.getFoo("foo", "bar") }
    assert_raise(ArgumentError) { cls.setFoo(1, 2) }
    assert_raise(ArgumentError) { cls.setFoo }
  end
end
{% endhighlight %}

odpalamy:

<pre>
$ ruby tc_javabeans.rb
Loaded suite tc_javabeans
Started
.
Finished in 0.000758 seconds.

1 tests, 5 assertions, 0 failures, 0 errors
</pre>

Teraz wszystko działa tak jak powinno :).

### Podsumowanie

Ruby pozwala nam dodawać metody do klas na wiele sposobów. Jest to możliwe dlatego, że dodawanie metod polega na wysłaniu odpowiedniego komunikatu do obiektu klasy. Co ciekawe ręczne wywołanie komunikatu dodającego metodę powoduje subtelne różnice w działaniu metody pojawiające się z powodu różnicy z jaką interpreter traktuje parametry metody i parametry bloku. Dlatego zdecydowanie lepszym rozwiązaniem jest wykorzystanie metod `eval` lub `module_eval`, które podany ciąg znaków potraktują jak zwyczajny kod napisany przez programistę. Metody te można też wykorzystywać do aktualizowania działających systemów bez potrzeby ich wyłączania albo do uruchamiania pluginów. W każdym razie sposób ten otwiera przed nami nieograniczone możliwości rozszerzania naszych klas w czasie działania aplikacji.