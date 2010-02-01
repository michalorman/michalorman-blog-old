---
layout: post
title: Anatomia języka Ruby - wyrażenia, wyrażenia...
description: Jakie możliwości i konsekwencje daje w języku Ruby to, że niemal wszystko jest wyrażeniem.
keywords: Ruby wyrażenia zmienna tablica warunek logiczny
---
No i mamy nowy rok 2010. Pozostały nam tylko jeszcze <a href="http://www.orion2012.pl/patrick_geryl">dwa do końca świata</a> ;). W każdym razie święta się skończyły czas wziąć się za robotę. 

Wolne upłynęło mi pod znakiem Rubie-go i <a href="http://rubyonrails.pl/">Railsów</a> i o tym pierwszym chciałem napisać mój pierwszy post w nowym roku. Konkretnie chciałem przedstawić kilka ciekawych sztuczek jakie znajdują się w tym języku a nie ma ich np. w Javie (zasadniczo nie wiem w jakich jeszcze językach takie rzeczy istnieją, ale to nieistotne ;)).

Wyrażenia to jedna z cech która wyróżnia język Ruby. To co może zwracać rozsądną wartość robi to! W języku tym prawie wszystko jest wyrażeniem w odróżnieniu do języka C czy Javy, gdzie wiele rzeczy jest instrukcjami (zaraz zobaczymy o co konkretnie mi chodzi i jakie to ma konsekwencje).

Jedna z oczywistych rzeczy, wynikająca z bycia wyrażeniem, jest możliwość łączenia wyrażeń w łańcuchy:

<pre>
irb(main):001:0> a = b = c = d = 1
=> 1
irb(main):002:0> [7, 3, 0, 1].sort.reverse
=> [7, 3, 1, 0]
</pre>

Jednakże powyższe przykłady nie robią na nikim wrażenia, przejdźmy zatem do bardziej ciekawych konstruktów.

### Przypisania równoległe

Przypisanie to jedna z najczęstszych operacji wykonywana w każdym programie. Często też programiści muszą naklepać się sporo w klawiaturę, aby wykonać proste przypisania. Składnia języka Ruby pozwala nam nieco usprawnić ten proces pozwalając na równoległe przypisania. Równoległe przypisanie jest to przypisanie wielu tzw. <i>r-wartości</i> do wielu <i>l-wartości</i> w jednym wyrażeniu:

<pre>
irb(main):003:0> a, b = 1, 2
=> [1, 2]
irb(main):004:0> a
=> 1
irb(main):005:0> b
=> 2
</pre>

Co ciekawe Ruby daje nam z pomocą przypisań równoległych więcej ciekawych możliwości niż tylko zaoszczędzenie paru uderzeń w klawiaturę. Weźmy na przykład prosty kod zamieniający wartości dwóch zmiennych napisany np. w Javie:

{% highlight java %}
int a = 2, b = 3, tmp;
tmp = b;
b = a;
a = tmp;
{% endhighlight %}

Moglibyśmy pozbyć się zmiennej `tmp` wykorzystując <a href="http://en.wikipedia.org/wiki/XOR_swap_algorithm">trik z operatorem XOR</a>. Ten sam kod w Ruby wyglądałby tak:

{% highlight ruby %}
a, b = 2, 3
a, b = b, a
{% endhighlight %}

Co ciekawe jeżeli równolegle spróbujemy przypisać tablice to poszczególne elementy zostaną równolegle przypisane kolejnym zmiennym:

<pre>
irb(main):019:0> a = [1, 2, 3]
=> [1, 2, 3]
irb(main):020:0> b, c = a
=> [1, 2, 3]
irb(main):021:0> b
=> 1
irb(main):022:0> c
=> 2
</pre>

Powyższe wyrażenie jest nieco dziwaczne, ponieważ w tym przypadku tablica została rozłożona na poszczególne elementy - <i>r-wartości</i> - które dalej były równolegle przypisywane do zmiennych - <i>l-wartości</i>. Nadmiarowe <i>r-wartości</i> zostały pominięte. Jednakże, gdybyśmy chcieli nie pomijać <i>r-wartości</i> moglibyśmy przed ostatnim elementem postawić gwiazdkę:

<pre>
irb(main):023:0> b, *c = a
=> [1, 2, 3]
irb(main):024:0> b
=> 1
irb(main):025:0> c
=> [2, 3]
</pre>

