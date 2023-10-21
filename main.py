#!/usr/bin/env python

import getpass
import iterfzf
from lxml import html
import requests
import sys 

def main():
    # session = requests.Session()
    # submit_submission(session, '')
    # return
    username = input('username: ')
    password = getpass.getpass('password: ')

    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/118.0'})

    login(session, username, password)

    course_list = get_courses(session)
    course_name = iterfzf.iterfzf(map(lambda x: x['name'], course_list))

    assignments = get_course_assignments(session, list(filter(lambda x: x['name'] == course_name, course_list))[0]['path'])
    assignment_name = iterfzf.iterfzf(map(lambda x: x['title'], assignments))

    print('submitting to ' + assignment_name)
    submit_submission(session, list(filter(lambda x: x['title'] == assignment_name, assignments))[0]['path'], input('enter files (separated by spaces): ').split(' '))

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

def get_courses(session):
    page = session.get('https://www.gradescope.com')
    doc = html.document_fromstring(page.content)
    courses = doc.xpath('//a[@class="courseBox"]')

    return list(map(lambda course: {
        'path': course.get('href'),
        'short_name': course.find('h3[@class="courseBox--shortname"]').text_content(),
        'name': course.find('div[@class="courseBox--name"]').text_content(),
    }, courses))

def get_course_assignments(session, path):
    page = session.get('https://www.gradescope.com' + path)

    doc = html.document_fromstring(page.content)
    elements = doc.xpath('//table/tbody/tr')

    assignments = []

    for e in elements:
        if e.find_class('progressBar'):
            title_element = e.find('th[@class="table--primaryLink"]/a')
            assignments.append({
                'title': title_element.text_content(),
                'path': title_element.get('href'),
            })

    return assignments

def submit_submission(session, path, files):
    page = session.get('https://www.gradescope.com' + path)
    doc = html.document_fromstring(page.content)
    authenticity_token = doc.xpath('//meta[@name="csrf-token"]/@content')[0]

    data = (
        ('utf8', '✓'),
        ('authenticity_token', authenticity_token),
        ('submission[method]', 'upload'),
        ('submission[leaderboard_name]', ''),
    )

    files = (
        *tuple(map(lambda f: ('submission[files][]', (f, open(f, 'rb'), 'application/octet-stream')), files)),
    )

    print('https://www.gradescope.com' + '/'.join(path.split('/')[:-1]))

    submission_response = session.post('https://www.gradescope.com' + '/'.join(path.split('/')[:-1]), files=files, data=data, headers={'Accept': 'application/json'}).json()
    print(submission_response)

def getCookies(cookie_jar):
    cookie_dict = cookie_jar.get_dict(domain='www.gradescope.com')
    found = ['%s=%s' % (name, value) for (name, value) in cookie_dict.items()]
    return ';'.join(found)

if __name__ == '__main__':
    main()
