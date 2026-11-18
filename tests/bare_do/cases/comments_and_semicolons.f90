program p
implicit none
integer::i,j,n
n=0; do ! header
n=n+1; if(n==3) exit ! transfer
end do; print *,n
end program
