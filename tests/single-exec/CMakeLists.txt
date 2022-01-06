cmake_minimum_required(VERSION 3.20)
project(single-exec LANGUAGES CXX)

include(JgdSetupDefaultProject)
jgd_setup_default_project(ADD_SUBDIRECTORIES CONFIGURE_CONFIG_HEADER WITH_IPO
                          WIT_TESTS)
