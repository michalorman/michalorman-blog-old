---
layout: post
title: Ruby i The GNU Readline Library
description: Jak skompilować interpreter Ruby'ego wraz ze wsparciem dla biblioteki GNU Readline Library, wykorzystywanej m.in. przez irb.
keywords: Ruby The GNU Readline Library irb script/console
navbar_pos: 1
---
[Ostatnio](/blog/2010/03/ruby-i-openssl-w-opensuse/) pisałem o kompilacji interpretera
Ruby wraz z OpenSSL. Okazało się jednak, że nie był to koniec moich problemów
z zabawą z [RVM](http://rvm.beginrescueend.com/) i kompilacją interpretera. Niedługo
po problemach z OpenSSL w pewnej aplikacji Rails'owej chciałem uruchomić sesję IRB-a
(za pomocą skryptu `console`), oto co dostałem:

<pre>
$ ruby script/console
Loading development environment (Rails 2.3.5)
/home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/completion.rb:10:in `require': no such file to load -- readline (LoadError)
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/completion.rb:10
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/init.rb:254:in `require'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/init.rb:254:in `load_modules'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/init.rb:252:in `each'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/init.rb:252:in `load_modules'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb/init.rb:21:in `setup'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/lib/ruby/1.8/irb.rb:54:in `start'
        from /home/snc/.rvm/rubies/ruby-1.8.7-p249/bin/irb:18
</pre>

[Readline](http://tiswww.case.edu/php/chet/readline/rltop.html) a właściwie **The GNU Readline
Library**, bo tak brzmi pełna nazwa to biblioteka wspierająca CLI czyli tzw. wiersz
poleceń. Autorzy tej biblioteki piszą:

> The GNU Readline library provides a set of functions for use by applications that
> allow users to edit command lines as they are typed in.

Wygląda na to, że brakowało odpowiednich nagłówków w czasie kompilacji interpretera. Aby
to sprawdzić podobnie jak w przypadku OpenSSH należy udać się do źródeł (w tym
przypadku do podkatalogu `/ext/readline/`) i uruchomić skrypt `extconf.rb`:

<pre>
$ ruby extconf.rb
checking for tgetnum() in -lncurses... no
checking for tgetnum() in -ltermcap... no
checking for tgetnum() in -lcurses... no
checking for readline/readline.h... no
checking for editline/readline.h... no
</pre>

Rzeczywiście w systemie brakuje odpowiednich plików nagłówkowych. Instaluję zatem
brakujące biblioteki:

<pre>
$ sudo zypper install readline-devel
</pre>

To w przypadku systemu OpenSUSE, w przypadku Debiana/Ubuntu potrzebny pakiet to
`libreadline5-dev` wraz z `libncurses5-dev` (o ile ten drugi nie jest instalowany
jako zależność do tego pierwszego). Instalacja pakietu `readline-devel` jako zależność
wymusza instalację `ncurses-devel`.

Ponowne uruchomienie skryptu celem sprawdzenia zależności:

<pre>
$ ruby .rb
checking for tgetnum() in -lncurses... yes
checking for readline/readline.h... yes
checking for readline/history.h... yes
checking for readline() in -lreadline... yes
.
.
.
creating Makefile
</pre>

Teraz wszystko gra. Po kompilacji i zainstalowaniu uruchamiam sesję irb:

<pre>
$ ruby script/console
Loading development environment (Rails 2.3.5)
ruby-1.8.7-p249 >
</pre>

Zatem obsługa biblioteki Readline działa. Swoją drogą muszę przysiąść i przeanalizować
jakich jeszcze bibliotek mi brakowała podczas kompilacji interpretera. Jak na razie
przypomina to zabawę w kotka i myszkę, gdzie ja dodaję kolejne biblioteki, a interpreter
w którymś momencie się wykrzacza z braku innej.
