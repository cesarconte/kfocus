set(CMAKE_INCLUDE_CURRENT_DIR ON)
add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_org.cesar.kfocus\")

add_library(kfocus_core STATIC
    focuscontroller.cpp
    focuscontroller.h
)
set_target_properties(kfocus_core PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(kfocus_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(kfocus_core PUBLIC
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Qml
)

plasma_add_applet(org.cesar.kfocus
    CPP_SOURCES
        focusapplet.cpp
        focusapplet.h
    QML_SOURCES
        qml/main.qml
    RESOURCES
        res/main.xml
)

target_include_directories(org.cesar.kfocus PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(org.cesar.kfocus PRIVATE
    kfocus_core
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::I18n
    Plasma::Plasma
    Plasma::PlasmaQuick
)
