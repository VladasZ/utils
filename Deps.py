import Git
import Args
import File
import Paths
import Cmake
import Debug
import Conan

_processed_deps = []

_ignore_build_tools = False

_project_name = File.folder_name()


def all_installed():
    return File.get_files(Paths.deps)


def safe_to_delete():
    for dep in all_installed():
        if dep == _project_name:
            continue
        if _ignore_build_tools and dep == "build_tools":
            continue
        if Git.has_changes(Paths.deps + "/" + dep):
            Debug.info("Dep " + dep + " has changes.")
            return True
    return False


def install(deps_file):
    deps = File.get_lines(deps_file)
    for dep in deps:
        _install(dep, update=Args.update_deps)
    if not _ignore_build_tools:
        _install("build_tools", update=Args.update_deps)


def print_info():
    changes = False
    for dep in all_installed():
        if dep == ".DS_Store":
            continue
        if Git.has_changes(Paths.deps + "/" + dep):
            changes = True
            print(dep + " - has changes")
    if not changes:
        print("no changes")


def clean():
    for dep in File.get_files(Paths.deps):
        File.rm(Paths.deps + "/" + dep + "/dep_build")
        File.rm(Paths.deps + "/" + dep + "/build")


def _clean_project_name(name):
    return name.replace("-", "_")


def _install(name, update=True):

    global _processed_deps

    if name in _processed_deps:
        return

    _processed_deps += [name]

    if name == "soil":
        Debug.throw("Soil dep is no logner supported. Use conan package.")

    if update and safe_to_delete():
        Debug.throw("Commit deps changes before updating.")

    path = Paths.deps + "/" + name

    if name != "build_tools":
        Cmake.append_var("GIT_DEPENDENCIES_PATHS", "\"" + path + "\"")
        Cmake.append_var("GIT_DEPENDENCIES", _clean_project_name(name))
        Cmake.add_var(_clean_project_name(name) + "_path", "\"" + path + "\"")

    Git.clone("https://github.com/vladasz/" + name, path, delete_existing=update, recursive=True, ignore_existing=True)

    deps_file = path + "/deps.txt"
    simple_conan_file = path + "/conan.txt"

    if File.exists(deps_file):
        install(deps_file)

    if File.exists(simple_conan_file):
        Conan.add_requires(simple_conan_file)
