cmake_minimum_required(VERSION 3.20)
project(libcomp-project LANGUAGES CXX)

include(JgdSetupDefaultProject)
jgd_setup_default_project(ADD_SUBDIRECTORIES WITH_IPO COMPONENTS "core;extra")
