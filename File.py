import os
import getpass
import shutil
import Shell
import System
import Args

def mkdir(name):
    if not os.path.exists(name):
        os.makedirs(name)

def cd(path):
    os.chdir(path)

def chown(path):
	if not System.isWindows:
		Shell.run(['sudo', 'chown', '-R', 'vladaszakrevskis', path])

def rm(path):
	if os.path.exists(path):
		shutil.rmtree(path)

def build_folder():
	if Args.has('--make'):
		return 'make'
	return 'build'
