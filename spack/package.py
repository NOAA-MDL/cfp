# Copyright 2013-2026 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.cmake import CMakePackage

from spack.package import *

class Cfp(CMakePackage):
    """The Command File Processor (CFP) is an MPI-based Fortran/C tool
    designed to manage and process parallel execution command files."""

    homepage = "https://github.com/NOAA-MDL/cfp"
    url = "https://github.com/NOAA-MDL/cfp/archive/refs/tags/v2.1.0.tar.gz"
    git = "https://github.com/NOAA-MDL/cfp"

    # Maintainers list (GitHub handles)
    maintainers = ["maintainer_username"]

    # Versions
    version("main", branch="main")
    version("2.1.0", sha256="")

    # Compilers required for C and Fortran mixed codebase
    languages = ["c", "fortran"]

    # Mandatory Dependencies
    depends_on("cmake@3.18:", type="build")
    depends_on("mpi")
    depends_on("openmp")

    def cmake_args(self):
        args = [
            self.define("BUILD_TESTING", self.run_tests),
        ]
        return args
