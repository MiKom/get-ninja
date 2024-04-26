#! /bin/bash

echo "Runner $RUNNER_OS $RUNNER_ARCH"

wget=wget
if [ "$RUNNER_OS" == "Windows" ]; then
    if [ "$RUNNER_ARCH" == "ARM64" ]; then
        filename=ninja-winarm64.zip
    else
        filename=ninja-win.zip
    fi
    wget=C:/msys64/usr/bin/wget.exe
    checksum=sha512sum
elif [ "$RUNNER_OS" == "macOS" ]; then
    filename=ninja-mac.zip
    checksum="shasum -a 512"
elif [ "$RUNNER_OS" == "Linux" ]; then
    if [ "$RUNNER_ARCH" == "ARM64" ]; then
        filename=ninja-linux-aarch64.zip
    else
        filename=ninja-linux.zip
    fi
    checksum="sha512sum"
else
    echo "$RUNNER_OS not supported"
    exit 1
fi
if ! $wget -q "https://github.com/ninja-build/ninja/releases/download/v1.12.0/$filename" ; then
    echo "Couldn't download $filename file"
    exit 2
fi

echo GITHUB_ACTION_PATH = $(cygpath -u $GITHUB_ACTION_PATH)
echo pwd = $(pwd)/

# We do our own SHA512 check on Windows when running get-ninja
# actions, as it looks like sha512sum --check is not working in that
# specific case.
if [[ "$RUNNER_OS" == "Windows" && $(cygpath -u $GITHUB_ACTION_PATH) == $(pwd)/ ]]; then
    expected=$(cat checksums.txt | grep $filename | cut -d ' ' -f 1)
    actual=$($checksum $filename | cut -d ' ' -f 1)
    echo expected SHA512 $expected $filename
    echo actual SHA512 $actual $filename
    if [[ "$expected" == "" || "$actual" == "" || "$expected" != "$actual" ]] ; then
	echo "Invalid SHA512 checksum"
	exit 3
    fi
else
    if ! $checksum --ignore-missing --check $GITHUB_ACTION_PATH/checksums.txt ; then
        echo "Invalid SHA512 checksum"
        exit 4
    fi
fi

# Copy the ninja binary to $HOME/.local/bin
mkdir -p "$HOME/.local/bin"
unzip -d "$HOME/.local/bin" "$filename"
