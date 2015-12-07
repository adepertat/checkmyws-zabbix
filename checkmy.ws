#!/usr/bin/env python
# -*- encoding: utf-8 -*-

__version__ = '1.0.0'

import sys
import json
import argparse

# Warnings must be disabled explicitly on U12.04/Py2.7
import requests
requests.packages.urllib3.disable_warnings()

import logging
logging.basicConfig(format='%(levelname)s %(message)s')
logger = logging.getLogger('plugin')

try:
    import checkmyws
except ImportError:
    print("Please install 'checkmyws-python' module ('pip install checkmyws-python')")
    sys.exit(3)

# ---------------------------------------------------------------------

# Keys with values that we are allowed to query from the API
KEYS = (
    'lastvalues.httptime',
    'lastvalues.state',
    'metas.base64Size',
    'metas.code',
    'metas.contentLength',
    'metas.cssSize',
    'metas.dns_expiration_timestamp',
    'metas.favicon_url',
    'metas.htmlSize',
    'metas.imageSize',
    'metas.ip',
    'metas.jsErrors',
    'metas.jsSize',
    'metas.lastcheck',
    'metas.laststatechange',
    'metas.laststatechange_bin',
    'metas.notFound',
    'metas.otherSize',
    'metas.redirects',
    'metas.requests',
    'metas.title',
    'metas.webfontSize',
    'metas.yslow_page_load_time',
    'metas.yslow_score',
    'name',
    'state',
    'state_code',
    'state_code_str',
    'status_description',
    'status_link_facebook',
    'status_link_googleplus',
    'status_link_other',
    'status_link_twitter',
    'status_share_buttons',
    'tags',
    'url',

    'list-keys',
    'discover-locations',
)

# Special keys that can be queried by location
KEYS_BY_LOCATION = (
    'lastvalues.httptime',
    'metas.ip',
    'state',
)

# ---------------------------------------------------------------------

def discover_locations(status):
    """ Return a JSON dict of all locations suitable for Zabbix LLD
    """
    return json.dumps(
        dict(
            data=[{
                '{#LOCATION_ID}': worker_id,
                '{#LOCATION_BANDWIDTH}': worker_details['bandwidth'],
                '{#LOCATION_CITY}': worker_details['city'],
                '{#LOCATION_COUNTRY}': worker_details['country'],
                '{#LOCATION_FLAG}': worker_details['flag'],
                '{#LOCATION_ISP}': worker_details['isp'],
            } for worker_id, worker_details in status['workers'].items()]
        )
    )

def get_value(status, key, location):
    """ Return the value from the API, using the location if needed
    """
    # Get the value from the root of the status dict or from a subdict if the
    # key contains a dot
    value = None
    if '.' in key:
        a,b = key.split('.')
        value = status[a][b]
    else:
        value = status[key]

    if location:
        if key not in KEYS_BY_LOCATION:
            raise KeyError("{} is not available by location".format(key))
        # Special case for state==states in the location context
        if key == 'state':
            value = status['states']
        return value[location]

    if key == 'lastvalues.state':
        return value['backend']
    return value

# ---------------------------------------------------------------------

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Check my Website plugin for Zabbix.",
        version=__version__
    )
    parser.add_argument('--proxy', default=None, help='HTTP Proxy URL')
    parser.add_argument('--location', default=None, 
                        help=("Get value from this location if applicable "
                              "(discover with discover-locations)"))
    parser.add_argument('check_id', nargs=1, help='Check ID')
    parser.add_argument('action', nargs='?', default='state_code_str',
                        help="Metric/status to display (list-keys to list)")
    parser.add_argument('--debug', action='store_true', help="More info.")
    args = parser.parse_args()

    args.check_id = args.check_id[0]

    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.debug("Args: {}".format(args))
    logger.debug("Checking ID {}".format(args.check_id))

    client = checkmyws.CheckmywsClient(proxy=args.proxy)
    try:
        status = client.status(args.check_id)
    except Exception as e:
        print(e)
        sys.exit(3)

    if args.action == 'list-keys':
        print('\n'.join(KEYS))
    elif args.action == 'discover-locations':
        print(discover_locations(status))
    elif args.action in KEYS:
        try:
            print(get_value(status, args.action, args.location))
        except Exception as e:
            print(e)
            sys.exit(3)
    else:
        print('Unsupported key/action (list-keys to show) : {}'.format(args.action))
