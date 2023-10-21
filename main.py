#!/usr/bin/env python

import getpass
from lxml import html
import requests
import sys 

def main():
    username = input('username: ')
    password = getpass.getpass('password: ')

    session = requests.Session()

    self.session.get('https://www.gradescope.com/auth/saml/clemson')
    idp_page = self.session.post(
        'https://idp.clemson.edu/idp/profile/SAML2/Redirect/SSO?execution=e1s1',
        data={
            'j_username': username,
            'j_password': password,
            '_eventId_proceed': '',
        }
    )

    doc = html.document_fromstring(idp_page.content)
    saml_response = doc.xpath('//input[@type="hidden"]/@value')
    r = self.session.post('https://www.gradescope.com/auth/saml/clemson/callback', data={'SAMLResponse': saml_response})

if __name__ == '__main__':
    main()
