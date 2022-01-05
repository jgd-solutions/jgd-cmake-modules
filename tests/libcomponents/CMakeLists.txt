cmake_minimum_required(VERSION 3.20)
project(libcomponents LANGUAGES CXX)

include(JgdSetupDefaultProject)
jgd_setup_default_project(ADD_SUBDIRECTORIES WITH_IPO CONFIGURE_CONFIG_HEADER
                          COMPONENTS "core;extra")
