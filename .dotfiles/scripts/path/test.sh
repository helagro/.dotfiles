# Script just used for testing stuff

if [ -t 0 ]; then
    m_vared

    while [[ $line != 'q' ]]; do
        line=$(echo "$line" | tr -d '\\')
        a "$line"
        m_vared
    done
else
    while read -r line; do
        line=$(echo "$line" | sed -e 's/^- \[ \] //' -e 's/^- //')
        echo "$line"
        #a "$line"
    done
fi
