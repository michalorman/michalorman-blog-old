---
layout: post
title: Analiza bezpieczeństwa serwera WWW z Nitko
categories: [Security]
tags: [nitko, security, www]
description: Przedstawienie procesu analizy bezpieczeństwa serwera WWW z wykorzystaniem narzędzia Nitko
keywords: www security bezpieczeństwo nitko
---
Serwis [OSnews](http://osnews.pl/) opublikował [artykuł](http://osnews.pl/jak-sprawdzic-czy-twoj-serwer-www-jest-bezpieczny-pojawil-sie-nikto-2-1-0/) o tym jak można sprawdzić stan bezpieczeństwa serwera WWW za pomocą narzędzia [Nitko](https://cirt.net/nikto2). Z czystej ciekawości postanowiłem sprawdzić działanie tegoż narzędzia na serwerze z aplikacją, którą aktualnie się zajmuję. Tak więc szybka [instalacja](http://cirt.net/nikto2-docs/installation.html) i odpalam:

    $ perl nikto.pl -h 94.23.*.*
    - ***** SSL support not available (see docs for SSL install instructions) *****
    - Nikto v2.1.0/2.1.0
    ---------------------------------------------------------------------------
    + Target IP:          94.23.*.*
    + Target Hostname:    *.*
    + Target Port:        80
    + Start Time:         2009-11-09 16:50:51
    ---------------------------------------------------------------------------
    + Server: Apache-Coyote/1.1
    + OSVDB-0: robots.txt contains 5 entries which should be manually viewed.
    + No CGI Directories found (use '-C all' to force check all possible dirs)
    + OSVDB-0: Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, TRACE, OPTIONS
    + OSVDB-397: HTTP method ('Allow' Header): 'PUT' method could allow clients to save files on the web server.
    + OSVDB-5646: HTTP method ('Allow' Header): 'DELETE' may allow clients to remove files on the web server.
    + OSVDB-0: DEBUG HTTP verb may show server debugging information
    + OSVDB-0: Non-standard header set-cookie returned by server, with contents: JSESSIONID=6D4E13480BA384CFE46A3A2412291788; Path=/
    + OSVDB-0: Non-standard header x-powered-by returned by server, with contents: JSF/1.2
    + OSVDB-0: ETag header found on server, fields: 0xW/116 0x1254145192000
    + OSVDB-0: /help/: Help directory should not be accessible
    + OSVDB-3092: /cart/: This might be interesting...
    + OSVDB-3092: /register/: This might be interesting...
    + OSVDB-6659: /gQwvk0Xp8XPvD7m0gIuopOl8RMZfNAu43HpWKVCLIVuR3b7GhLJ4AO302WbmCDqMuOQ5YlrU5LvPoxT016P2wHpGTQgLrEiPTkbvUhnj10iqQ6pcUSrBC38YX8EihpZFYkuncPogNCNOXJdpdw10k7KNs2FV3aBxHtHrZRdQPxWcAAVRAWudV113oSKyg0VI6IBO8Nm96coH0vyBNHVLOaiqSPg4ZqfDEFACED<!--// : MyWebServer 1.0.2 is vulnerable to HTML injection. Upgrade to a later version.<br /-->
    + 3582 items checked: 12 item(s) reported on remote host
    + End Time:           2009-11-09 16:56:28 (337 seconds)
    ---------------------------------------------------------------------------
    + 1 host(s) tested

I co? Hmm... Nie widzę, aby skrypt alarmował o jakiś problemach na serwerze. Czy to znaczy, że mój serwer jest bezpieczny? Trudno powiedzieć, na wszelki wypadek wypróbuję skrypt na innym serwerze (z aplikacją naszego potencjalnego konkurenta ;)). Oto wynik:

    $ perl nikto.pl -h 82.96.*.*
    - ***** SSL support not available (see docs for SSL install instructions) *****
    - Nikto v2.1.0/2.1.0
    ---------------------------------------------------------------------------
    + Target IP:          82.96.*.*
    + Target Hostname:    82.96.*.*
    + Target Port:        80
    + Start Time:         2009-11-09 17:01:52
    ---------------------------------------------------------------------------
    + Server: Apache/1.3.41 () mod_ssl/2.8.30 OpenSSL/0.9.8c
    + OSVDB-0: robots.txt contains 1 entry which should be manually viewed.
    + OSVDB-0: Allowed HTTP Methods: GET, HEAD, OPTIONS, TRACE
    + OSVDB-0: DEBUG HTTP verb may show server debugging information
    + OSVDB-877: HTTP TRACE method is active, suggesting the host is vulnerable to XST
    + OSVDB-0: Apache/1.3.41 appears to be outdated (current is at least Apache/2.2.14). Apache 1.3.41 and 2.0.63 are also current.
    + OSVDB-0: mod_ssl/2.8.30 appears to be outdated (current is at least 2.8.31) (may depend on server version)
    + OSVDB-0: OpenSSL/0.9.8c appears to be outdated (current is at least 0.9.8i) (may depend on server version)
    + OSVDB-0: Non-standard header keep-alive returned by server, with contents: timeout=15, max=100
    + OSVDB-0: Non-standard header set-cookie returned by server, with contents: PHPSESSID=3f00181c814d249696327048bd50c7ba; path=/
    + OSVDB-0: Non-standard header x-powered-by returned by server, with contents: PHP/5.2.6
    + OSVDB-0: /forums//admin/config.php: PHP Config file may contain database IDs and passwords.
    + OSVDB-0: /forums//adm/config.php: PHP Config file may contain database IDs and passwords.
    + OSVDB-0: /forums//administrator/config.php: PHP Config file may contain database IDs and passwords.
    + OSVDB-0: /nsn/..%5Cutil/attrib.bas: Netbase util access is possible which means that several utility scripts might be run (including directory listings, NDS tree enumeration and running .bas files on server
    + OSVDB-0: /nsn/..%5Cutil/chkvol.bas: Netbase util access is possible which means that several utility scripts might be run (including directory listings, NDS tree enumeration and running .bas files on server
    + OSVDB-0: /nsn/..%5Cutil/copy.bas: Netbase util access is possible which means that several utility scripts might be run (including directory listings, NDS tree enumeration and running .bas files on server
    + OSVDB-0: /nsn/..%5Cutil/del.bas: Netbase util access is possible which means that several utility scripts might be run (including directory listings, NDS tree enumeration and running .bas files on server
    + OSVDB-0: /ht_root/wwwroot/-/local/httpd$map.conf: WASD reveals the http configuration file. Upgrade to a later version and secure according to the documents on the WASD web site.
    + OSVDB-0: /local/httpd$map.conf: WASD reveals the http configuration file. Upgrade to a later version and secure according to the documents on the WASD web site.
    + OSVDB-0: /..\..\..\..\..\..\temp\temp.class: Cisco ACS 2.6.x and 3.0.1 (build 40) allows authenticated remote users to retrieve any file from the system. Upgrade to the latest version.
    + OSVDB-0: /chat/!nicks.txt: WF-Chat 1.0 Beta allows retrieval of user information.
    + OSVDB-0: /chat/!pwds.txt: WF-Chat 1.0 Beta allows retrieval of user information.
    + OSVDB-240: /scripts/wsisa.dll/WService=anything?WSMadmin: Allows Webspeed to be remotely administered. Edit unbroker.properties and set AllowMsngrCmds to 0.
    + OSVDB-3092: /sitemap.xml: This gives a nice listing of the site content.
    + OSVDB-578: /level/16/exec/-///pwd: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/exec/-///show/configuration: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/exec//show/access-lists: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/level/16/exec//show/configuration: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/level/16/exec//show/interfaces: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/level/16/exec//show/interfaces/status: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/level/16/exec//show/version: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/level/16/exec//show/running-config/interface/FastEthernet: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/16/exec//show: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/17/exec//show: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/18/exec//show: CISCO HTTP service allows remote execution of commands
    + OSVDB-578: /level/19/exec//show: CISCO HTTP service allows remote execution of commands
    + OSVDB-12184: /index.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000: PHP reveals potentially sensitive information via certain HTTP requests which contain specific QUERY strings.
    + OSVDB-12184: /some.php?=PHPE9568F36-D428-11d2-A769-00AA001ACF42: PHP reveals potentially sensitive information via certain HTTP requests which contain specific QUERY strings.
    + OSVDB-12184: /some.php?=PHPE9568F34-D428-11d2-A769-00AA001ACF42: PHP reveals potentially sensitive information via certain HTTP requests which contain specific QUERY strings.
    + OSVDB-12184: /some.php?=PHPE9568F35-D428-11d2-A769-00AA001ACF42: PHP reveals potentially sensitive information via certain HTTP requests which contain specific QUERY strings.
    + OSVDB-3092: /lost+found/: This might be interesting...
    + OSVDB-3092: /iNotes/Forms5.nsf/$DefaultNav: This database can be read without authentication, which may reveal sensitive information.
    + OSVDB-3093: /bugtest+/+: This might be interesting... has been seen in web logs from an unknown scanner.
    + OSVDB-3093: /etc/shadow+: This might be interesting... has been seen in web logs from an unknown scanner.
    + OSVDB-3093: /index.php?topic=&amp;amp;lt;script&amp;amp;gt;alert(document.cookie)&amp;amp;lt;/script&amp;amp;gt;%20: This might be interesting... has been seen in web logs from an unknown scanner.
    + OSVDB-3093: /netget?sid=Safety&amp;amp;msg=2002&amp;amp;file=Safety: This might be interesting... has been seen in web logs from an unknown scanner.
    + OSVDB-4908: /securelogin/1,2345,A,00.html: Vignette Story Server v4.1, 6, may disclose sensitive information via a buffer overflow.
    + OSVDB-721: /..%255c..%255c..%255c..%255c..%255c../windows/repair/sam: BadBlue server is vulnerable to multiple remote exploits. See http://www.securiteam.com/exploits/5HP0M2A60G.html for more information.
    + OSVDB-721: /..%255c..%255c..%255c..%255c..%255c../winnt/repair/sam: BadBlue server is vulnerable to multiple remote exploits. See http://www.securiteam.com/exploits/5HP0M2A60G.html for more information.
    + OSVDB-721: /..%255c..%255c..%255c..%255c..%255c../winnt/repair/sam._: BadBlue server is vulnerable to multiple remote exploits. See http://www.securiteam.com/exploits/5HP0M2A60G.html for more information.
    + 3582 items checked: 146 item(s) reported on remote host
    + End Time:           2009-11-09 17:15:24 (812 seconds)
    ---------------------------------------------------------------------------
    + 1 host(s) tested
    
Tutaj narzędzie zwróciło nieco więcej wyników, trochę je jeszcze przyciąłem, aby były nieco czytelniejsze. W tym wypadku wynik jest zdecydowanie bardziej niepokojący, zwłaszcza informacje na temat serwera BadBlue, który zdaniem narzędzia jest podatny na wiele exploitów. Do tego źródła PHP potencjalnie pozwalają na odczyt wrażliwych danych (za pomocą żądań HTTP z odpowiednimi parametrami). Dramatycznie nie jest, ale na pewno gorzej niż w przypadku mojego serwera.

Narzędzie niewątpliwie ciekawe i z czasem spróbuję użyć innych tego typu. Jak znajdę czas przeanalizuję jakie jeszcze możliwości daje mi ten programik.