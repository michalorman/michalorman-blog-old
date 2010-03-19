---
layout: post
title: Polymorphic associations w Rails
description: Polymorphic associations to mechanizm wspierany przez Rails pozwalający na modelowanie polimorficznego zachowania rekordów bez dziedziczenia modeli.
keywords: Polymorphic Associations Rails Polimorfizm
navbar_pos: 1
---
Jedyną strategią dziedziczenia wspieraną domyślnie przez Rails jest Single Table Inheritance. Strategia ta zakłada, że
dla całej hierarchii dziedziczenia tworzona jest jedna tabela agregująca wszystkie atrybuty wszystkich modeli wchodzących
w skład tej hierarchii. Czasami jednak nie chcemy modelować dziedziczenia, albo posiadać takiej super tabeli a chcemy
korzystać z polimorficznego zachowania naszych modeli. Do tego celu posłuży nam mechanizm **Polymorphic Associations**.

## Polymorphic Associations

Polimorfizm to paradygmat programowania obiektowego zakładający przeniesienie interfejsu obiektu na wyższy poziom abstrakcji
i możliwą podmianę jego implementacji. Daje to efekt taki, że różne obiekty w tym samym miejscu będą zachowywały się
inaczej. Polimorfizm w odniesieniu do obiektów oznacza, że dany obiekt może być inaczej traktowany w zależności od
kontekstu, natomiast w odniesieniu do metod polimorfizm może oznaczać możliwość wywołania tej samej metody z innymi
argumentami.

W Rails polimorficzne asocjacje są sposobem deklarowania relacji do obiektów dzielących wspólny interfejs, ale mających
różne typy i implementacje. Załóżmy, że nasza aplikacja służy do odtwarzania różnego rodzaju utworów muzycznych albo wideo. Oczywiście
moglibyśmy skorzystać tutaj z STI, ale załóżmy, że z jakiejś przyczyny nie chcielibyśmy tego robić. Nasz model mógłby zatem
wyglądać tak:

{% highlight ruby %}
class Music < ActiveRecord::Base

  def play
    puts content
  end

end
{% endhighlight %}

{% highlight ruby %}
class Video < ActiveRecord::Base

  def play
    puts content
  end

end
{% endhighlight %}

Oba modele dzielą wspólny interfejs i obsługują komunikat ``play``. Potrzebujemy jeszcze modelu, który będzie spinał
wszystkie rodzaje utworów w jedną kolekcję:

{% highlight ruby %}
class Media < ActiveRecord::Base
end
{% endhighlight %}

Teraz moglibyśmy utworzyć tabele ``videos``, ``musics`` oraz ``medias`` i zamodelować relacje tak:

{% highlight ruby %}
class Music < ActiveRecord::Base

  has_one :media

  def play
    puts content
  end

end
{% endhighlight %}

{% highlight ruby %}
class Video < ActiveRecord::Base

  has_one :media

  def play
    puts content
  end

end
{% endhighlight %}

Jednakże takie deklaracje nie działałyby tak jak byśmy sobie tego życzyli. Dyrektywa ``has_one`` w modelach oznacza, że
tabela ``medias`` posiadałaby klucze obce do tabel ``musics`` oraz ``videos`` a to niewiele ma wspólnego z polimorfizmem.
My chcemy posiadać jeden atrybut, czyli de facto jedną relację.

Sztuczka z polymorphic associations polega na tym, że w tabeli spinającej modele tworzymy jedną relację (polimorficzną),
a relację tę reprezentujemy za pomocą dwóch kolumn. Jedna kolumna reprezentuje klucz obcy do innej tabeli, a druga kolumna
określa typ obiektu wskazywanego przez klucz obcy. Zatem jeżeli w naszym modelu ``Media`` relację nazwiemy ``resource``
potrzebować będziemy kolumn ``resource_id`` (stanowiącej klucz obcy relacji), oraz ``resource_type`` (określający typ).

Zadeklarujmy najpierw relację w naszym modelu:

{% highlight ruby %}
class Media < ActiveRecord::Base

  belongs_to :resource, :polymorphic => true

end
{% endhighlight %}