Teraz wartość 3 nie została pominięta a ostatnie wartości zostały w postaci tablicy przypisane zmiennej `c`. 

Na ilość <i>r-wartości</i> naprawdę trzeba uważać:

<pre>
irb(main):029:0> b, c = 4, a
=> [4, [1, 2, 3]]
irb(main):030:0> b
=> 4
irb(main):031:0> c
=> [1, 2, 3]
</pre>

Tutaj należy zauważyć brak gwiazdki przed `c`. W tym przypadku zmienna `a` nie została rozłożona jako tablica na poszczególne <i>r-wartości</i> ale w całości została przypisana zmiennej `c`. Tak naprawdę rozkład tablicy następuje jedynie, kiedy jest ona jedyną <i>r-wartością</i> w przypisaniu równoległym (czyli uwzględniającym więcej niż jedną <i>l-wartość</i>):

<pre>
irb(main):032:0> b, c, d = 4, a
=> [4, [1, 2, 3]]
irb(main):033:0> b
=> 4
irb(main):034:0> c
=> [1, 2, 3]
irb(main):035:0> d
=> nil
</pre>

Tutaj warto zauważyć, że <i>l-wartości</i> nie posiadające odpowiadających <i>r-wartości</i> mają wartość `nil`.

<pre>
irb(main):036:0> b, c, d = a
=> [1, 2, 3]
irb(main):037:0> b
=> 1
irb(main):038:0> c
=> 2
irb(main):039:0> d
=> 3
</pre>

### Przypisanie zagnieżdżone

Aby jeszcze zamotać sposób przypisywania Ruby pozwala na grupowanie <i>l-wartości</i>. Formalnie nazywa się to wtrąceniem. Odpowiednie <i>r-wartości</i> są wyłuskiwane i przypisywane do tych zmiennych. Wtrącenie realizuje się poprzez ujęcie zmiennych w nawias. Ponieważ trudno jest mi wytłumaczyć na czym to polega zobaczmy jak wygląda to na przykładzie:

<pre>
b, (c, d), e = 1, 2, 3, 4         → b == 1, c == 2, d == nil, e == 3
b, (c, d), e = [1, 2, 3, 4]       → b == 1, c ==2, d == nil, e == 3
b, (c, d), e = 1, [2, 3], 4       → b == 1, c == 2, d == 3, e == 4
b, (c, d), e = 1, [2, 3, 4], 5    → b == 1, c == 2, d == 3, e == 5
b, (c, *d), e = 1, [2, 3, 4], 5   → b == 1, c == 2, d == [3, 4], e == 5
</pre>

Ciekawe jest to, że tablica odpowiadająca wtrąceniu jest przypisywana osobno od głównego przypisania. Można powiedzieć, że są tutaj realizowane 2 przypisania na raz. Szczerze powiedziawszy nie spotkałem się jeszcze z praktycznym zastosowaniem tego tworu i jakoż nie mogę go sobie wyobrazić, ale kto wie :P.

### Wyrażenia warunkowe

Tak tak, to nie pomyłka. <b>Wyrażenie warunkowe</b> nie <b>instrukcje warunkowe</b> (ciekaw jest ile osób to czytających w ogóle zwróciło na to uwagę ;)). W Rubym instrukcje `if`, `unless` oraz `case` mogą zwracać wartość co czyni je wyrażeniami. Wartość przez nie zwracana to ostania przetworzona wartość w odpowiednim bloku:

<pre>
irb(main):054:0> a = if true then 3 else 4 end
=> 3
irb(main):055:0> a
=> 3
irb(main):056:0> a = if false then 3 else 4 end
=> 4
irb(main):057:0> a
=> 4
</pre>

### Wartość wyrażeń logicznych

Ruby ma ciekawą właściwość dotyczącą operatorów logicznych. Wiadomym jest, że operatory logiczne zwracają prawdę lub fałsz. W przypadku Ruby jednak operatory te zwracają pierwszą wartość, która determinuje prawdę lub fałsz w warunku. W Rubym fałsz oznaczany jest przez `false` lub `nil` (tutaj jest mała pułapka dla programistów C/C++ 0 to jest w Rubym prawda a nie fałsz). Jest to chyba najbardziej praktyczne "dziwaczne" wyrażenie (i chyba najczęściej stosowane). Zobaczmy jak to wygląda:

