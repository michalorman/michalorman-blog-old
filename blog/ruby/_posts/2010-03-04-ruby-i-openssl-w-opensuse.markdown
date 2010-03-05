---
layout: post
title: Ruby i OpenSSL w OpenSUSE
description: Problemy z OpenSSL po instalacji Ruby'ego ze źródeł. Zduplikowane nazwy pakietów przyczyną problemół z kompilacją interpretera Ruby.
keywords: Ruby RVM Version Manager SUSE OpenSUSE OpenSSL libopenssl libopenssl-devel
navbar_pos: 1
---
Uruchamiając migracje pewnej aplikacji [railsowej](http://rubyonrails.org/)
natknąłem się na poniższy błąd:

<pre>
$ rake db:migrate
rake aborted!
no such file to load -- openssl

(See full trace by running task with --trace)
</pre>

Zasadniczo komunikat jest co najmniej skąpy. Nie wiadomo, czy chodzi tu o brak
jakiegoś gema czy biblioteki. Użycie parametru `--trace` niewiele mi pomogło
(aczkolwiek jakby wykluczało brak gem'a no i w repozytorium gemów nie ma takiego
o nazwie `openssl`).

Tak się złożyło, że akurat bawiłem się [RVM'em](http://rvm.beginrescueend.com/),
który instaluje interpretery Ruby kompilując je ze źródeł. Szybko sprawdzam zainstalowane
pakiety w systemie dotyczące OpenSSL-a:

<pre>
$ zypper search openssl
Pobieranie danych repozytorium...
Odczyt zainstalowanych pakietów...

S | Nazwa                         | Podsumowanie                                                            | Typ
--+-------------------------------+-------------------------------------------------------------------------+----------------
  | compat-openssl097g            | Secure Sockets and Transport Layer Security                             | pakiet
  | compat-openssl097g            | Secure Sockets and Transport Layer Security                             | pakiet źródłowy
  | compat-openssl097g            | openssl: fix for possible man-in-the-middle attack due to renegotiation | poprawka
  | libopenssl-devel              | Include Files and Libraries mandatory for Development                   | pakiet
i | libopenssl-devel              | openssl: fix for possible man-in-the-middle attack due to renegotiation | poprawka
i | libopenssl0_9_8               | Secure Sockets and Transport Layer Security                             | pakiet
  | libxmlsec1-openssl-devel      | OpenSSL crypto plugin for XML Security Library                          | pakiet
  | libxmlsec1-openssl1           | OpenSSL crypto plugin for XML Security Library                          | pakiet
  | libxmlsec1-openssl1-debuginfo | Debug information for package libxmlsec1-openssl1                       | pakiet
  | nss-compat-openssl-devel      | OpenSSL to NSS source-level compatibility library                       | pakiet
i | openssl                       | Secure Sockets and Transport Layer Security                             | pakiet
  | openssl                       | Secure Sockets and Transport Layer Security                             | pakiet źródłowy
i | openssl-CVE-2009-4355.patch   | openssl security update                                                 | poprawka
i | openssl-certs                 | CA certificates for OpenSSL                                             | pakiet
  | openssl-certs                 | CA certificates for OpenSSL                                             | pakiet źródłowy
  | openssl-doc                   | Additional Package Documentation                                        | pakiet
  | openssl-ibmca                 | The IBMCA OpenSSL dynamic engine                                        | pakiet
  | openssl_tpm_engine            | OpenSSL TPM interface engine plugin                                     | pakiet
  | perl-Crypt-OpenSSL-Bignum     | Interface for OpenSSL's multiprecision integer arithmetic               | pakiet
  | perl-Crypt-OpenSSL-RSA        | RSA encoding and decoding, using the openSSL libraries                  | pakiet
  | perl-Crypt-OpenSSL-Random     | Interface to OpenSSL PRNG methods                                       | pakiet
  | php5-openssl                  | PHP5 Extension Module                                                   | pakiet
  | python-openssl                | Python wrapper module around the OpenSSL library                        | pakiet
</pre>

Na pierwszy rzut oka wszystko jest w porządku, mam zainstalowany zarówno pakiet `openssl` oraz
`libopenssl-devel`. Przyglądając się jednak bliżej, można zauważyć, że w repozytorium
OpenSUSE znajdują się dwa pakiety o nazwie `libopenssl-devel` (z czego jeden to pakiet,
drugi to poprawka). Wygląda na to, że `zypper` zainstalował mi tylko poprawkę, a sam pakiet pominął.

Jest sposób, aby upewnić się, że wszelkie nagłówki OpenSSL'a są zainstalowane prawidłowo.
Wchodzimy do źródeł Ruby'ego (które kompilowaliśmy) a tam do katalogu `ext/openssl`. W katalogu tym
uruchamiamy skrypt `extconf.rb`:

<pre>
$ ruby extconf.rb
=== OpenSSL for Ruby configurator ===
=== Checking for system dependent stuff... ===
checking for t_open() in -lnsl... no
checking for socket() in -lsocket... no
checking for assert.h... yes
=== Checking for required stuff... ===
<strong>checking for openssl/ssl.h... no</strong>
=== Checking for required stuff failed. ===
Makefile wasn't created. Fix the errors above.
</pre>

Widać, że brakuje pliku nagłówkowego `openssl/ssl.h`. Jeszcze raz instaluję `libopenssl-devel`
tym razem przy pomocy `yast'a`:

<pre>
# yast2 --install libopenssl-devel
</pre>

I sprawdzam zainstalowane pakiety:

<pre>
$ zypper search openssl
Pobieranie danych repozytorium...
Odczyt zainstalowanych pakietów...

S | Nazwa                         | Podsumowanie                                                            | Typ
--+-------------------------------+-------------------------------------------------------------------------+----------------
  | compat-openssl097g            | Secure Sockets and Transport Layer Security                             | pakiet
  | compat-openssl097g            | Secure Sockets and Transport Layer Security                             | pakiet źródłowy
  | compat-openssl097g            | openssl: fix for possible man-in-the-middle attack due to renegotiation | poprawka
i | libopenssl-devel              | Include Files and Libraries mandatory for Development                   | pakiet
i | libopenssl-devel              | openssl: fix for possible man-in-the-middle attack due to renegotiation | poprawka
i | libopenssl0_9_8               | Secure Sockets and Transport Layer Security                             | pakiet
  | libxmlsec1-openssl-devel      | OpenSSL crypto plugin for XML Security Library                          | pakiet
  | libxmlsec1-openssl1           | OpenSSL crypto plugin for XML Security Library                          | pakiet
  | libxmlsec1-openssl1-debuginfo | Debug information for package libxmlsec1-openssl1                       | pakiet
  | nss-compat-openssl-devel      | OpenSSL to NSS source-level compatibility library                       | pakiet
i | openssl                       | Secure Sockets and Transport Layer Security                             | pakiet
  | openssl                       | Secure Sockets and Transport Layer Security                             | pakiet źródłowy
i | openssl-CVE-2009-4355.patch   | openssl security update                                                 | poprawka
i | openssl-certs                 | CA certificates for OpenSSL                                             | pakiet
  | openssl-certs                 | CA certificates for OpenSSL                                             | pakiet źródłowy
  | openssl-doc                   | Additional Package Documentation                                        | pakiet
  | openssl-ibmca                 | The IBMCA OpenSSL dynamic engine                                        | pakiet
  | openssl_tpm_engine            | OpenSSL TPM interface engine plugin                                     | pakiet
  | perl-Crypt-OpenSSL-Bignum     | Interface for OpenSSL's multiprecision integer arithmetic               | pakiet
  | perl-Crypt-OpenSSL-RSA        | RSA encoding and decoding, using the openSSL libraries                  | pakiet
  | perl-Crypt-OpenSSL-Random     | Interface to OpenSSL PRNG methods                                       | pakiet
  | php5-openssl                  | PHP5 Extension Module                                                   | pakiet
  | python-openssl                | Python wrapper module around the OpenSSL library                        | pakiet
</pre>

Mam już zainstalowany pakiet `libopenssl-devel` a nie tylko poprawkę.
Teraz mogę wrócić do źródeł Ruby'ego i sprawdzić czy wszystko jest w porządku:

<pre>
$ ruby extconf.rb
=== OpenSSL for Ruby configurator ===
=== Checking for system dependent stuff... ===
checking for t_open() in -lnsl... no
checking for socket() in -lsocket... no
checking for assert.h... yes
=== Checking for required stuff... ===
checking for openssl/ssl.h... yes
checking for OpenSSL_add_all_digests() in -lcrypto... yes
checking for SSL_library_init() in -lssl... yes
checking for openssl/conf_api.h... yes
.
.
.
=== Checking done. ===
creating extconf.h
creating Makefile
Done.
</pre>

Działa, teraz spokojnie mogę skompilować interpreter. Widać tu jakie mały bałagan
z nazwami pakietów w repozytorium systemowym może spowodować problemy.