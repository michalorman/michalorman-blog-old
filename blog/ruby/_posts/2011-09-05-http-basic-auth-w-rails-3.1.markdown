---
layout: post
title: HTTP Basic Auth w Rails 3.1
description: Prosta implementacja HTTP Basic Authentication w Rails 3.1
keywords: HTTP Basic Rails 3.1 Ruby
---
[Rails
3.1](http://weblog.rubyonrails.org/2011/8/31/rails-3-1-0-has-been-released)
pojawiło się na horyzoncie przynosząc nam wiele zmian (czasem dość
kontrowersyjnych), a także wiele uproszeń, w tym dotyczących
uwierzytelniania (*ang. authentication*). Teraz jeżeli chcemy część
naszych widoków ukryć tylko dla administratora, możemy w prosty sposób
zadeklarować uwierzytelnianie metodą [HTTP
Basic](http://en.wikipedia.org/wiki/Basic_access_authentication). Wystarczy
w kontrolerze dodać:

{% highlight ruby %}
http_basic_authenticate_with :name => "admin", :password => "secret"
{% endhighlight %}

I już. Dla pełności powinniśmy dodać `force_ssl` aby połączenie było
szyfrowane. Możemy również użyć parametrów `only` oraz `except`
znanych z filtrów.

To proste podejście jest jednak mało interesujące dla tych, którzy
implementują jakiejś REST-owo-JSON-owe API w oparciu o Rails. W takim
przypadku powinniśmy zdefiniować w kontrolerze filtr:

{% highlight ruby %}
before_filter :authenticate!

private

def authenticate!
  authenticated = authenticate_with_http_basic do |username, passwd|
    # Tutaj proces uwierzytelniania...
  end
  request_http_basic_authentication unless authenticated
end
{% endhighlight %}

W ten sposób możemy posiadać bazę wielu użytkowników i uwierzytelniać
ich metodą HTTP Basic. Rails czarną robotę zrobi za nas.
