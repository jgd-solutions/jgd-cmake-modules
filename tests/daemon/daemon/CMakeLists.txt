jcm_add_executable(
  OUT_TARGET exec-target
  SOURCES
    main.cpp
    features.mpp
  LIB_SOURCES
    exec.mpp)

target_compile_features(${exec-target} PRIVATE cxx_std_20)

target_link_libraries(${exec-target}-library PRIVATE daemon::libdaemon)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-library)
