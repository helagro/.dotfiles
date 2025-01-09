max=0
output=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    -o | --output)
        output="$2"
        shift 2
        ;;
    -h | --help)
        echo "Usage: rand <max> [-o <output>]"
        exit 0
        ;;
    *)
        if [[ $max -eq 0 ]]; then
            max=$1
            shift
        else
            echo "Unknown option: $1"
            exit 1
        fi
        ;;
    esac
done

# Validate max argument
if [[ $max -le 0 ]]; then
    echo "Error: <max> must be a positive integer."
    exit 1
fi

# Seed RANDOM with entropy from /dev/urandom
seed=$(od -An -N2 -i /dev/urandom | tr -d ' ')
RANDOM=$seed

result=$((1 + RANDOM % ($max)))

if [[ -z "$output" ]]; then
    echo $result
fi

if [[ result -eq 1 ]]; then

    if [[ -n "$output" ]]; then
        echo "$output"
    fi

    exit 0
else
    exit 1
fi
