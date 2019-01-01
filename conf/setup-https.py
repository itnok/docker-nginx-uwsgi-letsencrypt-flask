#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, os
import subprocess
import fileinput
###################################################################
# Argparser
###################################################################
import argparse
import textwrap
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('''
    Configuration options required for automated letsencrypt certbot configuration.

    Examples:

    ./setup-https.py -d test.com -n test.com -e test@test.com
    ./setup-https.py -d test.com,www.test.com -n test.com -e test@test.com

    '''))
parser.add_argument('-d', '--domains', required=True, help="Comma separated set of domains to register")
parser.add_argument('-n', '--cert_name', required=True, help="Name for the cert, e.g. /etc/letsencrypt/live/CERTNAME/cert.pem")
parser.add_argument('-e', '--email', required=True, help="Email address to use with letsencrypt")
args = parser.parse_args()
###################################################################
# Directory/file variables
###################################################################
current_dir = os.path.dirname(os.path.realpath(__file__))
parent_dir = os.path.abspath(os.path.join(current_dir,os.pardir))
nginx_https_template_file = "{current_dir}/nginx-https-template.conf".format(current_dir=current_dir)
nginx_https_file = "{current_dir}/nginx-https.conf".format(current_dir=current_dir)


def remove_prior_folders(cert_name=args.cert_name):
    'Removes all instances of this domain.  If not done, new folders like /etc/letsencrypt/live/test.com-0001/ will be created'
    print_message("Removing any old folders to prevent any issues:")
    command = "rm -rf /etc/letsencrypt/live/{cert_name}*".format(cert_name=cert_name)
    output = get_command_output(command)
    command = "rm -rf /etc/letsencrypt/archive/{cert_name}*".format(cert_name=cert_name)
    output = get_command_output(command)
    command = "rm -rf /etc/letsencrypt/renewal/{cert_name}*".format(cert_name=cert_name)
    output = get_command_output(command)


def get_cert(domain_names, cert_name, email_address):
    'Attempts to get a cert through letsencrypt for the given domain and email'
    command = '''{current_dir}/certbot-auto \
    certonly \
    --non-interactive \
    --agree-tos \
    --cert-name "{cert_name}" \
    --webroot -w "{parent_dir}/app" \
    --email "{email_address}" \
    -d "{domain_names}"
    '''.format(current_dir=current_dir, parent_dir=parent_dir, cert_name=cert_name, email_address=email_address, domain_names=domain_names)
    print_message("Starting certbot-auto with:\n\n{command}".format(command=command))
    output = get_command_output(command)

    print_message("certbot-auto output:\n\n{output}".format(output=output))

    #Check and be sure that HTTPS was setup successfully
    if "Congratulations! Your certificate and chain have been saved" in output:
        return True
    else:
        return False


def configure_https(domain_names, cert_name):
    'Reconfigures Nginx for HTTPS'
    print_message("Reconfiguring Nginx for HTTPS")

    print_message("Replacing 'YOURDOMAIN' with cert_name {cert_name} and domains {domain_names} in {nginx_https_file}".format(cert_name=cert_name, domain_names=domain_names, nginx_https_file=nginx_https_file))

    #Write the new Nginx config file, keeping the template for future use
    template_file = open(nginx_https_template_file, "r")
    config_file = open(nginx_https_file, "w+")
    for line in template_file:
        if "YOURDOMAIN" in line:
            #Add all domain names to the server_name field
            if "server_name" in line:
                line = line.replace("YOURDOMAIN", " ".join(map(str,(domain_names.split(",")))))
            #Just add the cert_name to the cert path, e.g. /etc/letsencrypt/live/YOURDOMAIN/fullchain.pem
            elif "ssl_certificate" in line:
                line = line.replace("YOURDOMAIN", cert_name)
        config_file.write(line)
    template_file.close()
    config_file.close()

    #Remove HTTP symbolic link
    command = "rm /etc/nginx/sites-enabled/nginx-http.conf"
    print_message("Removing HTTP symbolic link:\n\n{command}".format(command=command))
    output = get_command_output(command)

    #Create a symbolic link for the HTTPS config
    command = "ln -s {nginx_https_file} /etc/nginx/sites-enabled/".format(nginx_https_file=nginx_https_file)
    print_message("Setting up symbolic link for HTTPS Nginx config:\n\n{command}".format(command=command))
    output = get_command_output(command)


def setup_cron_renew():
    'If not already created for this domain, creates an auto nenew cronjob'
    cron_command = '''1 0 * * * {current_dir}/certbot-auto renew --post-hook 'service supervisor restart' '''.format(current_dir=current_dir)
    if cron_command_in_crontab(cron_command):
        print_message("Auto-renew cronjob already setup")
    else:
        command = '''(crontab -l 2>/dev/null; echo "{cron_command}") | crontab -'''.format(cron_command=cron_command)
        print_message("Setting up auto-renew cronjob:\n\n{command}".format(command=command))
        output = get_command_output(command)


def cron_command_in_crontab(cron_command):
    'Checks to see if the cronjob is already in crontab'
    command = "cat /var/spool/cron/crontabs/root"
    output = get_command_output(command)
    if cron_command in output:
        return True
    else:
        return False


def restart_supervisor():
    'Restarts supervisor (runs uWSGI+Nginx) to enable HTTPS'
    command = "service supervisor restart"
    print_message("Restarting supervisor:\n\n{command}".format(command=command))
    output = get_command_output(command)


def print_message(message):
    print '''
========================================================================================================
[*] {message}
========================================================================================================
'''.format(message=message.strip())


def get_command_output(command):
    'Runs a command, returning its output'
    p = subprocess.Popen(command,
                            shell=True,
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,)
    output, error = p.communicate()
    return output


if __name__ == '__main__':
    remove_prior_folders(cert_name=args.cert_name)
    if get_cert(domain_names=args.domains, cert_name=args.cert_name, email_address=args.email):
        configure_https(domain_names=args.domains, cert_name=args.cert_name)
        setup_cron_renew()
        restart_supervisor()
    else:
        print_message("Letsencrypt cert was NOT successfully setup")
