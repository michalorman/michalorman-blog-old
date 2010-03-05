---
layout: post
title: Anatomia języka Ruby - deklarowanie metod
description: W jaki sposób w języku Ruby dodawane są metody i na jakie sposoby można je dodawać nawet w czasie wykonywania skryptu.
keywords: Ruby TDD BDD Metoda Klasa Object Class Module define_method send test behavioral driven development
---
Ostatnimi czasy postanowiłem odetchnąć nieco od platformy Java i nauczyć się wreszcie jakiegoś języka skryptowego. Kiedyś bawiłem się Perlem, ale nie sprawiało mi to specjalnej frajdy tak więc wybór padł na język Ruby. Python będzie musiał jeszcze poczekać, a Groovy należy do platformy Java do której nie chcę się szufladkować.

Muszę przyznać, że jestem językiem Ruby zafascynowany. Lekkość i swoistą naturalność pisania kodu jaką on mi daję jest doprawdy imponująca. Widać, że jest to język który zaprojektowany był z myślą o ułatwianiu życia programistom w przeciwieństwie do skostniałego języka Java, który swoimi ograniczeniami komplikuje pisanie kodu. Co ciekawe takie praktyki jak TDD czy BDD (o tak!) przyszły mi w tym języku wręcz same z siebie, gdzie w języku Java uważam pisanie testów za uciążliwe.

Zdaję sobie również sprawę, że każdy język i platforma ma swoje zastosowanie, dlatego daleki jestem od twierdzenia, że Ruby jest lepszy od Javy. Są to zupełnie inne języki do zupełnie innych zastosowań dlatego nie będę ich porównywał (no może poza jakimiś smaczkami składniowymi :)).

Ale do rzeczy...

### Literały i wyrażenia

Ruby posiada ogromną ilość literałów i wyrażeń. Dla programistów Javy z pewnością nie do pomyślenia jest, że instrukcje `if` czy `while` mogą być wyrażeniami (czyli zwracać wartość). Podobnie uważam za wielki minus języka Java, że posiada tak mało literałów a szczególnie brakuje mi literałów do tworzenia map i wyrażeń regularnych. Język Ruby oferuje nam pod tym względem więcej.

Co ciekawe w pierwszej chwili dla programistów Javy czy C++ bardzo dziwne jest to, że definicja klasy w języku Ruby jest kodem wykonywalnym (no dobra, może nie od pierwszej chwili bo raczej nie dowiemy się togo na początku nauki języka ;)). Pewnie każdy programista Javy pomyślał sobie teraz to co ja sobie pomyślałem:

> Co to do cholery znaczy, że definicja klasy jest kodem wykonywalnym?

Ano oznacza to ni mniej ni więcej tyle, że interpreter Ruby analizuje definicję klasy i na przykład wywołuje metody. Co dziwniejsze nie chodzi tutaj o wywoływanie metod na rzecz instancji naszego obiektu (tak jakby to miało miejsce w statycznych blokach inicjalizacyjnych Javy) ale na rzecz instancji klasy `Class`. Instancja takiej klasy tworzona jest dla każdej definicji klasy którą deklarujemy słowem kluczowym `class` i służy do stworzenia i zainicjalizowania naszego obiektu. 

Brzmi to trochę pokrętnie i trzeba trochę nad tym posiedzieć aby to zrozumieć (ja musiałem), jednak kiedy się to zrozumie to dochodzi do nas jakie taka funkcjonalność daje nam możliwości. Możemy np. tworzyć dyrektywy dla klas, które wyglądałyby jak słowa kluczowe, przez co moglibyśmy stworzyć swoistego DSL-a do jakiegoś konkretnego problemu. Takimi dyrektywami są np: `attr_reader` i `attr_writer` tworzące metody do odczytu i zapisu zmiennej egzemplarza. To są tak naprawdę metody klasy `Module`, którą rozszerza `Class` a ponieważ w Rubym możemy wywoływać metody bez nawiasów takie wyrażenia faktycznie wyglądają jak słowa kluczowe języka:

