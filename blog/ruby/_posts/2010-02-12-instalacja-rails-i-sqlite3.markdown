---
layout: post
title: Instalacja Rails i sqlite3
description: Problemy z konfiguracją Rails wraz z sqlite3
keywords: ruby rails sqlite3
---
Każdy rozpoczynający pracę z frameworkiem Rails może wpaść w pewną pułapkę, taką na jaką ja się nadziałem. Wynika ona ze
zbieżności nazw pakietów dla silnika bazy danych [SQLite](http://www.sqlite.org/). Jeżeli zaczynamy zabawę z Rails
i używamy właśnie tej bazy (np. wtedy gdy naukę zaczynamy od [tej](http://pragprog.com/titles/rails3/agile-web-development-with-rails-third-edition) książki)
musimy uważać na gemy jakie instalujemy. Prawidłowa lista gemów to:
* ``rails`` oczywiście, oraz
* ``sqlite3-ruby``

Czasami jednak dla nowo wygenerowanego projektu Rails w momencie gdy na stronie głównej sprawdzamy środowisko uruchomieniowe
możemy otrzymać informację o błędzie. Zaglądając na konsolę serwera widzimy taki oto zapis z sekcji zwłok:

<pre>
$ ruby script/server
=> Booting WEBrick
=> Rails 2.3.5 application starting on http://0.0.0.0:3000
=> Call with -d to detach
=> Ctrl-C to shutdown server
[2010-02-12 00:08:16] INFO  WEBrick 1.3.1
[2010-02-12 00:08:16] INFO  ruby 1.8.7 (2008-08-11) [i586-linux]
[2010-02-12 00:08:16] INFO  WEBrick::HTTPServer#start: pid=5303 port=3000
/!\ FAILSAFE /!\  Fri Feb 12 00:08:24 +0100 2010
  Status: 500 Internal Server Error
  uninitialized constant Encoding
    /usr/lib/ruby/gems/1.8/gems/activesupport-2.3.5/lib/active_support/dependencies.rb:443:in `load_missing_constant'
    /usr/lib/ruby/gems/1.8/gems/activesupport-2.3.5/lib/active_support/dependencies.rb:80:in `const_missing'
    /usr/lib/ruby/gems/1.8/gems/activesupport-2.3.5/lib/active_support/dependencies.rb:92:in `const_missing'
    /usr/lib/ruby/gems/1.8/gems/sqlite3-0.0.8/lib/sqlite3/encoding.rb:9:in `find'
    /usr/lib/ruby/gems/1.8/gems/sqlite3-0.0.8/lib/sqlite3/database.rb:66:in `initialize'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/sqlite3_adapter.rb:13:in `new'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/sqlite3_adapter.rb:13:in `sqlite3_connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:223:in `send'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:223:in `new_connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:245:in `checkout_new_connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:188:in `checkout'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:184:in `loop'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:184:in `checkout'
    /usr/lib/ruby/1.8/monitor.rb:242:in `synchronize'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:183:in `checkout'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:98:in `connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:326:in `retrieve_connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_specification.rb:123:in `retrieve_connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_specification.rb:115:in `connection'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/query_cache.rb:9:in `cache'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/query_cache.rb:28:in `call'
    /usr/lib/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/abstract/connection_pool.rb:361:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/string_coercion.rb:25:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/head.rb:9:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/methodoverride.rb:24:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/params_parser.rb:15:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/session/cookie_store.rb:93:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/failsafe.rb:26:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/lock.rb:11:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/lock.rb:11:in `synchronize'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/lock.rb:11:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/dispatcher.rb:114:in `call'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/reloader.rb:34:in `run'
    /usr/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/dispatcher.rb:108:in `call'
    /usr/lib/ruby/gems/1.8/gems/rails-2.3.5/lib/rails/rack/static.rb:31:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/urlmap.rb:46:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/urlmap.rb:40:in `each'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/urlmap.rb:40:in `call'
    /usr/lib/ruby/gems/1.8/gems/rails-2.3.5/lib/rails/rack/log_tailer.rb:17:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/content_length.rb:13:in `call'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/handler/webrick.rb:50:in `service'
    /usr/lib/ruby/1.8/webrick/httpserver.rb:104:in `service'
    /usr/lib/ruby/1.8/webrick/httpserver.rb:65:in `run'
    /usr/lib/ruby/1.8/webrick/server.rb:173:in `start_thread'
    /usr/lib/ruby/1.8/webrick/server.rb:162:in `start'
    /usr/lib/ruby/1.8/webrick/server.rb:162:in `start_thread'
    /usr/lib/ruby/1.8/webrick/server.rb:95:in `start'
    /usr/lib/ruby/1.8/webrick/server.rb:92:in `each'
    /usr/lib/ruby/1.8/webrick/server.rb:92:in `start'
    /usr/lib/ruby/1.8/webrick/server.rb:23:in `start'
    /usr/lib/ruby/1.8/webrick/server.rb:82:in `start'
    /usr/lib/ruby/gems/1.8/gems/rack-1.0.1/lib/rack/handler/webrick.rb:14:in `run'
    /usr/lib/ruby/gems/1.8/gems/rails-2.3.5/lib/commands/server.rb:111
    /usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `gem_original_require'
    /usr/lib/ruby/site_ruby/1.8/rubygems/custom_require.rb:31:in `require'
    script/server:3
</pre>

Aby zrozumieć co się tutaj stało kluczowe okazują się następujące linijki:

<pre>
  /usr/lib/ruby/gems/1.8/<strong>gems/sqlite3-0.0.8</strong>/lib/sqlite3/encoding.rb:9:in `find'
  /usr/lib/ruby/gems/1.8/<strong>gems/sqlite3-0.0.8</strong>/lib/sqlite3/database.rb:66:in `initialize'
</pre>

Otóż okazuje się, że jeżeli mamy zainstalowany gem ``sqlite3`` bez ``-ruby`` to wpływa on w jakiś sposób na procedurę inicjalizacji bazy co w konsekwencji
powoduję zgłoszenie wyjątku. Subtelna różnica w nazwie a może narobić takich irytujących problemów. W każdym razie odinstalowanie tego gema powoduje,
że nasza aplikacja działa prawidłowo.
