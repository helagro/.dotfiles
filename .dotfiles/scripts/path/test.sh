if [[ ! " $@ " == *" -c "* ]]; then
    echo "Arguments do not contain -c. Doing something..."
    # Add your actions here
else
    echo "Arguments contain -c."
fi
