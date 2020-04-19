#!/bin/bash
set -e;

export PROJECT_PATH="$(pwd)"
export BUILD_DIR="$PROJECT_PATH/.build"
export OUTPUT_DIR="$BUILD_DIR/release"

mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

deps() {
    mkdir -p .build/bin

    # Fetch scons
    brew install scons

    # Set up a python2 execution environment for SCons
    echo "python2 \"$(which scons)\" \"\$@\"" > .build/bin/scons
    chmod u+x .build/bin/scons

    # Fetch compatible OpenSSL
    brew install ./artefacts/openssl.rb
    export OPENSSL_LIB_PATH=/usr/local/Cellar/openssl/1.0.2t

    brew install ./artefacts/qt.rb
    export QT_LIB_PATH=/usr/local/Cellar/qt/5.14.1/lib/cmake

    export PATH="$(pwd)/.build/bin:$PATH"
}

fetch() {
    export ROBOMONGO_APP_PATH="$BUILD_DIR/robomongo-app"
    if [[ ! -d $ROBOMONGO_APP_PATH ]]; then
        git clone https://github.com/Studio3T/robomongo "$ROBOMONGO_APP_PATH"
    fi
    ( cd "$ROBOMONGO_APP_PATH";
        git reset --hard HEAD
        git checkout v0.9.0
        git apply "$PROJECT_PATH/artefacts/robomongo-app.patch"
    )

    export ROBOMONGO_SHELL_PATH="$BUILD_DIR/robomongo-shell"
    if [[ ! -d $ROBOMONGO_SHELL_PATH ]]; then
        git clone https://github.com/Studio3T/robomongo-shell "$ROBOMONGO_SHELL_PATH"
    fi
    ( cd "$ROBOMONGO_SHELL_PATH";
        git reset --hard HEAD
        git checkout roboshell-v3.2
        git apply "$PROJECT_PATH/artefacts/robomongo-shell.patch"
    )
}

build() {
    ( cd "$ROBOMONGO_SHELL_PATH";
        export ROBOMONGO_CMAKE_PREFIX_PATH="$OPENSSL_LIB_PATH"
        bin/build
    )
    ( cd "$ROBOMONGO_APP_PATH";
        export ROBOMONGO_CMAKE_PREFIX_PATH="$OPENSSL_LIB_PATH;$QT_LIB_PATH;$ROBOMONGO_SHELL_PATH"
        bin/configure
        bin/build
        bin/install
    )
}

main() {
    set -x

    deps
    fetch
    build

    cp -r "$ROBOMONGO_APP_PATH/build/release/install/"*.app "$OUTPUT_DIR"
}

main "$@"
