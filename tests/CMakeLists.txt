find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

add_executable(test_kfocus test_kfocus.cpp)
target_compile_definitions(test_kfocus PRIVATE KFOCUS_SOURCE_DIR="${CMAKE_SOURCE_DIR}")
target_link_libraries(test_kfocus PRIVATE
    kfocus_core
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Test
)

add_test(NAME test_kfocus COMMAND test_kfocus)
