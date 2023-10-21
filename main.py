#!/usr/bin/env python

import getpass
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
    assignments = get_course_assignments(session, course_list[0]['path'])
    submit_submission(session, assignments[0]['path'], ['helo'])

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
    authenticity_token = doc.xpath('//input[@name="authenticity_token"]/@value')[0]

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

    # print(requests.Request('POST', 'https://httpbin.org/post', data=data, files=files).prepare().body.decode('utf-8'))
    submission_response = session.post('https://www.gradescope.com' + '/'.join(path.split('/')[:-1]), files=files, data=data, headers={'Accept': 'application/json'}).json()
    print(submission_response)

if __name__ == '__main__':
    main()