Dyrektywa ``belongs_to`` określa nam, że w tabeli ``medias`` znajduje się klucz obcy relacji, natomiast parametr
``:polymorphic => true`` deklaruje nam, że relacja jest polimorficzna i niema nigdzie modelu ``Resource``. Potrzebujemy
jeszcze odpowiednio zmodyfikować nasze modele ``Music`` oraz ``Video`` tak aby wiedziały one, że klucz obcy będzie
reprezentowany przez ``resource_id`` a nie przez ``music_id`` czy ``video_id``:

{% highlight ruby %}
class Music < ActiveRecord::Base

  has_one :media, :as => :resource

  def play
    puts content
  end

end
{% endhighlight %}

{% highlight ruby %}
class Video < ActiveRecord::Base

  has_one :media, :as => :resource

  def play
    puts content
  end

end
{% endhighlight %}

Pozostaje nam jeszcze zadeklarować migracje tworzące tabele dla naszych modeli:

{% highlight ruby %}
create_table :musics do |t|
  t.string :content

  t.timestamps
end
{% endhighlight %}

{% highlight ruby %}
create_table :videos do |t|
  t.string :content

  t.timestamps
end
{% endhighlight %}

{% highlight ruby %}
create_table :medias do |t|
  # kolumny wspólne
  t.string :title

  # kolumny wymagane przez polimorphic associations
  t.integer :resource_id
  t.string :resource_type

  t.timestamps
end
{% endhighlight %}

Zauważmy, że wspólne atrybuty możemy przenieść do modelu spinającego, który będzie pełnił rolę swoistej klasy bazowej,
jednakże bez dziedziczenia. Deklarujemy także wymagane kolumny.

Po odpaleniu migracji możemy przejść do przetestowania naszego modelu:

{% highlight irb %}
>> music = Music.new(:content => "some music data...")
=> #<Music id: nil, content: "some music data...", created_at: nil, updated_at: nil>
>> media = Media.new(:title => "Music One")
=> #<Media id: nil, title: "Music One", resource_id: nil, resource_type: nil, created_at: nil, updated_at: nil>
>> media.resource = music
=> #<Music id: nil, content: "some music data...", created_at: nil, updated_at: nil>
>> media.save!
=> true
>> video = Video.new(:content => "some video data...")
=> #<Video id: nil, content: "some video data...", created_at: nil, updated_at: nil>
>> media = Media.new(:title => "Video One")
=> #<Media id: nil, title: "Video One", resource_id: nil, resource_type: nil, created_at: nil, updated_at: nil>
>> media.resource = video
=> #<Video id: nil, content: "some video data...", created_at: nil, updated_at: nil>
>> media.save!
=> true
>> Media.all
=> [#<Media id: 2, title: "Music One", resource_id: 2, resource_type: "Music", created_at: "2010-03-19 11:56:16", updated_at: "2010-03-19 11:56:16">, #<Media id: 3, title: "Video One", resource_id: 1, resource_type: "Video", created_at: "2010-03-19 11:56:40", updated_at: "2010-03-19 11:56:40">]
{% endhighlight %}

A teraz test polimorfizmu:

{% highlight irb %}
>> Media.all.each { |m| puts "Playing: #{m.title}: #{m.resource.content}" }
Playing: Music One: some music data...
Playing: Video One: some video data...
{% endhighlight %}

Działa, mamy polimorficzne zachowanie w naszych relacjach bez użycia dziedziczenia.

## Podsumowanie

Technika polymorphic associations pozwala nam na modelowanie polimorficznych zachowań relacji bez użycia dziedziczenia.
Jest to technika nieco bardziej skomplikowana niż STI, ale pozbawiona wad tej drugiej. W pewnym momencie prostota STI
staje się jej wadą (kiedy nasza super tabela rozrasta się za bardzo), stąd warto zastanowić się nad alternatywnym
rozwiązaniem.

Podobnie jak z STI zanim zdecydujemy się na polimorficzne asocjacje musimy zastanowić się czy jest nam to niezbędne, czy
nie wystarczy nam zwyczajna agregacja. Jednak zastosowanie tej techniki nie wiąże nam tak ściśle klas jak STI ponieważ
nie używamy tutaj dziedziczenia.