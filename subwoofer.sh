#!/bin/sh

case "$1" in
        resume)
                ;;
        thaw)
                ;;
        suspend)
                /opt/subwoofer.py exit || true
                ;;
        hibernate)
                /opt/subwoofer.py exit || true
                ;;
esac