cmake_minimum_required(VERSION 3.20)
project(single-exec LANGUAGES CXX)

include(JgdSetupProject)
jgd_setup_project(ADD_SUBDIRECTORIES CONFIGURE_CONFIG_HEADER WITH_IPO
                  WITH_TESTS)
