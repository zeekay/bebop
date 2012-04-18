from setuptools import setup

setup(name='bebop-server',
      version='0.3.2',
      url="https://github.com/zeekay/bebop",
      author='Zach Kelling',
      author_email='zeekayy@gmail.com',
      packages=['bebop', 'bebop.management.commands'],
      description='A tool for rapid web development',
      install_requires=['autobahn', 'twisted', 'watchdog'],
      scripts=['bin/bebop'],
)