<pre>
irb(main):064:0> nil and true
=> nil
irb(main):065:0> nil or true
=> true
irb(main):066:0> false and true
=> false
irb(main):067:0> false or true
=> true
irb(main):068:0> nil and 0
=> nil
irb(main):069:0> nil or 0
=> 0
irb(main):070:0> false and 0
=> false
irb(main):071:0> false or 0
=> 0
irb(main):072:0> 0 and "kot"
=> "kot"
irb(main):073:0> 0 or "kot"
=> 0
irb(main):076:0> "kot" and nil
=> nil
irb(main):077:0> "kot" or nil
=> "kot"
</pre>

Pamiętajmy, że w wyrażeniu `and` gdy pierwszy operand jest fałszem to całe wyrażenie jest fałszem, natomiast w przypadku operatora `or` gdy pierwszy operand jest prawdą to całe wyrażenie jest prawdą. Bardzo często ta właściwość języka jest wykorzystywana, np:

{% highlight ruby %}
map[:key] ||= []
map[:key] << "value"
{% endhighlight %}

Powyższy kod jest równoważny temu:

{% highlight ruby %}
map[:key] = map[:key] || []
map[:key] << "value"
{% endhighlight %}

Działa on tak. Najpierw jest pobierana wartość z mapy `map` pod kluczem `:key` jeżeli znajduje się tam wartość `nil` (lub `false`) to pod ten klucz przypisywana jest pusta tablica do której następnie jest dodawana wartość `"value"`. W przypadku gdy pod tym kluczem znajduje się już jakaś tablica ona jest zwracana. Ten kod można by zapisać tak;

{% highlight ruby %}
if map[:key].nil?
  map[:key] = []
end
map[:key] << "value"
{% endhighlight %}

Ale można go także skrócić do:

{% highlight ruby %}
(map[:key] ||= []) << "value"
{% endhighlight %}

Z operatorami logicznymi trzeba jednak uważać, gdyż jest z nimi związana pewna pułapka. Mianowicie chodzi o kolejność wykonywania operatorów. Okazuje się, że w Ruby operatory `||` i `&&` oraz `or` i `and` mimo iż tożsame mają inne priorytety. Te pierwsze wykonywane są przed operatorem przypisania te drugie po, co może skutkować na przykład czymś takim:

<pre>
irb(main):084:0> foo = nil
=> nil
irb(main):085:0> bar = "not nil"
=> "not nil"
irb(main):086:0> baz = foo or bar
=> "not nil"
irb(main):087:0> baz
=> nil
irb(main):088:0> baz = foo || bar
=> "not nil"
irb(main):089:0> baz
=> "not nil"
</pre>

Jak widać powyżej mimo iż operacje te same wyniki są różne, ponieważ `or` zostało wykonane po operatorze przypisania natomiast `||` przed. Zatem należy pamiętać, że jeżeli chcemy skorzystać z wartości zwracanej przez operatory logiczne przypisując ją do zmiennej powinniśmy zawsze korzystać z operatorów `||` i `&&` ewentualnie odpowiednio dodać nawiasy (co by nie było wątpliwości).

### Podsumowanie

W języku Ruby wszystko co może zwracać sensowną wartość robi to. Innymi słowy prawie wszystko jest wyrażeniem (w odróżnieniu od innych języków gdzie są to instrukcje). Twory te można oczywiście wykorzystywać do robienia zgrabniejszego kodu, ale mogą zostać wykorzystane w niecnych celach aby kod zagmatwać. Można się ich na początku bać (zwłaszcza programiści Javy czują się jakoś poruszeni tymi potworkami), ale prawdę mówiąc szybko dochodzi się do tego, że wyrażenia te są proste i dość naturalne. Wręcz wzrokowo rozpoznaje się miejsca gdzie one występują i jaki będzie wynik wyrażenia. Jak ze wszystkim należy z nich korzystać z rozwagą i wyczuciem, to są tylko narzędzia które mogą pomagać i utrudniać pracę.

Część przytoczonych tu przykładów została zaczerpnięta z książek "Programowanie w języku Ruby" D. Thomasa, C. Fowlera i A. Hunta oraz "RailsSpace: Tworzenie Społecznościowych serwisów internetowych w Ruby on Rails" M. Hartl'a oraz A. Prochazka.