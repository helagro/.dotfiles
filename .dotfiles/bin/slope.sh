function slope {
    local m="${1:-7}"

    tac | awk -v m="$m" '{
        y[NR]=$2;
        x[NR]=NR
    }
    END {
        n=NR;
        sumx=sumy=sumxy=sumxx=0;
        for (i=1;i<=n;i++) {
        sumx+=x[i];
        sumy+=y[i];
        sumxy+=x[i]*y[i];
        sumxx+=x[i]*x[i]
        }
        slope=(n*sumxy-sumx*sumy)/(n*sumxx-sumx^2);
        print slope * m
    }'
}
