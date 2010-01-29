---
layout: post
title: Migracja bloga z Wordpress na Jekyll
categories: [Blog]
tags: [wordpress, jekyll]
description: Post o migracji bloga z platformy Wordpress na Jekyll
keywords: wordpress jekyll Michał Orman blog
---
No i dałem się namówić. Porzucam publikacje postów na Wordpress na rzecz [Jekyll](http://github.com/mojombo/jekyll/). Co prawda Jekyll nie jest platformą do publikowania postów, jest to jedynie narzędzie, które generuje pliki statyczne z plików tekstowych na podstawie szablonu.

Powodów przemigrowania było conajmniej kilka. Jednym niewątpliwie jest skok wydajnościowy. Zamiana plików PHP i odwołań do bazy danych na rzecz plików statycznych daje kopa. Dodatkowo mam pełen backup wszystkich plików i publikacji, oraz większą kontrolę nad wyglądem witryny. Oczywiście jest to obarczone większym nakładem pracy, włącznie z zdefiniowaniem szablonu witryny, ale efekt końcowy jest dużo bardziej satysfakcjonujący.

Wcześcniej zasadniczo nie wiedziałem jak backapować witrynę na wykupionym przeze mnie hoście. Obecnie źródła są pod kontrolą wersji Git-a i trzymane na GitHubie a ponieważ generowane pliki są w większości statyczne migracja na innego hosta to będzie chwila roboty (no i nie straszne mi są teraz pady serwerów).

{% highlight bash %}
$ gem install cheat
{% endhighlight %}

{% highlight ruby %}
def method
  "return"
end
{% endhighlight %}

{% highlight java linenos %}
public abstract class Base {
  public abstract void methodA();
  
  public void methodB() {
    Base b = new Base();
    b.methodA();
  }
}
{% endhighlight %}