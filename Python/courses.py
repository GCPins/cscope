#!/usr/bin/env python

# Author: GCPins, anabasis
# CODE UNDER GPL

from turtle import title
from lxml import html
import requests
import sys 

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

def main():

    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/118.0'})

    c = login()
    session.cookies.update(c)

    course_list = get_courses(session)
    assignments = []
    for course in course_list:
        this_list = []
        assignments.append(this_list)
        this_list.append(get_course_assignments(session, course['path']))
    print(course_list, assignments, sep="|")

def login():
    option = Options()
    #option.headless = True
    option.add_argument("--headless=new")
    option.add_argument("--window-size=1920,1080")
    

    #print("Loading browser (please wait)...")

    option.add_experimental_option('excludeSwitches', ['enable-logging'])


    driver = webdriver.Chrome(options=option) 
    driver.get("https://gradescope.com/auth/saml/clemson")

    passwrd = driver.find_element(By.NAME, "j_password")
    usrname = driver.find_element(By.NAME, "j_username")

    usr = sys.argv[1]
    pss = sys.argv[2]

    passwrd.send_keys(pss)
    usrname.send_keys(usr)

    clickMe = driver.find_element(By.NAME, "_eventId_proceed")
    clickMe.click()

    #print("Logging in, please wait...")
    s_cookies = driver.get_cookies()

    r_cookies = {}
    for c in s_cookies:
        r_cookies[c['name']] = c['value']

    driver.quit()

    return r_cookies


"""
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
    r = session.post('https://www.gradescope.com/auth/saml/clemson/callback', data={'SAMLResponse': saml_response})
"""

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
            if title_element is not None:
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
