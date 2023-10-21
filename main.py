#!/usr/bin/env python

import getpass
from lxml import html
import requests
import sys 

def main():
    username = input('username: ')
    password = getpass.getpass('password: ')

    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/118.0'})

    login(session, username, password)
    print(get_courses(session))

def login(session, username, password):
    session.get('https://www.gradescope.com/auth/saml/clemson')
    idp_page = session.post(
        'https://idp.clemson.edu/idp/profile/SAML2/Redirect/SSO?execution=e1s1',
        data={
            'j_username': username,
            'j_password': password,
            '_eventId_proceed': '',
        }
    )

    doc = html.document_fromstring(idp_page.content)
    saml_response = doc.xpath('//input[@type="hidden"]/@value')
    session.post('https://www.gradescope.com/auth/saml/clemson/callback', data={'SAMLResponse': saml_response})

def get_course_list(session):
    page = session.get('https://www.gradescope.com')
    doc = html.document_fromstring(page.content)
    courses = doc.xpath('//a[@class="courseBox"]')

    return list(map(lambda course: {
        'path': course.get('href'),
        'short_name': course.find('h3[@class="courseBox--shortname"]').text_content(),
        'name': course.find('div[@class="courseBox--name"]').text_content(),
    }, courses))

if __name__ == '__main__':
    main()
