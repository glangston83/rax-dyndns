#!/usr/bin/env python

import pyrax
import urllib2
import datetime
import argparse
import logging

logging.basicConfig(filename='rax-dyndns.log',level=logging.DEBUG)

now = datetime.datetime.now()
format_date = now.strftime("%y-%m-%d %H:%M")


pyrax.settings.set('identity_type', 'rackspace')
pyrax.set_credential_file(".rackspace_cloud_credentials")

#acquire public IP of home server
my_ip = urllib2.urlopen('http://ip.42.pl/raw').read()

#hook dns
dns = pyrax.cloud_dns

def parse_arguments():
    parser = argparse.ArgumentParser()
#    parser.add_argument("--source", required = True, help = "The Account Number of the Source AWS Account for migration")
    #parser.add_argument("--domain", required = True, dest="domain", help = "Domain to update record on")
    parser.add_argument("--subdomain", required = True, dest="subdomain", help = "subdomain to update record on")
    parser.add_argument("--override_ip", required = False, dest="override_ip", help = "If not given, IP supplied will be public facing address")
    #parser.add_argument("--debug", help = "Turn on boto debugging", dest = "debug", default = False, action = "store_true")
    return parser.parse_args()

if __name__ == "__main__":

    options = parse_arguments()

    subdom = options.subdomain
    fqdn = subdom.split(".")
    dom = fqdn[1]+"."+fqdn[2]

    # If override IP was given
    if options.override_ip:
        my_ip = options.override_ip

#acquire domains on account in list and set to public IP of home server
    domains = dns.list()
    for domain in domains:
        if domain.name == dom:
            logging.debug(domain)
            recs = dns.list_records(domain)
            rec_found=False
            for rec in recs:
                if rec.name == subdom:
                    rec_found=True
                    #print format_date, "-- Updating record for ", rec.name, "IP Address ", my_ip
                    logging.debug(str(format_date) + "-- Updating record for " + str(rec.name) + " IP Address " + str(my_ip))
                    try:
                        rec.update(data=my_ip)
                    except:
                        logging.error("Failure to update DNS Records for %s" % subdom)
                    else:
                        logging.debug("Record Updated Successfully: %s" % subdom)
            if not rec_found:
                #print "Record not found for %s" % subdomain
                logging.debug("Record not found for %s" % subdom)

