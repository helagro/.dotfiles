for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" || "$arg" == "help" ]]; then
        exit 0
    fi
done

exit 1