{% highlight ruby %}
class Foo
  attr_reader :foo, :bar
end
{% endhighlight %}

### Deklaracja metod

Aby w skrypcie stworzyć metodę używamy słowa kluczowego `def` np:

{% highlight ruby %}
def foo
  puts "in foo!"
end
{% endhighlight %}

Mówiłem wcześniej, że interpreter Ruby doda taką metodę do klasy, ale przecież powyższa deklaracja nie deklaruje żadnej klasy! O co chodzi? Spokojnie, nie kłamałem. Tak naprawdę powyższa metoda zostanie dodana do klasy `Object` przez co będzie dostępna we wszystkich klasach co sprawia wrażenie, że jest to metoda globalna (a jednak nią nie jest). Co jednak oznacza stwierdzenie "dodana do klasy `Object`"? Przecież nie otwieraliśmy tutaj definicji klasy `Object`. No i w jaki sposób zostaje ona dodana?

Otóż okazuje się, że dla każdego typu interpreter Ruby tworzy sobie instancję klasy `Class`. Instancja ta odpowiada za "obsługę" konkretnego typu, czyli tworzenie instancji obiektów konkretnego typu czy obsługę komunikatów. Każda instancja klasy `Class` odpowiada za jeden typ a obsługiwane komunikaty są unikalne dla każdej instancji stąd do każdego obiektu możemy wysłać dowolny komunikat, ale nie musi on zostać przez niego obsłużony. Jak zatem zdefiniować, aby instancja obiektu `Class` obsługiwała komunikat? No jak to jak, wysyłając odpowiedni komunikat do instancji `Class`!

Z polskiego na nasze obiekty klasy `Class` obsługują komunikat który definiuje, że dany obiekt ma odpowiadać na dany komunikat. Deklaracja metody za pomocą `def` jest zakulisowo zamieniana na wywołanie metody obiektu `Class` dodającego obsługę metody. Stąd jasne jest dlaczego tak łatwo dodawać nowe metody do dowolnych klas w języku Ruby. Po prostu wysyłamy odpowiedni komunikat do odpowiedniego obiektu `Class`. Wiedząc to pozostało nam tylko zidentyfikowanie stosownego komunikatu.

Tak po prawdzie komunikat ten nie znajduje się w samej klasie `Class` a `Module` którą ta rozszerza. Komunikat ten nazywa się `define_method`. Komunikat ten tworzy metodę w obiekcie odbiorcy i przekazuje sterowanie albo do obiektu `Proc` albo do bloku kodu skojarzonego z wywołaniem metody `define_method`.

Oznacza to tyle, że zadeklarować metodę możemy na dwa sposoby, albo za pomocą komunikatu `define_method` albo słowem kluczowym `def` (który za kulisami wywoła komunikat `define_method`). Zobaczmy na ten przykład:

{% highlight ruby %}
class Foo
end

f = Foo.new

begin
  f.foo
rescue NoMethodError
  puts "nie ma metody foo!"
end

class Foo
  define_method("foo") { puts "w metodzie foo!" }
end

f.foo
{% endhighlight %}

Da on na wyjściu:

{% highlight bash %}
nie ma metody foo!
w metodzie foo!
{% endhighlight %}

Co jednak jeżeli chcielibyśmy dodać metodę w czasie wykonania programu? Moglibyśmy zrobić na przykład coś takiego:

{% highlight ruby %}
class Foo
  def foo
    puts "w metodzie foo!"
    define_method("bar") do
      puts "w metodzie bar!"
    end
  end
end

f = Foo.new

begin
  f.bar
rescue NoMethodError
  puts "nie ma metody bar!"
end

f.foo
f.bar
{% endhighlight %}

Jednakże to da nam na wyjściu:

