program p
implicit none
integer::i,j,n
n=0; outer: do; do; n=n+1; exit outer; enddo; enddo outer; print *,n
end program
