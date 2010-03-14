---
layout: post
title: Behavioral Driven Development z RSpec
description: Behavioral Driven Development to coraz popularniejsza metodyka programowania. Jest to niejako rozwinięcie metody programowania sterowanego testami (ang. Test Driven Development).
keywords: Behavioral Test Driven Development Ruby Rails RSpec programowanie sterowane testami TDD BDD
navbar_pos: 1
---
[Behavioral Driven Development](http://en.wikipedia.org/wiki/Behavior_Driven_Development) to metoda programowania, która
zdobywa ostatnio coraz większą popularność. Jest to niejako rozwinięcie metodyki programowania sterowanego testami
(ang. [Test Driven Development](http://en.wikipedia.org/wiki/Test-driven_development)). Póki co metodyka ta nie dorobiła
się jeszcze polskiego terminu (programowanie sterowane zachowaniami?), stąd będę używał jej angielskiego odpowiednika, albo
skrótu BDD.

Styl ten działa podobnie jak TDD, czyli zanim zaczniemy implementować kod naszego modelu czy logiki biznesowej, musimy
napisać test (w BDD zwany specyfikacją). Pozwoli to nam po pierwsze lepiej zastanowić się nad tym co będziemy implementować (już w tym momencie mogą
wyjść jakieś problemy z naszymi założeniami) a także uzyskać wysokie pokrycie kodu (ang. [code coverage](http://en.wikipedia.org/wiki/Code_coverage)).
Behavioral Driven Development różni się od TDD tym w jaki sposób implementujemy testy. Zamiast nudnych klas i metod testowych definiujemy
specyfikacje obiektów które będziemy implementować. Pozwala to nam w większym stopniu zastanowić się nad ich projektem i zastosowaniem
(niejako efektem ubocznym jest to, że nie wyolbrzymiamy niepotrzebnie interfejsu klasy).

W przypadku języka Ruby i frameworka Rails najpopularniejszym narzędziem wspierającym ten rodzaj programowania jest
[RSpec](http://rspec.info/) (w przypadku aplikacji J2EE możemy użyć narzędzia [easyb](http://www.easyb.org/)). Wpis ten
przedstawia sposób konfiguracji RSpec'a w Rails oraz szkielet prostej aplikacji napisanej w duchu BDD.

# Behavioral Driven Development w akcji

Aplikacja będzie dość ograna (i ograniczona), ale ma ona posłużyć tylko jako przykład. Będzie to prosty blog pozwalający na dodawanie
postów oraz komentarzy do nich. Zakładam, że Ruby i Railsy są już zainstalowane
(podobnie jak i adapter bazy danych SQLite3).

Zaczynamy od stworzenia aplikacji:

    $ rails blog

Kiedy Railsy wygenerują nam strukturę projektu musimy zainstalować wtyczki `rspec` oraz `rspec-rails`:

    $ ruby script/plugin install git://github.com/dchelimsky/rspec.git -r 'refs/tags/1.3.0'
    $ ruby script/plugin install git://github.com/dchelimsky/rspec-rails.git -r 'refs/tags/1.3.2'

Wtyczki te instalują się w katalogu `vendor/plugins/` w naszym projekcie. Teraz musimy "przygotować" naszą aplikację do
pracy z RSpec:

    $ ruby script/generate rspec

Komenda ta przygotuje nam bazową strukturę do pracy z RSpec'em. Co ciekawe wtyczki te rozszerzą nam możliwości skryptów
(np. `generate`) jak i dodadzą nowe zadania dla narzędzia Rake.

## Pierwszy model

Wraz z wtyczką RSpec dostajemy szereg nowych komend do tworzenia modeli czy kontrolerów wraz z odpowiednimi plikami
specyfikacji. Nowe komendy dostępne są oczywiście w ramach skryptu `generate`, a są to: `integration_spec`, `rspec`,
`rspec_controller`, `rspec_model`, oraz `rspec_scaffold`. Stwórzmy zatem rusztowanie dla modelu postu:

    $ ruby script/generate rspec_scaffold post title:string content:string

Nasz model został utworzony oczywiście w `app/models/` natomiast specyfikacja znajduje się w `spec/models/post_spec.rb`.
Nad niczym się nie zastanawiając przechodzimy do tworzenia specyfikacji.

Najpierw wywalamy zawartość naszej specyfikacji, a następnie dodajemy wymaganie, że post nie powinien przechodzić walidacji
jeżeli nie posiada opisu bądź zawartości (oczywiście można to rozbić na dwa wymagania i wielu programistów tak właśnie
by zrobiło).

{% highlight ruby %}
describe Post do

  before :each do
    @post = Post.new
  end

  it "should not be valid if either title or content is blank" do
    @post.should_not be_valid
    @post.should have(1).error_on(:title)
    @post.should have(1).error_on(:content)
  end

end
{% endhighlight %}

Warto zwrócić uwagę na to jak wyglądają testy w RSpec. Narzędzie to wykorzystuje specjalnego [DSL'a](http://en.wikipedia.org/wiki/Domain-specific_language),
czyli języka stworzonego na potrzeby pisania specyfikacji. Należy przyznać, że język ten faktycznie sprawia wrażenie
jakbyśmy opisywali model, a nie wywoływali kolejne metody w teście. Wszystko to sprawia, że pisanie testów (specyfikacji)
jest przyjemniejsze (podobnie zresztą jak czytanie tego).

Czas na uruchomienie testu, ale wcześniej należy uruchomić migracje:

    $ rake db:migrate
    $ rake spec
    (in /home/snc/work/test/blog)
    ............................F

    1)
    'Post should not be valid if title or content is empty' FAILED
    expected #<Post id: nil, title: nil, content: nil, created_at: nil, updated_at: nil> not to be valid

Test oczywiście się nie powiódł (testy, które przeszły to po prostu testy wygenerowane w czasie tworzenia rusztowania).
Oczekiwaliśmy, że nasz model nie przejdzie walidacji a stało się odwrotnie. Nie ma się czemu dziwić, w końcu nie zaimplementowaliśmy
jeszcze walidacji! Przechodzimy do modelu i dodajemy odpowiednie dyrektywy:

{% highlight ruby %}
class Post < ActiveRecord::Base

  validates_presence_of :title, :content

end
{% endhighlight %}

Odpalamy testy:

    $ rake spec
    (in /home/snc/work/test/blog)
    .............................

    Finished in 0.172905 seconds

Działa. Nasza specyfikacja określa, że nasz model wymaga tytułu oraz zawartości, aby można go było zapisać w bazie danych.

Powinniśmy do naszej specyfikacji dodać opis mówiący o tym, że post powinien się zapisać, jeżeli tytuł i zawartość nie
będą puste, a także moglibyśmy się pobawić innymi walidacjami, ale lepiej przejść do nieco bardziej skomplikowanego modelu
jakim jest komentarz.

## Model komentarza

Nasz kolejny model dotyczy komentarzy, które użytkownicy będą mogli zostawiać pod danym postem. Tym razem nie będę tworzył
całego rusztowania, a jedynie sam model:

    $ ruby script/generate rspec_model comment email:string content:string

W tym miejscu odpalamy migracje i do naszej specyfikacji powinniśmy dodać opisy mówiące o tym, że pola `email` i
`content` są wymagane analogicznie jak w przypadku postu. Jednak ja pominę ten etap i przejdę do opisywania relacji pomiędzy
komentarzem a postem.

Wiemy, że komentarz należy do określonego postu, a każdy post może posiadać wiele komentarzy. Na razie jednak nie wiemy
w jaki sposób "zaimplementować" specyfikację. Co jednak gdy chcemy zapisać w naszej specyfikacji odpowiednie wymagania
(chociażby po to aby ich nie zapomnieć) bez implementacji? Okazuje się, że RSpec pozwala nam dodać takie wymagania. Wymagania takie
będą miały stan `Pending` a RSpec wypisze nam w podsumowaniu:

{% highlight ruby %}
describe Post do
  # wcześniejsze wymagania...

  it "should have many comments"
end
{% endhighlight %}

{% highlight ruby %}
describe Comment do
  # wcześniejsze wymagania...

  it "should belongs to one post"
end
{% endhighlight %}

Po uruchomieniu testów otrzymamy:

    $ rake spec
    (in /home/snc/work/test/blog)
    ..............................*..*

    Pending:

    Comment should belongs to one post (Not Yet Implemented)
    ./spec/models/comment_spec.rb:19

    Post should have many comments (Not Yet Implemented)
    ./spec/models/post_spec.rb:20

    Finished in 0.202451 seconds

Możemy tak dodawać kolejne wymagania w miarę jak się one pojawiają, a nie wiemy jeszcze w jaki sposób je zaimplementować.
Zaimplementujmy jednak brakujące wymagania. Prosta implementacja wymagań może sprawdzać, czy odpowiednie relacje są zdefiniowane na odpowiednich klasach:

{% highlight ruby %}
describe Post do
  # wcześniejsze wymagania...

  it "should have many comments" do
    Post.reflect_on_association(:comments).macro.should == :has_many
  end
end
{% endhighlight %}

{% highlight ruby %}
describe Comment do
  # wcześniejsze wymagania...

  it "should belongs to one post" do
    Comment.reflect_on_association(:post).macro.should == :belongs_to
  end
end
{% endhighlight %}

Testy w tym momencie oczywiście nie powinny przejść, ale po zdefiniowaniu odpowiednich relacji powinno już być wszystko w
porządku. Kolejnymi etapami powinno być sprawdzanie dodawania komentarza do postu, walidacja poprawności adresu
email itd. Jednakże widać tu jak prosto z użyciem RSpec'a można tworzyć eleganckie specyfikacje, które jednocześnie
służą nam jako testy.

Oczywiście możliwości RSpec'a nie kończą się na testowaniu modeli. Można testować także i kontrolery, jednakże przedstawienie
tego tutaj wydłużyłoby niemiłosiernie ten wpis, więc pozostawię to na przyszłość.

# Podsumowanie

Behavioral Driven Development to ciekawa metodologia dzięki której nudne pisanie testów zamieniamy w dużo ciekawsze
pisanie specyfikacji. Dzięki świetnemu DSL'owi narzędzie RSpec wspaniale nam w tym zadaniu pomaga. Oczywiście przedstawione
przeze mnie przykłady są dość trywialne i w prawdziwym świecie trzeba by się nieco więcej napracować. Ale ja chciałem tylko
przedstawić samą ideę stojącą za BDD.

Przewagą BDD nad programowaniem sterowanym testami jest właśnie w miarę naturalny język jakim opisuje się testy (specyfikacje).
Język ten pozwala nam pisać testy na wyższym poziomie abstrakcji, przez co jest to łatwiejsze i bardziej naturalne. Nie powiem,
aby RSpec rozwiązywał wszelkie problemy związane z pisaniem testów, ale na pewno sprawia, że pisanie ich jest przyjemniejsze.

Zachęcam do zapoznania się z narzędziem RSpec, a także narzędziem [Cucumber](http://cukes.info/), które przenosi
nasze specyfikacje na jeszcze wyższy poziom abstrakcji. Poziom ten daje nam możliwość pisania testów już momencie
zbierania danych na temat funkcjonalności (poprzez tworzenie [opowieści użytkownika](http://en.wikipedia.org/wiki/User_story)).
Jest to bardzo ciekawa alternatywa, która w pewien sposób godzi jedną z zasad manifestu Agile:

> Working software over comprehensive documentation

Tutaj dostajemy niejako jedno z drugim, takie dwie pieczenie na jednym ogniu. A do tego wspaniałe pokrycie kodu.
