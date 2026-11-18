program p
implicit none
integer::i,j,n
n=0; do; n=n+1; if(n==2) exit; enddo; print *,n
end program