{% highlight bash %}
nie ma metody bar!
w metodzie foo!
foo.rb:4:in `foo': undefined method `define_method' for #<Foo:0xb78a4834> (NoMethodError)
  from foo.rb:18
{% endhighlight %}

Problem polega na tym, że powyższy przykład wywołuje metodę `define_method` na rzecz instancji klasy `Foo` a ta nie deklaruje takiej metody! Jest to bardzo częsty błąd początkujących programistów Ruby. Metodę tę musimy wywołać na rzecz obiektu `Class`, zatem przeróbmy kod aby tak było:

{% highlight ruby %}
class Foo
  def foo
    puts "w metodzie foo!"
    self.class.define_method("bar") do
      puts "w metodzie bar!"
    end
  end
end

f = Foo.new

begin
  f.bar
rescue NoMethodError
  puts "nie ma metody bar!"
end

f.foo
f.bar
{% endhighlight %}

Na wyjściu dostajemy:

{% highlight bash %}
nie ma metody bar!
w metodzie foo!
foo.rb:4:in `foo': private method `define_method' called for Foo:Class (NoMethodError)
  from foo.rb:18
{% endhighlight %}

Że co? Metoda `define_method` jest prywatna? Ano jest prywatna. Dlatego możemy tę metodę wywołać w samej definicji klasy ale nie możemy wywołać jej w jej metodach (bo to już jest definicja innej klasy). Można to sobie wyobrazić tak: ciało metody `foo` należy do definicji klasy `Foo` jednak ciało samej klasy `Foo` należy do definicji klasy `Class` tak jakby to była metoda tej klasy i dlatego tam możemy wywoływać metodę `define_method` a w metodach klasy już nie. 

Jednakże możemy użyć swoistego fortelu i wykorzystać komunikat `send` który pozwala wysłać dowolny komunikat do obiektu i zostanie on obsłużony nawet jeżeli ten komunikat jest prywatny. Co ciekawe API tego komunikatu (zadeklarowanego w klasie `Object`) nic o tym nie mówi, więc nie wiem czy traktować to jako bug czy jako feature. Trzeba się zatem liczyć, że wraz z kolejnymi wersjami języka Ruby funkcjonalność ta może przestać działać.

Zatem poprawiona wersja naszej klasy wyglądałaby tak:

{% highlight ruby %}
class Foo
  def foo
    puts "w metodzie foo!"
    self.class.send(:define_method, "bar") do
      puts "w metodzie bar!"
    end
  end
end

f = Foo.new

begin
  f.bar
rescue NoMethodError
  puts "nie ma metody bar!"
end

f.foo
f.bar
{% endhighlight %}

I wyjście:

{% highlight bash %}
nie ma metody bar!
w metodzie foo!
w metodzie bar!
{% endhighlight %}

No i jesteśmy w domu dodaliśmy metodę w czasie wykonywania skryptu! :)

### Podsumowanie

Mimo iż to dopiero początek mojego poznawania języka Ruby już teraz wywarł on na mnie wielkie wrażenie. Programy w nim pisane są zgrabniejsze, krótsze i powstają szybciej przez co programuje się naprawdę przyjemnie. Takie metodyki jak TDD i BDD niemal w naturalny sposób przychodzą wraz z tym językiem.

W języku Ruby wszystko jest obiektem. Nawet jeżeli tego nie widać to tak jest. Pozornie zdefiniowanie metody globalnej to tak naprawdę dodanie metody do klasy `Object`. Pozornie dziwne deklaracje i dyrektywy to tak naprawdę wywołania metod na innych obiektach. Wszystko to dzieje się jednak w większości w interpreterze toteż programista nie musi sobie specjalnie tym zawracać głowy. Co ciekawe dodanie metody do klasy robi się poprzez wywołanie metody (wysłanie komunikatu) do instancji klasy `Class`, która odpowiada za zarządzanie naszym typem. Stąd też dodanie nowych metod nawet do istniejących klas czy to w czasie kodowania czy w czasie wykonywania skryptu jest banalnie proste.