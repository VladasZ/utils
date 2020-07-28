import iOS
import Git
import File
import Make
import Time
import Args
import Deps
import File
import Shell
import Debug
import Conan
import Cmake


def _root_dir(path='.'):
    _path = path
    while not File.is_root(_path):
        if File.exists(_path + '/.projectile'):
            return File.full_path(_path)
        _path = _path + "/.."
    Debug.throw("C++ project root directory not found for path: " + File.full_path(path))


root_dir = _root_dir()
project_name = File.folder_name(root_dir)
build_dir = root_dir + "/build"

stamp = Time.stamp()


def prepare():
    if Args.ios:
        iOS.setup()

    File.cd(root_dir)

    Conan.setup()
    Cmake.setup()

    File.mkdir('build')
    File.cd('build')

    Cmake.reset_config()

    Deps.make_map(project_name)
    Debug.info(Deps._deps)
    Debug.info(Deps._deps_map)
    Deps.set_cmake_vars()

    Cmake.setup_variables()

    Conan.run()

    Cmake.run()

    print("Project prepare time: " + Time.duration())


def build():
    if not File.exists(build_dir):
        prepare()
    File.cd(build_dir)
    if Args.ios:
        Cmake.build()
    else:
        Make.run()
    print("Project build time: " + Time.duration())


def run():
    _project_name = "sand" if File.exists(build_dir + "/../source/sand") else project_name
    build()
    bin_dir = File.full_path(build_dir) + "/"

    if File.exists(bin_dir + "bin"):
        bin_dir += "bin/"

    Shell.run([bin_dir + _project_name])


def clean():
    File.rm(build_dir)
    Deps.clean()
