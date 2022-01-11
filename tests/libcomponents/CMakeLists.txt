cmake_minimum_required(VERSION 3.20)
project(libcomponents LANGUAGES CXX)

include(JgdSetupProject)
jgd_setup_project(ADD_SUBDIRECTORIES WITH_IPO CONFIGURE_CONFIG_HEADER
                  WITH_TESTS COMPONENTS "core;extra")
