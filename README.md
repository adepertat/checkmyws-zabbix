# Zabbix plugin for checkmy.ws

Get the status and performance information of https://checkmy.ws inside Zabbix.

## Requirements

* Python 2.7
* requests
* checkmyws

## Usage

1. Drop the `checkmy.ws` script in `/etc/zabbix/externalscripts` or wherever
   the `ExternalScripts` directive of your `zabbix_server.conf` points to and
   make it executable.
2. Import the template in Zabbix
3. Create a Host and declare a Macro named `{#CHECKMYWS_CHECK_ID}` containing
   the ID given by the checkmy.ws web site.
4. Gogogo
